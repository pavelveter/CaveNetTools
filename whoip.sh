#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

readonly CountryCodes=$(dirname $0)/country_codes.txt
readonly CountryFlags=$(dirname $0)/country_flags.txt
readonly GoogleMaps="google.com/maps/place/"
readonly url="https://ipinfo.io"

# Divider for for
IFS=";"

response=$(curl -s ${url}/${1})

echo ${response} | grep '"bogon": true' > /dev/null && (echo "\033[31mCan't find anything about\033[0m ${1}"; exit) 
echo ${response} | grep 'Wrong ip' > /dev/null && (echo "\033[31mWrong ip-address\033[0m ${1}"; exit) 

r=""
i=0

for s in $(echo ${response} | jq -r ".country, .ip, .city, .region, .org, .timezone, .loc" | tr "\n" ";"); do

    # Add flag and full name of country
    if (( 0 == $i )); then
        r+=$(grep \#$(grep $s ${CountryCodes} | cut -d "," -f1) ${CountryFlags} | cut -d "#" -f1)
        r+=" #"
        r+=$(grep $s ${CountryCodes} | cut -d "," -f1)"#"
    fi

    # Trying to add domain name
    ret=0
    nslookup ${1} > /dev/null || ret=1

    if (( 0 == ${ret} && 1 == $i )); then
        r+=$s"#"
        s=""
        r+=$(nslookup ${1} | grep name | cut -d "=" -f2 | sed -e "s/^.//; s/.$//")
    fi

    # Add URL for location
    if (( 6 == $i )); then
        r+=${GoogleMaps}
    fi

    let i+=1
    r+=$s"#"
done

echo $r | sed "s/#/;/g; s/;null;/;Unknown;/g" # | pygmentize -O style=paraiso-dark -l awk

IFS=" "
