#!/bin/bash

LOGS="/var/log/auth.log /var/log/auth.log.[1-4]"
numar=0
din=0
pana=0
timp=0
count=0

while [ $# -gt 0 ]; do
  case "$1" in
    -n)
      numar="$2"
      shift 2
      ;;
    -p)
      din=$(date -d "$2" +%s 2>/dev/null)  
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

grep -h "pam_unix(login:session): session" $LOGS 2>/dev/null | while read line; do
    user=$(echo "$line" | awk '{for(i=1;i<=NF;i++) if($i=="user") print $(i+1)}')
    terminal=$(echo "$line" | grep -o 'TTY=[^ ;]*' | cut -d= -f2)
    [ -z "$terminal" ] && terminal="LOCAL"
    ip=$(echo "$line" | grep -oE 'from [0-9.]*' | awk '{print $2}')
    [ -z "$ip" ] && ip="N/A"
    timp_start=$(echo "$line" | awk '{print $1}')
    pid=$(echo "$line" | awk '{print $3}')
    linie_oprire=$(grep "session closed" $LOGS 2>/dev/null | grep "$pid")
    start_sec=$(date -d "$timp_start" +%s)

    if [ "$timp" -ne 0 ] && [ "$start_sec" -ge "$timp" ]; then
        continue
    fi

    stop_sec=0
    if [ -n "$linie_oprire" ]; then
        timp_oprire=$(echo "$linie_oprire" | awk '{print $1}')
        stop_sec=$(date -d "$timp_oprire" +%s)
    fi

    if [ "$pana" -ne 0 ] && [ "$start_sec" -lt "$pana" ]; then
        continue
    fi

    if [ "$din" -ne 0 ]; then
        if [ "$stop_sec" -ne 0 ]; then
            if [ "$stop_sec" -lt "$din" ] && [ "$start_sec" -gt "$din" ]; then
                continue
            fi
        else
            if [ "$start_sec" -gt "$din" ]; then
                continue
            fi
        fi
    fi

    if [ -n "$linie_oprire" ]; then
        diff_sec=$((stop_sec - start_sec))
        ore=$((diff_sec / 3600))
        minute=$(((diff_sec % 3600) / 60))
        echo "USER=$user | TERMINAL=$terminal | IP=$ip | $(date -d "$timp_start" '+%a %b %d %H:%M') - $(date -d "$timp_oprire" '+%H:%M') ($ore:$minute)"
    else
        echo "USER=$user | TERMINAL=$terminal | IP=$ip | $(date -d "$timp_start" '+%a %b %d %H:%M') - still running"
    fi

    if [ "$numar" -ne 0 ]; then
        count=$((count + 1))
        if [ "$count" -ge "$numar" ]; then
            break
        fi
    fi
done
