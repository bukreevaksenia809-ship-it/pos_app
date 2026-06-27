#!/usr/bin/env python3
import serial
import time

def encode_cp866(text):
    """Таблица CP866 для теста"""
    cp866 = {
        # Заглавные буквы (А-Я)
        0x0410: 0x80, 0x0411: 0x81, 0x0412: 0x82, 0x0413: 0x83,
        0x0414: 0x84, 0x0415: 0x85, 0x0416: 0x86, 0x0417: 0x87,
        0x0418: 0x88, 0x0419: 0x89, 0x041A: 0x8A, 0x041B: 0x8B,
        0x041C: 0x8C, 0x041D: 0x8D, 0x041E: 0x8E, 0x041F: 0x8F,
        0x0420: 0x90, 0x0421: 0x91, 0x0422: 0x92, 0x0423: 0x93,
        0x0424: 0x94, 0x0425: 0x95, 0x0426: 0x96, 0x0427: 0x97,
        0x0428: 0x98, 0x0429: 0x99, 0x042A: 0x9A, 0x042B: 0x9B,
        0x042C: 0x9C, 0x042D: 0x9D, 0x042E: 0x9E, 0x042F: 0x9F,
        # Строчные буквы (а-я)
        0x0430: 0xA0, 0x0431: 0xA1, 0x0432: 0xA2, 0x0433: 0xA3,
        0x0434: 0xA4, 0x0435: 0xA5, 0x0436: 0xA6, 0x0437: 0xA7,
        0x0438: 0xA8, 0x0439: 0xA9, 0x043A: 0xAA, 0x043B: 0xAB,
        0x043C: 0xAC, 0x043D: 0xAD, 0x043E: 0xAE, 0x043F: 0xAF,
        0x0440: 0xB0, 0x0441: 0xB1, 0x0442: 0xB2, 0x0443: 0xB3,
        0x0444: 0xB4, 0x0445: 0xB5, 0x0446: 0xB6, 0x0447: 0xB7,
        0x0448: 0xB8, 0x0449: 0xB9, 0x044A: 0xBA, 0x044B: 0xBB,
        0x044C: 0xBC, 0x044D: 0xBD, 0x044E: 0xBE, 0x044F: 0xBF,
        # Ё и ё
        0x0401: 0xF0, 0x0451: 0xF1,
    }
    
    result = []
    for ch in text:
        code = ord(ch)
        if code < 128:
            result.append(code)
        else:
            result.append(cp866.get(code, 0x3F))
    return bytes(result)

def print_test():
    try:
        port = serial.Serial('/dev/cu.usbserial-110', 19200, timeout=2)
        print('✅ Порт открыт')
        
        # Инициализация
        port.write(b'\x1b\x40')
        time.sleep(0.1)
        port.write(b'\x1b\x52\x07')  # CP866 код 7
        time.sleep(0.1)
        
        # Заголовок
        port.write(encode_cp866('=' * 50 + '\n'))
        port.write(encode_cp866('ТЕСТ ВСЕХ РУССКИХ БУКВ\n'))
        port.write(encode_cp866('=' * 50 + '\n\n'))
        
        # Заглавные буквы
        uppercase = 'АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ'
        port.write(encode_cp866('ЗАГЛАВНЫЕ:\n'))
        for i, letter in enumerate(uppercase):
            code = hex(ord(letter))
            cp = hex(encode_cp866(letter)[0])
            port.write(encode_cp866(f'{letter}  {code} -> CP866:{cp}\n'))
            time.sleep(0.01)
        
        port.write(encode_cp866('\n'))
        
        # Строчные буквы
        lowercase = 'абвгдеёжзийклмнопрстуфхцчшщъыьэюя'
        port.write(encode_cp866('СТРОЧНЫЕ:\n'))
        for i, letter in enumerate(lowercase):
            code = hex(ord(letter))
            cp = hex(encode_cp866(letter)[0])
            port.write(encode_cp866(f'{letter}  {code} -> CP866:{cp}\n'))
            time.sleep(0.01)
        
        port.write(encode_cp866('\n\n'))
        
        # Обрезка
        port.write(b'\x1d\x56\x00')
        time.sleep(0.5)
        
        port.close()
        print('✅ Тест отправлен!')
        print('📸 Сделай фото чека!')
        
    except Exception as e:
        print(f'❌ Ошибка: {e}')

if __name__ == '__main__':
    print_test()
