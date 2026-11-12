# WiFi Probe

Kali Linux on raspberry pi 3B,4B 上に 自動Wifi Probe 環境を構築する。

### ハードウェア準備

---

- Raspberry Pi 3 シリーズ 以降
- Seed Studio RTC HAT(ds1307) DigiKey等で購入
- Waveshare 2.13inch e-Paper HAT (B) Amazon等で購入

### インストール

---

- 利用環境が整っているものとする。（kali linux microSDメディアの構成を参照）
- Kali linux を使用する。
- GUIモードで、スクリーンセーバーのOFF,スリープの無効化を行う

- 初期起動をCLIに変更、sshdを起動しておく

```shell
sudo systemctl set-default multi-user
systemctl enable --now ssh
```

- pythonライブラリのインストール（グローバル）

```shell
pip install textfile
```

- RTC関連のモジュールをインストールする。

```shell
sudo apt install lua5.4
sudo mkdir /opt/rtc
cd /opt/rtc
sudo git clone https://github.com/Seeed-Studio/pi-hats.git
cd pi-hats/tools
cd pi-hats
sudo ./install.sh -u rtc_ds1307
sudo shutdown -h now

# RTCモジュールを取り付ける
# 再度起動してインストールを確認

cd /opt/rtc/pi-hats/tools
./install.sh -l

# 現在のRTCの時刻を確認
sudo hwclock -r
```

- 電圧監視用のライブラリをインストールする

```shell
sudo apt -y install libraspberrypi-bin
```

- USB給電制御用のライブラリをインストールする

```shell
sudo -i
sudo apt -y install uhubctl
```

- ファイル監視用のライブラリをインストールする

```shell
sudo -i
sudo apt -y install inotify-tools
```

- <wifiprobe>ユーザーを設定する（root権限が必要）

- /opt/ に wifiprobeディレクトリをコピーする
- /opt/wifiprobe以下に<wifiprobe>グループ権限を付加する（任意）
- rootのcrontabに@reboot /usr/sbin/iw dev wlan0 set power_save off を設定する

```shell
echo '@reboot /opt/wifiprobe/bin/init/wifipowersaveoff.sh' | crontab
```

- ホスト名を設定する。ステーション番号と同じにする。

```shell
sudo /opt/wifiprobe/bin/init/change_host_name <ホスト名>
```

- /opt/wifiprobe/bin/config を編集し、probe_numberと intervalをセットする

- 再起動して再度 /opt/wifiprobe/binに移動し、サービスを登録する。

```shell
cd /etc/systemd/system
ln -s /opt/wifiprobe/bin/init/wifiprobe.service wifiprobe.service
systemctl daemon-reload
systemctl enable wifiprobe.service
systemctl status wifiprobe.service
reboot
```

- ssh でログインする

- /opt/wifiprobe/log/を確認し、wifiprobeが開始していることを確認する。
- sudo systemctl stop wifiprobe.service 実行し、probeが停止することを確認する。
- /opt/wifiprobe/bin/init/wifiprobecleanup.shを起動し、確認テストで生成されたファイルをクリアする。
- 再起動し、wifiprobeが自動で開始されることを確認する

### config

---

probeの設定ファイル

```bash
readonly BIN_DIR='/opt/wifiprobe'　#インストールディレクトリ
readonly probe_number='001'　# probeステーションの番号が001である。
readonly mode='filesize'  # mode: duration (sec), filesize (KB),
readonly interval=10 # tsharkがキャプチャファイルを変更するインターバル秒数
readonly usb_poweroff=false #USB給電のON/OFF
readonly hdmi_poweroff=false # HDMIの電源のON/OFF
readonly keeppcap=false
readonly epaper=true  # ePaperを使用する
readonly epaper_refresh=180 # ePaperを再描画する間隔（秒）
```

上記設定の場合、capture ディレクトリにはキャプチャ開始時刻のフォルダと10秒ごとの連番ファイルが記録される
（注意事項）実際の使用では、10秒でローテションした場合、メモリエラーが発生してキャプチャできなくなる。
duration指定の場合、600 くらいの値を使用すること。

```
yyyymmddhhMMssss/probe_number_nnnnn_yyyymmddhhMMss.pcap
ex) 2023072518331690277631/001_00001_20230725183355.pcap
                           001_00002_20230725183405.pcap
                           001_00003_20230725183415.pcap
```

## 起動の確認

wifiprobeの状態については本体のLEDで確認することができる。

|         |      初期       | 動作中 |  自動起動異常   |
| :-----: | :-------------: | :----: | :-------------: |
| 赤色LED |      点灯       |  点灯  |  ハートビート   |
| 緑色LED | 消灯 / 時々点灯 |  点滅  | 消灯 / 時々点灯 |

## kali linux microSDメディアの構成

wifiprobeの起動メディアは次の様なパーティションにすること。
fat32のDATAパーティションは必須。

BOOT : ブート領域

LINUX : OS領域（/opt/wifiprobe/）

DATA : /opt/wifiprobe/dataに自動マウント（fat32）

### DATAパーティションを自動マウントする設定

/etc/fstab を編集し、DATAパーティションのUUIDをマウント登録する

blkidで"DATA"のUUIDを確認する

```
┌──(kali㉿wpst002)-[~]
└─$ sudo blkid
/dev/mmcblk0p3: LABEL_FATBOOT="DATA" LABEL="DATA" UUID="C415-C97B" BLOCK_SIZE="512" TYPE="vfat" PARTUUID="3a59bff4-03"
/dev/mmcblk0p1: LABEL_FATBOOT="BOOT" LABEL="BOOT" UUID="C7D0-84C0" BLOCK_SIZE="512" TYPE="vfat" PARTUUID="3a59bff4-01"
/dev/mmcblk0p2: LABEL="ROOTFS" UUID="f5181791-acfc-493e-ab5a-ae537e8aa9ce" BLOCK_SIZE="4096" TYPE="ext4" PARTUUID="3a59bff4-02"

```

/etc/fstabに登録する

```
/etc/fstab
# <file system> <mount point>   <type>  <options>       <dump>  <pass>
proc            /proc           proc    defaults          0       0

UUID=f5181791-acfc-493e-ab5a-ae537e8aa9ce /               ext4 errors=remount-ro 0       1
UUID=C415-C97B                          /opt/wifiprobe/data   vfat   defaults 0   0
LABEL=BOOT      /boot           vfat    defaults          0       2

```

再起動して、/opt/wifiprobe/dataとしてマウントされていることを確認する

## ディレクトリの構造

```
.
├── bin
│   ├── config # 設定パラメータファイル
│   ├── init　# 初期設定用
│   │   ├── wifiprobe.service #systemd サービスファイル
│   │   ├── checkthrottled.sh #電圧状態チェック
│   │   ├── chkvolt.sh # 電圧状態監視スクリプト
│   │   ├── wifiprobeclen.sh  # 処理フォルダ初期化スクリプト
│   │   └── wifipowersaveoff.sh # WiFiチップのパワーOFF防止スクリプト
│   ├── lib # epaper関連ライブラリ
│   ├── resources # ロゴ、フォントファイル
│   │
│   ├── startprobe.sh　# wifiprobe起動スクリプト
│   ├── checkcapture.sh　# キャプチャプロセス監視スクリプト
│   ├── cvtprobedata.py　# CSV一括変換プログラム
│   ├── watchandconvertpcap.sh　# CSV変換処理監視スクリプト
│   ├── dispepaper.sh　# ePaper表示スクリプト
│   ├── epd_monitor.py　# ePaper表示プログラム
│   ├── epd_clear.py　# ePaper表示初期化プログラム
│   ├── epd_stop.py　# ePaper収録終了表示プログラム
│   └── stopprobe.sh  # wifiprobe停止スクリプト
│
├── capture　# パケットキャプチャフォルダ
├── data　# パケット変換用 => microSDのfat32領域をここにマウントしている
├── log # 動作ログ出力フォルダ
├── tmp # ファイル監視動作pid
├── status　# 状態記録用、記録中のcaptureのプローブフォルダ名がある
└── readme.md
```

## config の変更適用

１）microSDのルートに入れ替えるconfigを作成

２）microSDを挿入してraspiを起動

３）新しいconfigが適用される

## 収録フォルダの初期化

１）microSDのルートにinitというファイル名のファイルを作成

- touch init などでOK、中身はなんでもよい

２）microSDを挿入してraspiを起動

３）capture , data, status, tmp フォルダがクリアされる

手動でクリアする場合のコマンド
sudo /opt/wifiprobe/init/wifiprobeclen.sh

## 追加

## e-paper hat インストール

１）SPIコンフィグレーション用ツールインストール

```
wget http://archive.raspberrypi.org/debian/pool/main/r/raspi-config/raspi-config_20230214_all.deb

sudo dpkg -i raspi-config_20230214_all.deb
sudo raspi-config
Choose Interfacing Options -> SPI -> Yes Enable SPI interface

sudo reboot
```

再起動後、 /boot/config.txt　をチェックする。 'dtparam=spi=on' があることを確認する。

ドライバーがインストールされていることを確認する。

```
ls /dev/spi*
/dev/spidev0.1 /dev/spidev0.1
```

e-Paperのソースコードをダウンロードして、サンプルを動かしてみる。

```
sudo pip3 install RPi.GPIO
sudo pip3 install spidev

git clone https://github.com/waveshare/e-Paper.git

cd e-Paper/RaspberryPi_JetsonNano/
cd python/examples/
python3 epd_2in13b_V4_test.py
```

https://www.waveshare.com/wiki/2.13inch_e-Paper_HAT_(B)_Manual#Introduction

## 制限事項

- 電源切断時、収録中の最後のキャプチャファイルはCSVに反映されない。
- sudo systemctl stop wifiprobe を行ったあと、start wifiprobe でtsharkが動かない場合、自動的にリブートされ、収録が自動開始される。
- ePaperの表示更新中にリブートし、表示が異常になった場合、python /opt/wifiprobe/bin/epd_clear.py を実行する。
- 手動で収録を終了する場合、sudo systemctl stop wifiprobe を実行する。再スタートは sudo reboot で行う。
- ePaperの再描画時間が45秒のため、 wifiprobe.service は TimeoutSec=50 に設定している。

## License

This project is licensed under the MIT License - see the LICENSE file.
`bin/lib/waveshare_epd/` is from Waveshare e-Paper (MIT-style license, see file headers).
