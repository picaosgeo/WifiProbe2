#! /bin/bash

source /opt/wifiprobe/bin/config
cd $BIN_DIR/bin

if "${epaper}"; then
  /usr/bin/python $BIN_DIR/bin/epd_clear.py
  echo 'clear ePaper'
fi

# CSVコンバータのpidを確認してkill
pids="/opt/wifiprobe/tmp/*"
for pid in $pids; do
  if test  $pid != "/opt/wifiprobe/tmp/*" ; then
    echo $(TZ=UTC-9 date '+%Y-%m-%d %H:%M:%S :')'CSV conversion process terminated'| /usr/bin/tee -a /opt/wifiprobe/log/wifiprobe$probe_number.log
    kill $(pgrep -P ${pid##*/})
  fi
done

rm -rf $pids

wifiprobetask=$(pidof tshark)

echo $wifiprobetask' - wifiprobe task' 

if test -z $wifiprobetask; then
  echo 'wifiprobe not running'
  #赤色LEDをデフォルトに設定
  echo input | /usr/bin/tee /sys/class/leds/led1/trigger
else
  kill $wifiprobetask
  rm /opt/wifiprobe/status/*
  /usr/sbin/airmon-ng stop wlan0mon
  /usr/bin/systemctl restart NetworkManager
  #緑色LEDをデフォルトに設定
  echo mmc0 | /usr/bin/tee /sys/class/leds/led0/trigger
  echo $(TZ=UTC-9 date '+%Y-%m-%d %H:%M:%S :')$wifiprobetask' - wifiprobe task stopped.'| /usr/bin/tee -a /opt/wifiprobe/log/wifiprobe$probe_number.log
fi

if "${usb_poweroff}"; then
    uhubctl -a on
    echo $(TZ=UTC-9 date '+%Y-%m-%d %H:%M:%S :')"USB power on"
fi

if "${hdmi_poweroff}"; then
    /usr/bin/tvservice -p
    /usr/bin/fbset -depth 8
    /usr/bin/fbset -depth 24
    echo $(TZ=UTC-9 date '+%Y-%m-%d %H:%M:%S :')"HDMI power on"
fi

