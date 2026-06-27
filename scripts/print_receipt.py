#!/usr/bin/env python3
import serial
import time
import json
import sys
import os
from datetime import datetime
import warnings
warnings.filterwarnings('ignore')

def detect_port():
    """Автоматическое определение порта на разных ОС"""
    if sys.platform == 'win32':
        # Windows - пробуем COM порты
        for port in ['COM3', 'COM4', 'COM5', 'COM6', 'COM7', 'COM8']:
            try:
                test = serial.Serial(port, 19200, timeout=1)
                test.close()
                return port
            except:
                continue
    elif sys.platform == 'darwin':
        # macOS
        ports = ['/dev/cu.usbserial-110', '/dev/cu.usbserial-10', '/dev/tty.usbserial-110']
        for port in ports:
            try:
                test = serial.Serial(port, 19200, timeout=1)
                test.close()
                return port
            except:
                continue
    else:
        # Linux
        ports = ['/dev/ttyUSB0', '/dev/ttyUSB1']
        for port in ports:
            try:
                test = serial.Serial(port, 19200, timeout=1)
                test.close()
                return port
            except:
                continue
    return None

# Остальной код тот же, что и раньше...
# (копируем полный скрипт сюда)
