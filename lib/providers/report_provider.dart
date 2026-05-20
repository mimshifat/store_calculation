import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';

class ReportProvider with ChangeNotifier {
  bool _isLoading = false;

  double totalCollection = 0;
  double totalSales = 0;
  double totalPurchases = 0;
  double totalSupplierPayments = 0;
  double totalCashExpense = 0;

  bool get isLoading => _isLoading;

  Future<void> loadReport(DateTime startDate, DateTime endDate) async {
    _isLoading = true;
    notifyListeners();

    // Reset values
    totalCollection = 0;
    totalSales = 0;
    totalPurchases = 0;
    totalSupplierPayments = 0;
    totalCashExpense = 0;

    final db = await DatabaseHelper.instance.database;
    final startIso = startDate.toIso8601String();
    final endIso = endDate.toIso8601String();

    // 1. Customer Transactions (Sales and Collections)
    final custTxs = await db.query(
      'transactions',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startIso, endIso],
    );

    for (var tx in custTxs) {
      final amount = (tx['amount'] as num).toDouble();
      if (tx['type'] == 'payment') {
        totalCollection += amount;
      } else if (tx['type'] == 'sale') {
        totalSales += amount;
      }
    }

    // 2. Supplier Transactions (Purchases and Payments)
    final suppTxs = await db.query(
      'supplier_transactions',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startIso, endIso],
    );

    for (var tx in suppTxs) {
      final amount = (tx['amount'] as num).toDouble();
      if (tx['type'] == 'purchase') {
        totalPurchases += amount;
      } else if (tx['type'] == 'payment') {
        totalSupplierPayments += amount;
      }
    }

    // 3. Cashbook Entries (Income and Expenses)
    final cashTxs = await db.query(
      'cash_entries',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startIso, endIso],
    );

    for (var tx in cashTxs) {
      final amount = (tx['amount'] as num).toDouble();
      if (tx['type'] == 'expense') {
        totalCashExpense += amount;
      }
    }

    _isLoading = false;
    notifyListeners();
  }
}
