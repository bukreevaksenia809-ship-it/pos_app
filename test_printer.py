#!/usr/bin/env python3
import serial
import time

# Порт и скорость
PORT = '/dev/cu.usbserial-110'
BAUD = 19200

try:
    print(f'🔌 Открываю порт {PORT}...')
    printer = serial.Serial(PORT, BAUD, timeout=1)
    print('✅ Порт открыт')
    
    # Сброс
    printer.write(b'\x1b\x40')
    time.sleep(0.1)
    
    # Устанавливаем кодировку
    print('📝 Устанавливаю кодировку PC866 (код 7)...')
    printer.write(b'\x1b\x52\x07')
    time.sleep(0.1)
    
    # Тестовый текст
    test_text = '''
========================================
ТЕСТ ПРИНТЕРА ATOL RP326USE
PC866 [Cyrillic] - код 7
========================================

АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ
абвгдеёжзийклмнопрстуфхцчшщъыьэюя

ИП Букреева А.А. Магазин "МЕДВЕДЬ"
397855, Воронежская область, г. Воронеж, ул. Херсонская, д. 21а
ИНН 361913652004

ИТОГ: 1234.56 ₽
Сдача: 567.89 ₽

========================================
'''
    
    # Отправляем текст в кодировке CP866
    print('📤 Отправляю тестовый текст...')
    printer.write(test_text.encode('cp866', errors='replace'))
    printer.write(b'\n\n\n')
    
    # Обрезка бумаги
    printer.write(b'\x1d\x56\x00')
    
    printer.close()
    print('✅ Тест отправлен! Смотри на чек.')
    
except Exception as e:
    print(f'❌ Ошибка: {e}')
