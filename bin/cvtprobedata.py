# -*- coding: utf-8 -*-
"""
/***************************************************************************
Name                 : cvtprobedata
Description          : pcapをcsvに変換したデータを加工する
Date                 : November, 2026
copyright            : (C) 2026 by Hirofumi Hayashi
email                : 
 ***************************************************************************/
"""

__author__ = "Hirofumi Hayashi"
__date__ = "2026-11-27"
__copyright__ = "(C) 2026, Hirofumi Hayashi"
__revision__ = "$Format:%H$"


import csv
import datetime
import time
import locale
import math
import os
import sys
from os import getenv
import argparse
import textfile
import hashlib


def main(argv) -> int:
    ret,src,dest = parse_argv(argv)
    if ret==False:
        # Something is wrong
        return 1

    # 引数のCSVファイルをコンバート処理する
    try:
        ret=convertdata(src,dest)
        print("convert and append:{0}->{1}".format(src.replace('.csv',''),dest))
        return ret

    except ValueError:
        return 1

# CSVデータをリードして、日付の分割とMACをmd5変換する
def convertdata(src,dest) ->bool:

    # srcをオープンして読み込み
    # ヘッダはそのまま出力
    #
    try:
        #アペンド用のファイルが存在しなかった場合、ヘッダを出力する
        chk = os.path.isfile(dest)

		# 出力ファイルオープン
        with open( src, "r", encoding='utf-8', newline='' ) as fr:
            reader=csv.reader(fr)
            with open( dest, "a", encoding='utf-8', newline='' ) as fw:
                if chk == False:
                    fw.writelines("{0}\n".format("date,time,sa,wlan.seq,wlan_radio.signal_dbm"))
                dmy=next(reader)
                for row in reader:
                    dd,dt=row[0].split(' ')
                    dd=dd.replace('-','/')
                    hash=hashlib.md5(row[1].encode("utf-8")).hexdigest()
                    fw.writelines("{0},{1},{2},{3},{4}\n".format(dd,dt,hash,row[2],row[3]))

				# 出力ファイルを閉じる
                fw.close()
            fr.close()

    except Exception as err:
        print(f"Unexpected {err=}, {type(err)=}")
        return False
    return True
    
def parse_argv(argv) -> [bool,str,str]:
    try:
        srcname = argv[1]
        destname = argv[2]

    except ValueError:
        print >> sys.stderr, __doc__
        return False,'',''

    return True, srcname, destname


if __name__ == "__main__":
    main(sys.argv)
