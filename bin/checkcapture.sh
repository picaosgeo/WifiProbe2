#!/bin/bash

source /opt/wifiprobe/bin/config

TARGET="$1"

# trap "kill $BASHPID" EXIT
(
#TIMEOUT=30 # タイムアウトに設定する秒数
#count=0
while true; do
  ps=`ps $TARGET | grep $TARGET | grep -v grep | wc -l`
  if [ $ps -eq 0 ]; then # 対象プロセスが存在しない場合
    echo $(TZ=UTC-9 date '+%Y-%m-%d %H:%M:%S :')"wifi probe process died. reboot for restart probe" | /usr/bin/tee -a /opt/wifiprobe/log/wifiprobe$probe_number.log
    reboot
    exit 0
  fi
  sleep 30s
  ((count++))
  # echo "process wait ${count}sec"
done
)
