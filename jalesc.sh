#!/bin/bash

C_RESET='\033[0m'
C_RED='\033[1;31m'
C_GREEN='\033[1;32m'
C_YELLOW='\033[1;33m'
C_BLUE='\033[1;34m'
C_WHITE='\033[1;37m'
C_RESET_SED='\033[0m'
C_RED_SED='\\033[1;31m'
C_GREEN_SED='\\033[1;32m'
C_YELLOW_SED='\\033[1;33m'
C_BLUE_SED='\\033[1;34m'
C_WHITE_SED='\\033[1;37m'

function print_err {
    echo -e "${C_RED}[-]${C_RESET} $1"
}

function print_notif {
    echo -e "${C_YELLOW}[!]${C_RESET} $1"
}

function print_success {
    echo -e "${C_GREEN}[+]${C_RESET} $1"
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
if [ -n "$(which ifconfig 2>/dev/null)" ]; then
    ifout=$(ifconfig)
    inetaddrs=$(echo "$ifout" | grep -o "inet addr:[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}")
else
    ifout=$(ip addr show)
    inetaddrs=$(echo "$ifout" | grep -o "inet[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}")
fi

while read -r addr; do
    ifout=$(echo "$ifout" | sed "s/${addr}/${C_BLUE_SED}${addr}${C_RESET_SED}/g")
done <<< "$inetaddrs"
echo -e "$ifout"
note_highlight "ipv4 addresses"

echo "----------------------------"
echo -e "${C_WHITE}ARP CACHE${C_RESET}"
echo "----------------------------"
cat /proc/net/arp
echo ""

echo "----------------------------"
echo -e "${C_WHITE}LISTENING SOCKETS${C_RESET}"
echo "----------------------------"
netstat -auntp 2>/dev/null | egrep "(Proto|LISTEN|udp)"
echo ""

echo "----------------------------"
echo -e "${C_WHITE}ESTABLISHED CONNECTIONS${C_RESET}"
echo "----------------------------"
netstat -auntp 2>/dev/null | egrep -v "(LISTEN|udp)"
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
if [ -n "$(which last 2>/dev/null" ] && [ -f "/var/log/wtmp" ]; then
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
    users=$(echo "$sshhist" | grep -o "for .* from" | cut -d " " -f 2 | sort | uniq)
    while read -r user; do
        sshhist=$(echo "$sshhist" | sed "s/${user}/${C_BLUE_SED}${user}${C_RESET_SED}/g")
    done <<< "$users"
    echo -e "$sshhist"
    note_highlight "accounts trying to authenticate"
fi

echo "----------------------------"
echo -e "${C_WHITE}HOME DIRECTORIES${C_RESET}"
echo "----------------------------"
echo ""
homedirs=$(ls -lah /home/)
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


echo "#################################################"
echo "#           SECTION: Interesting Files          #"
echo "#################################################"
echo ""

echo "----------------------------"
echo -e "${C_WHITE}SET UID BINARIES${C_RESET}"
echo "----------------------------"
echo ""
defaultSetUIDs="/usr/bin/at /usr/bin/Xorg /usr/bin/crontab /usr/bin/chfn /usr/bin/sudo /usr/bin/gpasswd \
                /usr/bin/passwd /usr/bin/pkexec /bin/ping /bin/su /bin/umount /bin/fusermount /bin/ping6 \
                /bin/mount /sbin/mount.nfs"
suids=$(find / -type f -perm -4000 -exec ls -la {} \; 2>/dev/null)
suidsFilenames=$(echo "$suids" | rev | cut -d " " -f 1 | rev)
while read -r suid; do
    if [ $(echo "$defaultSetUIDs" | grep -c "$suid") -eq 0 ]; then
        suid=$(echo "$suid" | sed "s/\//\\\\\//g")
        suids=$(echo "$suids" | sed "s/${suid}/${C_BLUE_SED}${suid}${C_RESET_SED}/g")
    fi
done <<< "$suidsFilenames"
echo -e "$suids"
note_highlight "\"non-standard\" SUID binaries"