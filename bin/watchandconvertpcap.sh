#!/bin/bash

source /opt/wifiprobe/bin/config

TARGET="$1"

# コンバート先ディレクトリを作成する
CSVDIR="${TARGET##*/}"
DATADIR=$BIN_DIR/data

# 一括CSVファイル名
PROBECSV=$DATADIR/$probe_number"_"$CSVDIR.csv

# mkdir $DATADIR
mkdir $DATADIR/tmp

# trap "kill $BASHPID" EXIT
(
rm -rf $BIN_DIR/tmp/*
touch $BIN_DIR/tmp/$BASHPID

/usr/bin/inotifywait -m -e close_write  --format "%f" $TARGET \
    | while read FILENAME
        do
            echo Detected $FILENAME, "CSV converting..."
            echo tshark $TARGET/$FILENAME "=> " $DATADIR/tmp/$FILENAME.csv
            # $TARGET/$FILENAME をコンバート
            # すでに同じCSVがある場合は、ヘッダをつけない
            /usr/bin/tshark -r $TARGET/$FILENAME  -t ad -T fields -E separator=',' -E header=y  -e _ws.col.Time -e wlan.sa -e wlan.seq -e wlan_radio.signal_dbm >$DATADIR/tmp/$FILENAME.csv
            # ファイル変更とアペンド
            /usr/bin/python $BIN_DIR/bin/cvtprobedata.py $DATADIR/tmp/$FILENAME.csv $PROBECSV

            # pcapの削除指定がある場合、処理済みのpcapは削除
            if [ "${keeppcap}" = false ]; then
                rm -f $DATADIR/tmp/$FILENAME.csv
                rm -f $TARGET/$FILENAME
                echo $(TZ=UTC-9 date '+%Y-%m-%d %H:%M:%S :')"delete " $TARGET/$FILENAME | /usr/bin/tee -a /opt/wifiprobe/log/wifiprobe$probe_number.log
            fi

        done
)

