#!/usr/bin/env python3
import serial
import time

PORT = '/dev/cu.usbserial-110'
BAUD = 19200

print(f'🔌 Открываю порт {PORT}...')
printer = serial.Serial(PORT, BAUD, timeout=2)
print('✅ Порт открыт')

# Сброс
printer.write(b'\x1b\x40')
time.sleep(0.2)

# Пробуем разные кодировки
tests = [
    ('CP866 (код 7)', b'\x1b\x52\x07', 'cp866'),
    ('CP866 (код 15)', b'\x1b\x52\x0f', 'cp866'),
    ('CP1251', b'\x1b\x52\x00', 'cp1251'),
    ('UTF-8 напрямую', b'', 'utf-8'),
]

for name, code, encoding in tests:
    print(f'\n📝 Тест: {name}')
    
    # Сброс
    printer.write(b'\x1b\x40')
    time.sleep(0.1)
    
    # Устанавливаем код страницы
    if code:
        printer.write(code)
        time.sleep(0.1)
    
    # Заголовок
    header = f'\n=== {name} ===\n'
    if encoding == 'utf-8':
        printer.write(header.encode('utf-8'))
    else:
        printer.write(header.encode(encoding, errors='replace'))
    
    # Текст
    text = '''АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ
абвгдеёжзийклмнопрстуфхцчшщъыьэюя
ИП Букреева А.А. Магазин "МЕДВЕДЬ"
'''
    
    if encoding == 'utf-8':
        printer.write(text.encode('utf-8'))
    else:
        printer.write(text.encode(encoding, errors='replace'))
    
    printer.write(b'\n\n')
    time.sleep(1)

# Обрезка
printer.write(b'\x1d\x56\x00')
time.sleep(0.5)

printer.close()
print('\n✅ Все тесты отправлены! Смотри на чек.')
