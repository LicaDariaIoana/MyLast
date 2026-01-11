#!/bin/bash

LOGS="/var/log/auth.log /var/log/auth.log.[1-4]"
numar=0
pana=0
timp=0
count=0

while [ $# -gt 0 ]; do
  case "$1" in
    -n)
      numar="$2"
      shift 2
      ;;
    -s)
      pana=$(date -d "$2" +%s 2>/dev/null)  
      shift 2
      ;;
    -t)
      timp=$(date -d "$2" +%s 2>/dev/null)  
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

grep -hE "pam_unix\(login:auth\): authentication failure|Failed password" $LOGS 2>/dev/null | while read line; do
    if echo "$line" | grep -q 'user='; then
	user=$(echo "$line" | grep -o ' user=[^ ;]*' | cut -d= -f2)
    else
	user=$(echo "$line" | awk '{for(i=1;i<=NF;i++) if($i=="for") {if($(i+1)=="invalid") print $(i+3); else print $(i+1)}}')
    fi 

    terminal=$(echo "$line" | grep -o 'TTY=[^ ;]*' | cut -d= -f2)
    [ -z "$terminal" ] && terminal="ssh:notty"

    ip=$(echo "$line" | grep -oE 'from [0-9.]*' | awk '{print $2}')
    [ -z "$ip" ] && ip="N/A"

    timp_start=$(echo "$line" | awk '{print $1}')
    start_sec=$(date -d "$timp_start" +%s)

    if [ "$timp" -ne 0 ] && [ "$start_sec" -ge "$timp" ]; then
        continue
    fi

    if [ "$pana" -ne 0 ] && [ "$start_sec" -lt "$pana" ]; then
        continue
    fi

    echo "USER=$user | TERMINAL=$terminal | IP=$ip | $(date -d "$timp_start" '+%a %b %d %H:%M') - $(date -d "$timp_start" '+%H:%M') (00:00)"


    if [ "$numar" -ne 0 ]; then
        count=$((count + 1))
        if [ "$count" -ge "$numar" ]; then
            break
        fi
    fi
done
