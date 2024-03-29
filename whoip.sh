#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

which jq > /dev/null || ( echo "ERROR! Need to install jq, https://stedolan.github.io/jq/download/"; exit 1)
which curl > /dev/null || ( echo "ERROR! Need to install curl, https://curl.se/download.html"; exit 1 )

CountryCodes="$(dirname "$0")/country_codes.txt"
readonly CountryCodes
CountryFlags="$(dirname "$0")/country_flags.txt"
readonly CountryFlags
readonly GoogleMaps="google.com/maps/place/"
readonly url="ipinfo.io"

ping -c 1 ${url} > /dev/null 2>&1 || ( echo "ERROR! Can't access URL: ${url}"; exit 1)

# Divider for for
IFS=";"

if ! [ 1 = ${#} ] || ! [[ ${1} =~ ^(0*(1?[0-9]{1,2}|2([0-4][0-9]|5[0-5]))\.){3}0*(1?[0-9]{1,2}|2([0-4][0-9]|5[0-5]))$ ]]; then
    echo "ERROR! We need valid IP address as first argument"
    exit 1
fi

response=$(curl -s "${url}/${1}")

echo "${response}" | grep '"bogon": true' > /dev/null && (echo "ERROR! Can't find anything about ${1}"; exit) 
echo "${response}" | grep 'Wrong ip' > /dev/null && (echo "ERROR! Wrong ip-address ${1}"; exit) 

r=""
i=0

for s in $(echo "${response}" | jq -r ".country, .ip, .city, .region, .org, .timezone, .loc" | tr "\n" ";"); do

    # Add flag and full name of country
    if [ 0 == $i ]; then
        r+=$(grep "$(grep "$s" "${CountryCodes}" | cut -d "," -f1)" "${CountryFlags}" | cut -d "#" -f1)
        r+=" #"
        r+=$(grep "$s" "${CountryCodes}" | cut -d "," -f1)"#"
    fi

    # Trying to add domain name
    ret=0
    nslookup "${1}" > /dev/null || ret=1

    if [ 0 == ${ret} ] && [ 1 == $i ]; then
        r+=$s"#"
        s=""
        r+=$(nslookup "${1}" | grep name | cut -d "=" -f2 | sed -e "s/^.//; s/.$//")
    fi

    # Add URL for location
    if [ 6 == $i ]; then
        r+=${GoogleMaps}
    fi

    i+=1
    r+=$s"#"
done

echo $r | sed "s/#/;/g; s/;null;/;Unknown;/g"

IFS=" "
