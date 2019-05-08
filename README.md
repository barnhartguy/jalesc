# jalesc
DISCLAIMER: This tool is still in VERY early stages of development. Please contact me on twitter @kindredsec if you have any questions/concerns/requests. I will continue adding onto this project for the foreseeable future.

jalesc (Just Another Linux Enumeration Script) is a simple Bash script for locally enumerating a compromised Linux box. It's purpose is to gather some general, basic information to quickly get a general overview of your target system. It gathers various pieces of information such as networking information, user accounts, interesting files, and running services. 

[![asciicast](https://asciinema.org/a/244929.svg)](https://asciinema.org/a/244929)
(NOTE: This asciinema doesn't do a particularly good job at displaying capabilities. It is reccomended to test it on your own system to see its fully functionality).

WHAT MAKES JALESC DIFFERENT?
-------------------
As you can tell by the name, not super much. I wanted to build the script to omit some of the "fluff" that a lot of other enumeration scripts tends to have. This of course could omit some useful information, but the vast majority of the time this script will point you in the right direction. Jalesc also has "focus highlighting," which color codes information of particular interest and value to attackers (such as writable config files, readable history/log files, IP addresses, etc). In summary, Jalesc is the best option for those who want quick, defined path towards escalating privileges. 

CONTACT ME
-------------
* Twitter: https://twitter.com/kindredsec
* Discord: https://discord.gg/CCZCJCu
* Youtube: https://www.youtube.com/channel/UCwTH3RkRCIE35RJ16Nh8V8Q
