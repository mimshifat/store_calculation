import 'package:flutter/foundation.dart';
import '../models/supplier.dart';
import '../models/supplier_transaction.dart';
import '../database/database_helper.dart';

class SupplierProvider with ChangeNotifier {
  List<Supplier> _suppliers = [];
  List<Supplier> _filteredSuppliers = [];
  Map<int, DateTime> _oldestPurchaseDates = {};

  bool _isLoading = false;
  String _searchQuery = '';

  List<Supplier> get suppliers => _filteredSuppliers;
  bool get isLoading => _isLoading;
  Map<int, DateTime> get oldestPurchaseDates => _oldestPurchaseDates;

  /// Always returns the total due from ALL suppliers regardless of active filter.
  double get totalDueAllSuppliers =>
      _suppliers.fold(0.0, (sum, s) => sum + s.dueAmount);

  SupplierProvider() {
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    _suppliers = await DatabaseHelper.instance.getAllSuppliers();
    _oldestPurchaseDates = await DatabaseHelper.instance.getOldestPurchaseDatePerSupplier();
    _applyFilter();

    _isLoading = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilter();
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredSuppliers = List.from(_suppliers);
    } else {
      final q = _searchQuery.toLowerCase();
      _filteredSuppliers = _suppliers.where((s) {
        return s.name.toLowerCase().contains(q) ||
               s.companyName.toLowerCase().contains(q) ||
               s.mobile.contains(q);
      }).toList();
    }
    notifyListeners();
  }

  Future<void> addSupplier(Supplier supplier) async {
    await DatabaseHelper.instance.insertSupplier(supplier);
    await loadData();
  }

  Future<void> updateSupplier(Supplier supplier) async {
    await DatabaseHelper.instance.updateSupplier(supplier);
    await loadData();
  }

  Future<void> deleteSupplier(int id) async {
    await DatabaseHelper.instance.deleteSupplier(id);
    await loadData();
  }

  // --- Transaction Logic ---

  Future<List<SupplierTransaction>> getTransactions(int supplierId) async {
    return await DatabaseHelper.instance.getTransactionsForSupplier(supplierId);
  }

  Future<void> addTransaction(SupplierTransaction transaction, Supplier supplier) async {
    // Insert the transaction
    await DatabaseHelper.instance.insertSupplierTransaction(transaction);

    // Fetch the LATEST supplier data from DB to avoid stale dueAmount
    final allSuppliers = await DatabaseHelper.instance.getAllSuppliers();
    final latestSupplier = allSuppliers.firstWhere((s) => s.id == supplier.id);

    // Update the supplier's due amount
    // For suppliers: 'purchase' means our debt INCREASES. 'payment' means our debt DECREASES.
    double newDue = latestSupplier.dueAmount;
    if (transaction.type == 'purchase') {
      newDue += transaction.amount;
    } else if (transaction.type == 'payment') {
      newDue -= transaction.amount;
    }

    // Update due amount in DB
    await DatabaseHelper.instance.updateSupplierDueAmount(supplier.id!, newDue);
    
    // Refresh list
    await loadData();
  }

  Future<void> deleteTransaction(SupplierTransaction tx, int supplierId) async {
    // Fetch latest supplier
    final allSuppliers = await DatabaseHelper.instance.getAllSuppliers();
    final latestSupplier = allSuppliers.firstWhere((s) => s.id == supplierId);

    // Reverse the transaction's effect on the current dueAmount
    double newDue = latestSupplier.dueAmount;
    if (tx.type == 'purchase') {
      newDue -= tx.amount;
    } else if (tx.type == 'payment') {
      newDue += tx.amount;
    }

    // Delete and update
    await DatabaseHelper.instance.deleteSupplierTransaction(tx.id!);
    await DatabaseHelper.instance.updateSupplierDueAmount(supplierId, newDue);
    await loadData();
  }

  Future<void> updateTransaction(SupplierTransaction updatedTx, Supplier supplier) async {
    // We need the OLD transaction to reverse its effect.
    final allTxs = await DatabaseHelper.instance.getTransactionsForSupplier(supplier.id!);
    final oldTx = allTxs.firstWhere((t) => t.id == updatedTx.id);

    // Fetch latest supplier
    final allSuppliers = await DatabaseHelper.instance.getAllSuppliers();
    final latestSupplier = allSuppliers.firstWhere((s) => s.id == supplier.id);

    // Reverse oldTx, apply updatedTx
    double newDue = latestSupplier.dueAmount;
    if (oldTx.type == 'purchase') {
      newDue -= oldTx.amount;
    } else if (oldTx.type == 'payment') {
      newDue += oldTx.amount;
    }
    
    if (updatedTx.type == 'purchase') {
      newDue += updatedTx.amount;
    } else if (updatedTx.type == 'payment') {
      newDue -= updatedTx.amount;
    }

    // Update DB
    await DatabaseHelper.instance.updateSupplierTransaction(updatedTx);
    await DatabaseHelper.instance.updateSupplierDueAmount(supplier.id!, newDue);
    await loadData();
  }
}
