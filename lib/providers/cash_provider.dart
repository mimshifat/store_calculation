import 'package:flutter/foundation.dart';
import '../models/cash_entry.dart';
import '../database/database_helper.dart';
import '../widgets/filter_bar.dart';

class CashProvider with ChangeNotifier {
  List<CashEntry> _entries = [];
  bool _isLoading = false;

  DateTime _selectedDate = DateTime.now();
  FilterMode _filterMode = FilterMode.monthly;
  DateTime? _customStart;
  DateTime? _customEnd;

  List<CashEntry> get allEntries => _entries;
  bool get isLoading => _isLoading;
  DateTime get selectedDate => _selectedDate;
  FilterMode get filterMode => _filterMode;
  DateTime? get customStart => _customStart;
  DateTime? get customEnd => _customEnd;

  List<CashEntry> get filteredEntries {
    switch (_filterMode) {
      case FilterMode.monthly:
        return _entries.where((e) {
          return e.date.year == _selectedDate.year && e.date.month == _selectedDate.month;
        }).toList();
      case FilterMode.yearly:
        return _entries.where((e) => e.date.year == _selectedDate.year).toList();
      case FilterMode.allTime:
        return List.from(_entries);
      case FilterMode.custom:
        if (_customStart == null || _customEnd == null) return List.from(_entries);
        final end = DateTime(_customEnd!.year, _customEnd!.month, _customEnd!.day, 23, 59, 59);
        return _entries.where((e) {
          return e.date.isAfter(_customStart!.subtract(const Duration(seconds: 1))) &&
              e.date.isBefore(end.add(const Duration(seconds: 1)));
        }).toList();
    }
  }

  CashProvider() {
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();
    _entries = await DatabaseHelper.instance.getAllCashEntries();
    _isLoading = false;
    notifyListeners();
  }

  void setFilterMode(FilterMode mode) {
    _filterMode = mode;
    notifyListeners();
  }

  void setCustomRange(DateTime start, DateTime end) {
    _customStart = start;
    _customEnd = end;
    _filterMode = FilterMode.custom;
    notifyListeners();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void previousMonth() {
    _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
    notifyListeners();
  }

  void nextMonth() {
    _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
    notifyListeners();
  }

  void previousYear() {
    _selectedDate = DateTime(_selectedDate.year - 1, _selectedDate.month);
    notifyListeners();
  }

  void nextYear() {
    _selectedDate = DateTime(_selectedDate.year + 1, _selectedDate.month);
    notifyListeners();
  }

  Future<void> addEntry(CashEntry entry) async {
    await DatabaseHelper.instance.insertCashEntry(entry);
    await loadData();
  }

  Future<void> updateEntry(CashEntry entry) async {
    await DatabaseHelper.instance.updateCashEntry(entry);
    await loadData();
  }

  Future<void> deleteEntry(int id) async {
    await DatabaseHelper.instance.deleteCashEntry(id);
    await loadData();
  }

  double get filteredExpense {
    return filteredEntries
        .where((e) => e.type == 'expense')
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  // Helper getters for dashboard (All-time)
  double get totalExpense {
    return _entries
        .where((e) => e.type == 'expense')
        .fold(0.0, (sum, item) => sum + item.amount);
  }
}
