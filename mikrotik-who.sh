#!/bin/zsh

set -o errexit
set -o nounset
set -o pipefail

readonly mikrotik=192.168.88.1
readonly port=2200
readonly user=admin

readonly vendict=$(dirname $0)/oui.txt

readonly unknown="e[35m__UNKNOWN__e[39m"
readonly cnc="e[32mCONNECTe[39m  "
readonly wot="e[31mWAITINGe[39m  "

[[ -s ${vendict} ]] || (echo -e "\e[31mWait a minute, downloading database of vendors...\n\e[39m"; \
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
