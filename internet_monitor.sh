#!/bin/zsh

set -o errexit
set -o nounset
set -o pipefail

# Log file in CSV format (located in the same directory as the script)
logfile="${0:a:h}/internet_status.csv"

# Directory for storing status files in tmpfs
status_dir="/dev/shm"

# Get the default gateway IP (router IP)
router_ip=$(ip route show default | awk '/default/ {print $3}')

# Array of hosts to ping
hosts=("1.1.1.1" "ya.ru" "google.com" "$router_ip")

# Function to check ping and log to file
check_ping() {
  local host=$1
  local statusfile="${status_dir}/status_${host//./_}.tmp"
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")

  # Skip DNS resolution for local IP addresses
  if [[ ! "$host" =~ ^(192\.168\.|10\.|172\.(1[6-9]|2[0-9]|3[0-1])\.) ]]; then
    if ! host "$host" &>/dev/null; then
      echo "$timestamp;$host;DNS lookup failed" >> "$logfile"
      return
    fi
  fi

  # Ping the host and check the status
  if ping -c 1 "$host" &>/dev/null; then
    current_status="UP"
  else
    current_status="DOWN"
  fi

  # Check if status file exists and read it
  if [ -f "$statusfile" ]; then
    previous_status=$(cat "$statusfile")
  else
    previous_status=""
  fi

  # Compare current and previous status
  if [ "$current_status" != "$previous_status" ]; then
    echo "$timestamp;$host;$current_status" >> "$logfile"
    echo "$current_status" > "$statusfile"
  fi
}

# Iterate over each host and check
for host in "${hosts[@]}"; do
  check_ping "$host"
done

