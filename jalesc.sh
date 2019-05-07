#!/bin/bash

C_RESET='\033[0m'
C_RED='\033[1;31m'
C_GREEN='\033[1;32m'
C_YELLOW='\033[1;33m'
C_BLUE='\033[1;34m'
C_WHITE='\033[1;37m'
C_RESET_SED='\\033[0m'
C_RED_SED='\\033[1;31m'
C_GREEN_SED='\\033[1;32m'
C_YELLOW_SED='\\033[1;33m'
C_BLUE_SED='\\033[1;34m'
C_WHITE_SED='\\033[1;37m'

function print_err {
    echo -e "${C_RED}[-]${C_RESET} $1"
	echo ""
}

function print_notif {
    echo -e "${C_YELLOW}[!]${C_RESET} $1"
	echo ""
}

function print_success {
    echo -e "${C_GREEN}[+]${C_RESET} $1"
	echo ""
}

function note_highlight {
    echo ""
    echo -e "(${C_BLUE}highlight${C_RESET} = $1)"
    echo ""
}

echo "#################################################"
echo "#              SECTION: Networking              #"
echo "#################################################"
echo ""

echo "----------------------------"
echo -e "${C_WHITE}INTERFACE IP ADDRESSES${C_RESET}"
echo "----------------------------"
echo ""
if [ -n "$(which ifconfig 2>/dev/null)" ]; then
    ifout=$(ifconfig)
    if [ $(echo "$ifout" | grep -c "inet addr:") -gt 0 ]; then
    	inetaddrs=$(echo "$ifout" | grep -o "inet addr:[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}")
    else
    	inetaddrs=$(echo "$ifout" | grep -o "inet [0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}")
    fi
		
else
    ifout=$(ip addr show)
    inetaddrs=$(echo "$ifout" | grep -o "inet [0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}")
fi

while read -r addr; do
    ifout=$(echo "$ifout" | sed "s/${addr}/${C_BLUE_SED}${addr}${C_RESET_SED}/g")
done <<< "$inetaddrs"
echo -e "$ifout"
note_highlight "ipv4 addresses"

echo "----------------------------"
echo -e "${C_WHITE}ARP CACHE${C_RESET}"
echo "----------------------------"
echo ""
cat /proc/net/arp
echo ""

echo "----------------------------"
echo -e "${C_WHITE}LISTENING SOCKETS${C_RESET}"
echo "----------------------------"
echo ""
netstat -auntp 2>/dev/null | egrep "(Proto|LISTEN|udp)"
echo ""

echo "----------------------------"
echo -e "${C_WHITE}ESTABLISHED CONNECTIONS${C_RESET}"
echo "----------------------------"
echo ""
netstat -auntp 2>/dev/null | egrep -v "(LISTEN|udp)"
echo ""

echo "----------------------------"
echo -e "${C_WHITE}DNS AND HOSTNAMES${C_RESET}"
echo "----------------------------"
echo ""
echo -e "${C_WHITE}Our Hostname:${C_RESET} $(hostname)"
echo ""
echo -e "${C_WHITE}Configured name servers:${C_RESET}"
echo "$(grep "nameserver" /etc/resolv.conf 2>/dev/null)"
echo ""
echo -e "${C_WHITE}Mappings configured in /etc/hosts:${C_RESET}"
echo "$(egrep -v "#" /etc/hosts 2>/dev/null | sed '/^$/d')"
echo ""


echo "#################################################"
echo "#              SECTION: Users                   #"
echo "#################################################"
echo ""

echo "----------------------------"
echo -e "${C_WHITE}PASSWD OUTPUT${C_RESET}"
echo "----------------------------"
passwd=$(cat /etc/passwd)
interactiveUsers=$(echo "$passwd" | egrep "(/bin/bash|/bin/csh|/bin/ksh|/bin/sh|/bin/tcsh|/bin/zsh)")
while read -r line; do
    line=$(echo "$line" | sed "s/\//\\\\\//g")
    passwd=$(echo "$passwd" | sed "s/${line}/${C_BLUE_SED}${line}${C_RESET_SED}/g")
done <<< "$interactiveUsers"
echo -e "$passwd"
note_highlight "users with an interactive shell"

echo "----------------------------"
echo -e "${C_WHITE}RECENT USER SESSIONS${C_RESET}"
echo "----------------------------"
if [ -n "$(which last 2>/dev/null)" ] && [ -f "/var/log/wtmp" ]; then
    last -n 10 | grep -v "wtmp begins"
else
    print_err "The \'last\' utility is not available on this system. Skipping . . ."
fi
echo ""

echo "----------------------------"
echo -e "${C_WHITE}RECENT SSH LOGINS${C_RESET}"
echo "----------------------------"
if [ -r "/var/log/secure" ]; then
    logFile="/var/log/secure"
elif [ -r "/var/log/auth.log" ]; then
    logFile="/var/log/auth.log"
else
    logFile="NOPERMS"
fi

if [ "$logFile" == "NOPERMS" ]; then
    print_err "Insufficient permissions for reading authentication logs. Skipping . . ."
    echo ""
else
    sshhist=$(grep -m 15 "Accepted" $logFile)
	if [ -z "$sshhist" ]; then
		print_notif "No presence of any SSH authentication history . . . "
    	echo ""
	else 
    	users=$(echo "$sshhist" | grep -o "for .* from" | cut -d " " -f 2 | sort | uniq)
    	while read -r user; do
        	sshhist=$(echo "$sshhist" | sed "s/${user}/${C_BLUE_SED}${user}${C_RESET_SED}/g")
    	done <<< "$users"
    	echo -e "$sshhist"
    	note_highlight "accounts trying to authenticate"
	fi
fi

echo "----------------------------"
echo -e "${C_WHITE}HOME DIRECTORIES${C_RESET}"
echo "----------------------------"
echo ""
homedirs=$(ls /home/)
if [ -z "$homedirs" ]; then
	print_notif "The /home directory appears to be empty . . ."
	echo ""
else
	homedirs=$(ls -lh /home/)
	readables=$(find /home/ -maxdepth 1 -type d -readable | tail -n +2)
	echo -e "${C_WHITE}/home${C_RESET}"
	while read -r dir; do
    	dir=$(echo "$dir" | cut -d "/" -f 3)
    	homedirs=$(echo "$homedirs" | sed -e "s/${dir}/${C_BLUE_SED}${dir}${C_RESET_SED}/g")
	done <<< "$readables"
	echo -e "$homedirs"
	echo ""

	while read -r dir; do
    	echo -e "${C_WHITE}${dir}${C_RESET}"
    	ls -lah $dir
    	echo ""
	done <<< "$readables"
	note_highlight "accessible home directories"
fi



echo "#################################################"
echo "#           SECTION: Interesting Files          #"
echo "#################################################"
echo ""

echo "----------------------------"
echo -e "${C_WHITE}SET UID BINARIES${C_RESET}"
echo "----------------------------"
echo ""
defaultSetUIDs="/usr/bin/at /usr/bin/Xorg /usr/bin/crontab /usr/bin/chfn /usr/bin/sudo /usr/bin/gpasswd"
defaultSetUIDs="${defaultSetUIDs} /usr/bin/passwd /usr/bin/pkexec /bin/ping /bin/su /bin/umount"
defaultSetUIDs="${defaultSetUIDs} /bin/fusermount /bin/ping6 /bin/mount /sbin/mount /usr/bin/newgrp"
defaultSetUIDs="${defaultSetUIDs} /usr/lib/xorg/Xorg.wrap /usr/bin/traceroute6.iputils /usr/sbin/pppd"
defaultSetUIDs="${defaultSetUIDs} /usr/bin/arping /usr/bin/chsh /usr/bin/ntfs-3g /usr/sbin/exim4 /usr/bin/umount"
defaultSetUIDs="${defaultSetUIDs} /usr/lib/openssh/ssh-keysign /usr/bin/fusermount /usr/sbin/exim4 /usr/sbin/mount.cifs"
defaultSetUIDs="${defaultSetUIDs} /usr/bin/mount /usr/lib/dbus-1.0/dbus-daemon-launch-helper /usr/bin/bwrap"
print_notif "This could take a few moments . . ."
suids=$(find / -type f -perm -4000 -not -path "/sys/*" -not -path "/run/*" -not -path "/proc/*" -not -path "/dev/*" -exec ls -la {} \; 2>/dev/null | grep -v /snap)
suidsFilenames=$(echo "$suids" | rev | cut -d " " -f 1 | rev)
while read -r suid; do
    if [ $(echo "$defaultSetUIDs" | grep -c "$suid") -eq 0 ]; then
        suid=$(echo "$suid" | sed "s/\//\\\\\//g")
        suids=$(echo "$suids" | sed "s/${suid}/${C_BLUE_SED}${suid}${C_RESET_SED}/g")
    fi
done <<< "$suidsFilenames"
echo -e "$suids"
note_highlight "\"non-standard\" SUID binaries"

echo "----------------------------"
echo -e "${C_WHITE}NOTABLE SYSTEM FILES${C_RESET}"
echo "----------------------------"
echo ""
echo -e "${C_WHITE}Potential config files${C_RESET}"
out=$(find / -type f -not -path "/var/*" -not -path "/proc/*" -not -path "/sys/*" -not -path "/run/*" -name "*.cfg" -o -name "*.conf" -o -name "*.cnf" -exec ls -lh {} \; 2>/dev/null)
fnames=$(echo "$out" | rev | cut -d " " -f 1 | rev)
while read -r file; do

	if [ -r "$file" ]; then
        file=$(echo "$file" | sed "s/\//\\\\\//g")
		out=$(echo "$out" | sed -e "s/${file}/${C_BLUE_SED}${file}${C_RESET_SED}/g")
	fi
done <<< "$fnames"
echo -e "$out"
echo ""

echo -e "${C_WHITE}/var/log Log Files${C_RESET}"
out=$(find /var/log -type f -exec ls -lh {} \;)
fnames=$(echo "$out" | rev | cut -d " " -f 1 | rev)

while read -r file; do
	
	if [ -r "$file" ]; then
        file=$(echo "$file" | sed "s/\//\\\\\//g")
		out=$(echo "$out" | sed "s/${file}/${C_BLUE_SED}${file}${C_RESET_SED}/g")
	fi
done <<< "$fnames"
echo -e "$out"
echo ""

echo -e "${C_WHITE}/var/www Web Files${C_RESET}"
out=$(find /var/www -type f -exec ls -lh {} \;)
fnames=$(echo "$out" | rev | cut -d " " -f 1 | rev)
while read -r file; do
	
	if [ -r "$file" ]; then
        file=$(echo "$file" | sed "s/\//\\\\\//g")
		out=$(echo "$out" | sed "s/${file}/${C_BLUE_SED}${file}${C_RESET_SED}/g")
	fi
done <<< "$fnames"
echo -e "$out"
note_highlight "file is readable"

echo "----------------------------"
echo -e "${C_WHITE}FILES WITH CAPABILITIES${C_RESET}"
echo "----------------------------"
echo ""
out=$(getcap -r / 2>/dev/null)
if [ -z "$out" ]; then
	print_notif "No capabilities set on any files . . ."
else
	echo "$out"
	echo ""
fi
	

echo "----------------------------"
echo -e "${C_WHITE}USER PRESENCE FILES${C_RESET}"
echo "----------------------------"
echo ""
echo -e "${C_WHITE}Bash History Files${C_RESET}"
out=$(find / -type f -not -path "/proc/*" -not -path "/run/*" -not -path "/dev/*" -not -path "/sys/*" -name ".bash_history" -exec ls -lh {} \; 2>/dev/null)
if [ -z "$out" ]; then
	print_notif "No bash history files could be located . . ."
else
	fnames=$(echo "$out" | rev | cut -d " " -f 1 | rev)
	while read -r file; do
	
		if [ -r "$file" ]; then
			fileraw=$file
       	    file=$(echo "$file" | sed "s/\//\\\\\//g")
			out=$(echo "$out" | sed "s/${file}/${C_BLUE_SED}${file}${C_RESET_SED}/g")
			out="$out\n$(print_notif 'Last 20 Commands...')\n"
			out="${out}$(tail -n 20 ${fileraw})"
		fi
	
	done <<< "$fnames"
	echo -e "$out"
	echo ""
fi

echo -e "${C_WHITE}MYSQL History Files${C_RESET}"
out=$(find / -type f -not -path "/proc/*" -not -path "/run/*" -not -path "/dev/*" -not -path "/sys/*" -name ".mysql_history" -exec ls -lh {} \; 2>/dev/null)
if [ -z "$out" ]; then
	print_notif "No mysql history files could be located . . ."
else
	fnames=$(echo "$out" | rev | cut -d " " -f 1 | rev)
	while read -r file; do
	
		if [ -r "$file" ]; then
			fileraw=$file
       	    file=$(echo "$file" | sed "s/\//\\\\\//g")
			out=$(echo "$out" | sed "s/${file}/${C_BLUE_SED}${file}${C_RESET_SED}/g")
			out="$out\n$(print_notif 'Last 20 Commands...')\n"
			out="${out}$(tail -n 20 ${fileraw})"
		fi
	
	done <<< "$fnames"
	echo -e "$out"
	echo ""
fi

echo -e "${C_WHITE}viminfo Files${C_RESET}"
out=$(find / -type f -not -path "/proc/*" -not -path "/run/*" -not -path "/dev/*" -not -path "/sys/*" -name ".viminfo" -exec ls -lh {} \; 2>/dev/null)
if [ -z "$out" ]; then
	print_notif "No viminfo files could be located . . ."
else
	fnames=$(echo "$out" | rev | cut -d " " -f 1 | rev)
	while read -r file; do	
		if [ -r "$file" ]; then
       	    file=$(echo "$file" | sed "s/\//\\\\\//g")
			out=$(echo "$out" | sed "s/${file}/${C_BLUE_SED}${file}${C_RESET_SED}/g")
		fi
	
	done <<< "$fnames"
	echo -e "$out"
	echo ""
fi
note_highlight "file is readable"

echo "#################################################"
echo "#           SECTION: Processes and Jobs          #"
echo "#################################################"
echo ""

echo "----------------------------"
echo -e "${C_WHITE}RUNNING PROCESSES${C_RESET}"
echo "----------------------------"
echo ""
ps -elf | egrep -v "*]$"
echo ""

echo "----------------------------"
echo -e "${C_WHITE}CRON DIRECTORIES${C_RESET}"
echo "----------------------------"
echo ""
echo -e "${C_WHITE}/etc/cron.d${C_RESET}"
out=$(ls -lh /etc/cron.d | egrep -v "^total")
if [ -z "$out" ]; then
	print_notif "No jobs configured in cron.d . . ."
else
	echo "$out"
	echo ""
fi
echo -e "${C_WHITE}/etc/cron.hourly${C_RESET}"
out=$(ls -lh /etc/cron.hourly | egrep -v "^total")
if [ -z "$out" ]; then
	print_notif "No jobs configured in cron.hourly . . ."
else
	echo "$out"
	echo ""
fi
echo -e "${C_WHITE}/etc/cron.daily${C_RESET}"
out=$(ls -lh /etc/cron.daily | egrep -v "^total")
if [ -z "$out" ]; then
	print_notif "No jobs configured in cron.daily . . ."
else
	echo "$out"
	echo ""
fi
echo -e "${C_WHITE}/etc/cron.monthly${C_RESET}"
out=$(ls -lh /etc/cron.monthly | egrep -v "^total")
if [ -z "$out" ]; then
	print_notif "No jobs configured in cron.monthly . . ."
else
	echo "$out"
	echo ""
fi

echo -e "${C_WHITE}System Crontab Content${C_RESET}"
if [ -r "/etc/crontab" ]; then
	cat /etc/crontab | egrep -v "^#"
	echo ""
else
	print_notif "/etc/crontab is not readable by the current user . . ."
fi

echo -e "${C_WHITE}User Crontabs${C_RESET}"
out=$(ls -lh /var/spool/cron/crontabs | egrep -v "^total")
if [ -z "$out" ]; then
	print_notif "No User crontabs could be found . . ."
else
	echo "$out"
	echo ""
fi
