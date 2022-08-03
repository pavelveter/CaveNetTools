#!/bin/zsh

set -o errexit
set -o nounset
set -o pipefail

readonly mikrotik=192.168.88.1
readonly port=2200
readonly user=admin

readonly vendict=$(dirname $0)/oui.txt

readonly c_violet="e[35m"
readonly c_green="e[32m"
readonly c_red="e[31m"
readonly c_reset="e[0m"

readonly unknown="${c_violet}__UNKNOWN__${c_reset}"
readonly cnc="${c_green}CONNECT${c_reset}  "
readonly wot="${c_red}WAITING${c_reset}  "

[[ -s ${vendict} ]] || (echo -e "Wait a minute, downloading database of vendors...\n"; \
                        wget http://standards.ieee.org/develop/regauth/oui/oui.txt)

while read line; do
    if [[ ${line} == *${unknown}* ]]; then 
        vendor=$(grep $(echo ${line} | tr -s " " | cut -d " " -f3 \
                | cut -d "-" -f1,2,3) ${vendict} | cut -c 19-)

        echo -e ${line//e\[/\\e[} by ${vendor}
    else
        echo -e ${line//e\[/\\e[}
    fi
done <<< $( \
    ssh ${user}@${mikrotik} -p ${port} 'ip dhcp-server lease print' \
    | awk 'FIELDWIDTHS="5 15 4 17 1 4" { \
            if (index($4, ":")) { \
                ip=$2; mac=$4; gsub(":", "-", mac); \
                cnt=substr($0, 66, 2);  gsub("b", "'${cnc}'", cnt); gsub("w", "'${wot}'", cnt); \
                if (index(t, ";")) { rem=substr(t, 10, length(t)-10) } else { rem="'${unknown}'" } \
                printf "%s %s %s   %s\n", ip, cnt, mac, rem
            } \
        t=$0; }' \
)
