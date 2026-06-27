// lib/services/shift_service.dart

import 'package:pos_app/services/database/database_helper.dart';
import '../models/shift.dart';

class ShiftService {
  final DatabaseHelper _db = DatabaseHelper();

  Future<Shift> getCurrentShift() async {
    return await _db.getCurrentShift();
  }

  Future<void> closeShift(int shiftId) async {
    await _db.closeShift(shiftId);
  }

  Future<Shift> openNewShift() async {
    // Закрываем текущую
    final current = await _db.getCurrentShift();
    if (current.isOpen) {
      await _db.closeShift(current.id!);
    }
    return await _db.getCurrentShift();
  }

  Future<ShiftStats> getShiftStats(int shiftId) async {
    return await _db.getShiftStats(shiftId);
  }

  Future<List<Shift>> getAllShifts({int limit = 50}) async {
    return await _db.getAllShifts(limit: limit);
  }

  Future<int> getReceiptCount({int? shiftId}) async {
    return await _db.getReceiptCount(shiftId: shiftId);
  }
}