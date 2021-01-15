#!/bin/bash

function join-addomain() {
	if [[ -z $realm_name ]]; then
		read -p "Enter domain name: " addomain
		read -p "Enter user with domain admin rights: " domain_admin
		systemctl restart dbus
		realm join "$addomain" --user="$domain_admin"
		sleep 2
		
		realm_name=$(realm list | head -n 1)
		if [[ -z $realm_name ]]; then
			echo "Failed to enter $(hostname) to domain"
		else
			set-adconfig
			echo "$(hostname) added to domain succesfully. Reboot recommended to finish process completley"
		fi
	else
		echo "$(hostname) already in $realm_name domain"
	fi
}

function leave-addomain() {
	realm_name=$(realm list | head -n 1)
	if [[ ! -z $realm_name ]]; then
		remove-addomain -a
		echo "Leaving domain: $realm_name"
		read -p "Enter user with domain admin rights: " domain_admin
		realm leave "$realm_name" --user="$domain_admin"
		sleep 2

		if [[ -z $realm_name ]]; then
			echo "$(hostname) left domain succesfully. Reboot recommended to finish process completley"
		else
			echo "Failed to leave domain"
		fi
	else
		echo "$(hostname) not in a domain" 
	fi
}

function set-adconfig() {
	realm deny --all
	sed -i 's/use_fully_qualified_names = True/use_fully_qualified_names = False/g' /etc/sssd/sssd.conf
	sed -i 's/fallback_homedir = \/home\/%u@%d/fallback_homedir = \/home\/%u/g' /etc/sssd/sssd.conf
	if [[ -z $(grep AllowUsers /etc/ssh/sshd_config) ]]; then
		echo 'AllowUsers root' >> /etc/ssh/sshd_config
	fi
	if [[ -z $(grep AllowGroups /etc/ssh/sshd_config) ]]; then
		echo 'AllowGroups root' >> /etc/ssh/sshd_config
	fi
	if [[ ! -f "/etc/sudoers.d/sudoers" ]]; then
		touch /etc/sudoers.d/sudoers
	fi

	sleep 2
	systemctl restart sssd sshd
	get-adusersgroups
}

function get-adusersgroups() {
	echo ""
	echo "Domain name: $(realm list | head -n 1)"

	logins=$(realm list | grep login-policy)
	if [[ "$logins" =~ "allow-permitted-logins" ]]; then
		readarray logins < <(realm list | grep permitted)
		for login in "${logins[@]}"; do
			echo $login
		done
	else
		echo $logins
	fi

	ssh_users=$(grep AllowUsers /etc/ssh/sshd_config | cut -d' ' -f2-)
	ssh_groups=$(grep AllowGroups /etc/ssh/sshd_config | cut -d' ' -f2-)
	if [[ "$ssh_users" =~ '?' ]]; then
		ssh_users="$(echo $ssh_users | sed 's/?/ /g')"
	fi
	if [[ "$ssh_groups" =~ '?' ]]; then
		ssh_groups="$(echo $ssh_groups | sed 's/?/ /g')"
	fi
	echo "SSH allowed users: $ssh_users"
	echo "SSH allowed user groups: $ssh_groups"

	sudo_users=$(grep -v '%' /etc/sudoers.d/sudoers)
	sudo_groups=$(grep '%' /etc/sudoers.d/sudoers)
	if [[ ! -z $sudo_users ]] && [[ ! -z $sudo_groups ]]; then
		if [[ "$sudo_users" =~ '\ ' ]] || [[ "$sudo_groups" =~ '\ ' ]]; then
			sudo_users=$(echo $sudo_users | sed 's/\\ / /g')
			sudo_groups=$(echo $sudo_groups | sed 's/\\ / /g')
		fi
		sudo_users=$(echo $sudo_users | sed 's/ALL=(ALL) ALL//g')
		sudo_groups=$(echo $sudo_groups | sed 's/ALL=(ALL) ALL//g' | sed 's/%//g')
		echo "Users with sudo/admin permissions: $sudo_users"
		echo "Groups of users with sudo/admin permissions: $sudo_groups"
	fi
	echo ""
}

function add-adusersgroups() {
	sudoers=false
	declare -a adusers
	declare -a adgroups

	while [ -n "$1" ]; do
		case "$1" in
				-a) sudoers=true ;;
				-u) shift
					for user in "$@"; do
						if [[ $user =~ ^-.* ]]; then break; fi
						adusers+=("${user,,}")
					done ;;
				-g) shift
					for group in "$@"; do
						if [[ $group =~ ^-.* ]]; then break; fi
						adgroups+=("${group,,}")
					done ;;
				--) shift
					break ;;
				#*) ;;
			esac
			shift
	done
	
	if [[ ${#adusers[@]} -eq 0 ]] && [[ ${#adgroups[@]} -eq 0 ]]; then
		echo "No users or groups were added"
		return 1
	else
		declare -a falseusers
		declare -a falsegroups
		if [[ ${#adusers[@]} -ne 0 ]]; then
			for user in "${adusers[@]}"; do
				checkuser=$(groups "$user" 2> /dev/null)
				if [[ -z "$checkuser" ]]; then falseusers+=("$user"); fi
			done
		fi
		if [[ ${#adgroups[@]} -ne 0 ]]; then
			for group in "${adgroups[@]}"; do
				checkgroup=$(getent group "$group" 2> /dev/null)
				if [[ -z "$checkgroup" ]]; then falsegroups+=("$group"); fi
			done
		fi
	fi
	
	if [[ ${#falseusers[@]} -ne 0 ]] && [[ ${#falsegroups[@]} -ne 0 ]]; then
		echo "${falseusers[@]} ${falsegroups[@]} do not exist"
		return 1
	else
		if [[ ${#adusers[@]} -ne 0 ]]; then
			for user in "${adusers[@]}"; do
				realm_user="$user"
				if [[ "$user" =~ " " ]]; then
					ssh_user="$(echo $user | sed 's/ /?/g')"
					sudo_user="$(echo $user | sed 's/ /\\ /g')"
					sudo_user_check="$(echo $user | sed 's/ /\\\\ /g')"
				else
					ssh_user="$user"
					sudo_user="$user"
					sudo_user_check="$user"
				fi

				realm permit "$realm_user"

				sshd_file=$(grep AllowUsers /etc/ssh/sshd_config)
				if [[ ! $sshd_file =~ "$ssh_user" ]]; then
					sed -i "s/$sshd_file/$sshd_file $ssh_user/g" /etc/ssh/sshd_config
				else
					echo "$user already in sshd_config file"
				fi

				if [ $sudoers == true ]; then
					sudo_file=$(cat /etc/sudoers.d/sudoers | grep "$sudo_user_check")
					if [[ -z $sudo_file ]]; then
						echo "$sudo_user    ALL=(ALL)       ALL" >> /etc/sudoers.d/sudoers
					else
						echo "$user already in sudoers file"
					fi
				fi
			done
		fi

		if [[ ${#adgroups[@]} -ne 0 ]]; then
			for group in "${adgroups[@]}"; do
				realm_group="$group"
				if [[ "$group" =~ " " ]]; then
					ssh_group="$(echo $group | sed 's/ /?/g')"
					sudo_group="$(echo $group | sed 's/ /\\ /g')"
					sudo_group_check="$(echo $group | sed 's/ /\\\\ /g')"
				else
					ssh_group="$group"
					sudo_group="$group"
					sudo_group_check="$group"
				fi

				realm permit -g "$realm_group"

				sshd_file=$(grep AllowGroups /etc/ssh/sshd_config)
				if [[ ! $sshd_file =~ "$ssh_group" ]]; then
					sed -i "s/$sshd_file/$sshd_file $ssh_group/g" /etc/ssh/sshd_config
				else
					echo "$group already in sshd_config file"
				fi

				if [ $sudoers == true ]; then
					sudo_file=$(cat /etc/sudoers.d/sudoers | grep "$sudo_group_check")
					if [[ -z $sudo_file ]]; then
						echo "%$sudo_group    ALL=(ALL)       ALL" >> /etc/sudoers.d/sudoers
					else
						echo "$group already in sudoers file"
					fi
				fi
			done
		fi
		
		sleep 2
		systemctl restart sssd sshd
		get-adusersgroups
	fi
}

function remove-adusersgroups() {
	remove_all=false
	sudoers=true
	declare -a adusers
	declare -a adgroups

	while [ -n "$1" ]; do
		case "$1" in
				-a) remove_all=true ;;
				-s) sudoers=false ;;
				-u) shift
					for user in "$@"; do
						if [[ $user =~ ^-.* ]]; then break; fi
						adusers+=("${user,,}")
					done ;;
				-g) shift
					for group in "$@"; do
						if [[ $group =~ ^-.* ]]; then break; fi
						adgroups+=("${group,,}")
					done ;;
				--) shift
					break ;;
				#*) ;;
			esac
			shift
	done

	if [[ $remove_all == true ]]; then
		realm deny --all
		ssh_users=$(grep AllowUsers /etc/ssh/sshd_config)
		ssh_groups=$(grep AllowGroups /etc/ssh/sshd_config)
		sed -i "s/$ssh_users/AllowUsers root/g" /etc/ssh/sshd_config
		sed -i "s/$ssh_groups/AllowGroups root/g" /etc/ssh/sshd_config
		echo -n "" > /etc/sudoers.d/sudoers

	elif [[ ${#adusers[@]} -ne 0 ]] || [[ ${#adgroups[@]} -ne 0 ]]; then
		if [[ ${#adusers[@]} -ne 0 ]]; then
			for user in "${adusers[@]}"; do
				realm_user="$user"
				if [[ "$user" =~ " " ]]; then
					ssh_user="$(echo $user | sed 's/ /?/g')"
					sudo_user="$(echo $user | sed 's/ /\\\\ /g')"
				else
					ssh_user="$user"
					sudo_user="$user"
				fi

				if [[ $sudoers == true ]]; then
					realm permit -x "$realm_user"

					sshd_file=$(grep AllowUsers /etc/ssh/sshd_config)
					if [[ $sshd_file =~ "$ssh_user" ]]; then
						sed -i "s/$ssh_user//g" /etc/ssh/sshd_config
					else
						echo "$user is not in sshd_config file"
					fi
				fi

				sudo_file=$(cat /etc/sudoers.d/sudoers | grep "$sudo_user")
				if [[ ! -z $sudo_file ]]; then
					sed -i "s/$sudo_user    ALL=(ALL)       ALL//g" /etc/sudoers.d/sudoers
					sed -i '/^$/d' /etc/sudoers.d/sudoers
				else
					echo "$user is not in sudoers file"
				fi
			done
		fi

		if [[ ${#adgroups[@]} -ne 0 ]]; then
			for group in "${adgroups[@]}"; do
				realm_group="$group"
				if [[ "$group" =~ " " ]]; then
					ssh_group="$(echo $group | sed 's/ /?/g')"
					sudo_group="$(echo $group | sed 's/ /\\\\ /g')"
				else
					ssh_group="$group"
					sudo_group="$group"
				fi
				
				if [[ $sudoers == true ]]; then
					realm permit -g -x "$realm_group"

					sshd_file=$(grep AllowGroups /etc/ssh/sshd_config)
					if [[ $sshd_file =~ "$ssh_group" ]]; then
						sed -i "s/$ssh_group//g" /etc/ssh/sshd_config
						sed -i '/^$/d' /etc/sudoers.d/sudoers
					else
						echo "$group is not in sshd_config file"
					fi
				fi

				sudo_file=$(cat /etc/sudoers.d/sudoers | grep "$sudo_group")
				if [[ ! -z $sudo_file ]]; then
					sed -i "s/%$sudo_group    ALL=(ALL)       ALL//g" /etc/sudoers.d/sudoers
					sed -i '/^$/d' /etc/sudoers.d/sudoers
				else
					echo "$group is not in sudoers file"
				fi
			done
		fi
	else
		echo "No users or groups were selected for removal"
	fi
	
	sleep 2
	systemctl restart sssd sshd
	get-adusersgroups
}