// lib/test_simple.dart - МАКСИМАЛЬНО ПРОСТОЙ ТЕСТ
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_libserialport/flutter_libserialport.dart';

void main() async {
  print('🖨️ ПРОСТЕЙШИЙ ТЕСТ');
  print('=' * 50);
  
  try {
    final ports = SerialPort.availablePorts;
    print('📋 Порты: $ports');
    
    String portName = '/dev/cu.usbserial-110';
    if (!ports.contains(portName)) {
      print('❌ Порт не найден');
      return;
    }
    
    print('🔌 Порт: $portName');
    
    final port = SerialPort(portName);
    port.config
      ..baudRate = 19200
      ..bits = 8
      ..stopBits = 1
      ..parity = SerialPortParity.none;
    
    if (!port.openReadWrite()) {
      print('❌ Ошибка открытия порта');
      return;
    }
    
    print('✅ Порт открыт');
    
    // ============================================================
    // ПРОСТО ОТПРАВЛЯЕМ ТЕКСТ
    // ============================================================
    
    // 1. Сброс
    port.write(Uint8List.fromList([0x1B, 0x40]));
    await Future.delayed(Duration(milliseconds: 100));
    
    // 2. CP866
    port.write(Uint8List.fromList([0x1B, 0x52, 0x07]));
    await Future.delayed(Duration(milliseconds: 100));
    
    // 3. Текст (латиница)
    port.write(Uint8List.fromList('HELLO WORLD\n'.codeUnits));
    await Future.delayed(Duration(milliseconds: 100));
    
    // 4. Русские буквы (байты)
    final russian = [
      0x80, 0x81, 0x82, 0x83, 0x84, 0x85, 0xF0, 0x86, 0x87,
      0x88, 0x89, 0x8A, 0x8B, 0x8C, 0x8D, 0x8E, 0x8F,
      0x90, 0x91, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97,
      0x98, 0x99, 0x9A, 0x9B, 0x9C, 0x9D, 0x9E, 0x9F,
      0x0A
    ];
    port.write(Uint8List.fromList(russian));
    await Future.delayed(Duration(milliseconds: 100));
    
    // 5. Обрезка
    port.write(Uint8List.fromList([0x1D, 0x56, 0x00]));
    await Future.delayed(Duration(milliseconds: 500));
    
    port.close();
    
    print('✅ Отправлено!');
    print('📸 Сделай фото чека!');
    
  } catch (e) {
    print('❌ Ошибка: $e');
  }
}
