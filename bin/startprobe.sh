#! /bin/bash

source /opt/wifiprobe/bin/config

cd $BIN_DIR/bin

# config ファイルチェックと置き換え
if [ -e $BIN_DIR/data/config ]; then
  mv $BIN_DIR/data/config $BIN_DIR/bin/config 
  echo $(TZ=UTC-9 date '+%Y-%m-%d %H:%M:%S :')"config changed boot again" | /usr/bin/tee -a /opt/wifiprobe/log/wifiprobe$probe_number.log
  #赤色LEDをハートビートに
  echo heartbeat | /usr/bin/tee /sys/class/leds/led1/trigger
  sleep 3s
  reboot
fi

# init ファイルチェックとフォルダ初期化
if [ -e $BIN_DIR/data/init ]; then
  rm -f $BIN_DIR/data/init 
  echo $(TZ=UTC-9 date '+%Y-%m-%d %H:%M:%S :')"probe folder initialized" | /usr/bin/tee -a /opt/wifiprobe/log/wifiprobe$probe_number.log
  $BIN_DIR/bin/init/wifiprobeclen.sh
fi


echo "---------------------------"
echo "WifiProbe 1.0 Nov 2026"
echo " -Station  :" $probe_number
echo " -Interval :" $interval
echo "---------------------------"

echo $(TZ=UTC-9 date '+%Y-%m-%d %H:%M:%S :')"--- START wifiprobe ---" | /usr/bin/tee -a /opt/wifiprobe/log/wifiprobe$probe_number.log


# 前処理
# USB,HDMIのパワー停止
if "${usb_poweroff}"; then
    uhubctl -a off
    echo $(TZ=UTC-9 date '+%Y-%m-%d %H:%M:%S :')"USB power off" | /usr/bin/tee -a /opt/wifiprobe/log/wifiprobe$probe_number.log
fi

if "${hdmi_poweroff}"; then
    /usr/bin/tvservice -o
    echo $(TZ=UTC-9 date '+%Y-%m-%d %H:%M:%S :')"HDMI power off" | /usr/bin/tee -a /opt/wifiprobe/log/wifiprobe$probe_number.log
fi

echo $(TZ=UTC-9 date '+%Y-%m-%d %H:%M:%S :')"Prepare wifi monitor" 

# wifiモニター準備
/usr/sbin/airmon-ng check kill
/usr/sbin/airmon-ng start wlan0

# 前回クラッシュリブート時のpidを確認して記録
files="/opt/wifiprobe/status/*"
for filepath in $files; do
  if test  $filepath != "/opt/wifiprobe/status/*" ; then
      PCAPDIR=$BIN_DIR/capture/"${filepath##*/}"
      echo $(TZ=UTC-9 date '+%Y-%m-%d %H:%M:%S :')$PCAPDIR': The last file in the folder may not have been successfully recorded.' | /usr/bin/tee -a /opt/wifiprobe/log/wifiprobe$probe_number.log
      # 最後のファイルを消去する
      # pcapの削除指定がある場合、pcapは削除
      if [ "${keeppcap}" = false ]; then
          rm -f $PCAPDIR/*.pcap
          echo $(TZ=UTC-9 date '+%Y-%m-%d %H:%M:%S :')"delete last pcap file in "$PCAPDIR  | /usr/bin/tee -a /opt/wifiprobe/log/wifiprobe$probe_number.log
      fi
  else
     echo $(TZ=UTC-9 date '+%Y-%m-%d %H:%M:%S :')'Previous startup check normal'| /usr/bin/tee -a /opt/wifiprobe/log/wifiprobe$probe_number.log
  fi
done

rm -rf $files

# CSVコンバータのpidを確認してkill
pids="/opt/wifiprobe/tmp/*"
for pid in $pids; do
  if test  $pid != "/opt/wifiprobe/tmp/*" ; then
      echo $(TZ=UTC-9 date '+%Y-%m-%d %H:%M:%S :')'The last file in the folder may not have been convert to CSV.' | /usr/bin/tee -a /opt/wifiprobe/log/wifiprobe$probe_number.log
  else
     echo $(TZ=UTC-9 date '+%Y-%m-%d %H:%M:%S :')'Previous CSV conversion process check normal'| /usr/bin/tee -a /opt/wifiprobe/log/wifiprobe$probe_number.log
  fi
done

rm -rf $pids

# 日時の取得
wifiprobetaskdate=$(TZ=UTC-9 date '+%Y%m%d%H%M%S')

# キャプチャディレクトリの作成
mkdir /opt/wifiprobe/capture/$wifiprobetaskdate

# ファイル監視＆CSVコンバート子プロセス

/opt/wifiprobe/bin/watchandconvertpcap.sh /opt/wifiprobe/capture/$wifiprobetaskdate & 

# パケットキャプチャのスタート
/usr/bin/tshark -w /opt/wifiprobe/capture/$wifiprobetaskdate/$probe_number.pcap -i wlan0mon -b $mode':'$interval -f 'link[0]==0x40' &

# パケットキャプチャプロセス死活監視（死んでた場合リブート）
/opt/wifiprobe/bin/checkcapture.sh  $!&

# 起動した場合、pidをpidディレクトリに格納
# 緑色LEDを点滅

# echo 'pid取得'
wifiprobetask=$(pidof tshark)
# wifiprobetask=$!

echo $(TZ=UTC-9 date '+%Y-%m-%d %H:%M:%S :')$wifiprobetask' - wifiprobe task' | /usr/bin/tee -a /opt/wifiprobe/log/wifiprobe$probe_number.log

if test -z $wifiprobetask; then
  echo $(TZ=UTC-9 date '+%Y-%m-%d %H:%M:%S :')'wifiprobetask '$wifiprobetaskdate' capture start failed.' | /usr/bin/tee -a /opt/wifiprobe/log/wifiprobe$probe_number.log
  #赤色LEDをハートビートに
  echo heartbeat | /usr/bin/tee /sys/class/leds/led1/trigger
else
  touch /opt/wifiprobe/status/$wifiprobetaskdate
  echo $(TZ=UTC-9 date '+%Y-%m-%d %H:%M:%S :')'wifiprobetask '$wifiprobetaskdate' capture start.' | /usr/bin/tee -a /opt/wifiprobe/log/wifiprobe$probe_number.log
  #緑色LEDを点滅に
  echo timer | /usr/bin/tee /sys/class/leds/led0/trigger

  if "${epaper}"; then
    watch -n $epaper_refresh -t /opt/wifiprobe/bin/dispepaper.sh &
  fi
fi
