# Copyright Robomotic 2010
# Author: Paolo Di Prodi
# Email: robomotic@gmail.com
import serial
import threading
import urllib
import string
from datetime import datetime
import time
from struct import *

payload="L:19H:60T:C1"

if payload.find("L")>=0:  
    Lmark=payload.find("L:");
    Lmark+=2
    Hmark=payload.find("H:");
    Tmark=payload.find("T");
    lightstring=payload[Lmark:Hmark]
    textLight=int(lightstring, 16); 
    print textLight
    humhex=payload[Hmark+2:Tmark]
    texthum=int(humhex, 16); 
    print texthum