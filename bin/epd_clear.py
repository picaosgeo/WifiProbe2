#!/usr/bin/python
# -*- coding:utf-8 -*-
import sys
import os
picdir = os.path.join(os.path.dirname(os.path.realpath(__file__)), 'resources')
libdir = os.path.join(os.path.dirname(os.path.realpath(__file__)), 'lib')
if os.path.exists(libdir):
    sys.path.append(libdir)

import logging
from waveshare_epd import epd2in13b_V4
import time
from PIL import Image,ImageDraw,ImageFont
import traceback

logging.basicConfig(level=logging.INFO)

try:    
    epd = epd2in13b_V4.EPD()
    logging.info("init and Clear")
    epd.init()
    epd.Clear()
    epd.sleep()

finally:
    exit()
