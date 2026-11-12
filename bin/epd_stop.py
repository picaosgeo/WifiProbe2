#!/usr/bin/python
# -*- coding:utf-8 -*-
"""
/***************************************************************************
Name                 : epd_stop.py
Description          : WiFi Probe の動作状況のePaperモニタ表示
Date                 : November, 2026
copyright            : (C) 2026 by Hirofumi Hayashi
email                : 
 ***************************************************************************/
"""

__author__ = "Hirofumi Hayashi"
__date__ = "2026-11-27"
__copyright__ = "(C) 2026, Hirofumi Hayashi"
__revision__ = "$Format:%H$"

import sys
import os
import datetime
import subprocess
from dataclasses import dataclass

picdir = os.path.join(os.path.dirname(os.path.realpath(__file__)), 'resources')
libdir = os.path.join(os.path.dirname(os.path.realpath(__file__)), 'lib')
confgfile = os.path.join(os.path.dirname(os.path.realpath(__file__)), 'config')

if os.path.exists(libdir):
    sys.path.append(libdir)

import logging
from waveshare_epd import epd2in13b_V4
import time
from PIL import Image,ImageDraw,ImageFont
import traceback


@dataclass
class config:
    bin_dir: str = ''
    probe_number: str = '000'
    mode: str = 'filesize'
    interval: int = 10
    usb_poweroff: bool = False
    hdmi_poweroff: bool = False
    keeppcap: bool = False
    epaper: bool = False
    recording_folder: str = ''
    temp: str = '--\'C'
    volt: str = '--v'
    packetcount: int = 0



def main() -> int:
    logging.basicConfig(level=logging.INFO)

    try:        
        epd = epd2in13b_V4.EPD()
        logging.info("init and Clear")
    
        # 現在の表示の消去
        epd.init()
        epd.Clear()
        time.sleep(1)

        status = False
        # モニターデータの取得
        # configを読み込んでパラメータを取得
        myconfig = config()

        if readconfig(confgfile,myconfig) == False :
            logging.info("error: config read error")
            epd.sleep()
            sys.exit(1)

        # 温度と電圧
        temp = subprocess.run(['vcgencmd','measure_temp'], capture_output=True)
        volt = subprocess.run(['vcgencmd','measure_volts'], capture_output=True)
        v = volt.stdout.decode().strip().split('=')[1].replace("V","")

        myconfig.temp = temp.stdout.decode().strip().split('=')[1]
        myconfig.volt = str(float(v) )+ "V"


        # 表示日付
        dt_now = datetime.datetime.now().strftime("%Y/%m/%d %H:%M:%S")


        # モニターデータ表示

        font20 = ImageFont.truetype(os.path.join(picdir, 'Font.ttc'), 20)
        font18 = ImageFont.truetype(os.path.join(picdir, 'Font.ttc'), 18)
        font16 = ImageFont.truetype(os.path.join(picdir, 'Font.ttc'), 16)
        font12 = ImageFont.truetype(os.path.join(picdir, 'Font.ttc'), 12)

        # e-Paperヘッダロゴ部分描画
        logging.info("Draw WiFi Prove config information ...") 
        HBlackimage = Image.new('1', (epd.height, epd.width), 255)  # 250*122
        HRYimage = Image.new('1', (epd.height, epd.width), 255)  # 250*122
        drawblack = ImageDraw.Draw(HBlackimage)
        drawry = ImageDraw.Draw(HRYimage)
        drawry.line((0, 29, 249, 29), fill = 0, width = 3)
        newimage = Image.open(os.path.join(picdir, 'logo32x26.bmp'))
        HBlackimage.paste(newimage, (1,1))
        drawblack.text((38, 0), 'WifiProbe 1.0', font = font20, fill = 0)
        drawblack.text((10, 30), 'Stn:{0}  電圧:{1}  温度:{2}'.format(myconfig.probe_number,myconfig.volt,myconfig.temp), font = font16, fill = 0)
        drawblack.text((10, 30+18), '記録間隔:{0} {1}    電源(USB:{2} HDMI:{3})'.format( \
                    myconfig.interval,\
                    ('sec' if myconfig.mode == 'duration' else 'KB'),\
                    ('切' if myconfig.usb_poweroff else '入'),\
                    ('切' if myconfig.hdmi_poweroff else '入')\
                    ), font = font12, fill = 0)

        # Drawing on the Horizontal image
        logging.info("Draw WiFi Probe stop Information ...")
        drawry.text((10, 34+16*2), '収録を終了しました', font = font16, fill = 0)
        drawry.text((10, 40+16*4), '({0} 更新)'.format(dt_now), font = font12, fill = 0)

        epd.display(epd.getbuffer(HBlackimage), epd.getbuffer(HRYimage))

        time.sleep(2)
        logging.info("Goto Sleep...")
        epd.sleep()

        sys.exit(0)

            
    except IOError as e:
        logging.info(e)
        sys.exit(1)
        
    except KeyboardInterrupt:    
        logging.info("ctrl + c:")
        epd2in13b_V4.epdconfig.module_exit()
        sys.exit(1)

# config ファイルをconfigデータクラスに読み込む
def readconfig(src, cfg:config) ->[bool]:
    try:
        with open( src, "r", encoding='utf-8', newline='' ) as fr:
            for l in fr.read().splitlines() :
                if l != "" :
                    l.strip()
                    if l.startswith('readonly') :
                        ll=l.split(" ")
                        lll=ll[1].split("=")
                        if lll[0] == "BIN_DIR" :
                            cfg.bin_dir = lll[1].strip("'")
                        elif lll[0] == "probe_number" :
                            cfg.probe_number = lll[1].strip("'")
                        elif lll[0] == "mode" :
                            cfg.mode = lll[1].strip("'")
                        elif lll[0] == "interval" :
                            cfg.interval = lll[1].strip("'")
                        elif lll[0] == "usb_poweroff" :
                            cfg.usb_poweroff = lll[1].strip("'")
                        elif lll[0] == "hdmi_poweroff" :
                            cfg.hdmi_poweroff = lll[1].strip("'")
                        elif lll[0] == "keeppcap" :
                            cfg.keeppcap = lll[1].strip("'")
                        elif lll[0] == "epaper" :
                            cfg.epaper = lll[1].strip("'")
                        else :
                            pass
        fr.close()
        
    except ValueError:
        print >> sys.stderr, __doc__
        return False

    return True

if __name__ == "__main__":
    main()
