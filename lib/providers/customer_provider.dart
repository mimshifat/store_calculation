import 'package:flutter/foundation.dart';
import '../models/customer.dart';
import '../models/khata.dart';
import '../models/transaction.dart';
import '../database/database_helper.dart';

enum CustomerSortMode { defaultOrder, oldestDueFirst, highestDueFirst }

class CustomerProvider with ChangeNotifier {
  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  List<Khata> _khatas = [];
  Map<int, DateTime> _oldestSaleDates = {};

  String _searchQuery = '';
  String _selectedKhataFilter = 'সব';
  CustomerSortMode _sortMode = CustomerSortMode.defaultOrder;

  bool _isLoading = false;

  List<Customer> get customers => _filteredCustomers;
  List<Customer> get allCustomers => _customers; // Unfiltered — for export
  List<Khata> get khatas => _khatas;
  bool get isLoading => _isLoading;
  String get selectedKhataFilter => _selectedKhataFilter;
  CustomerSortMode get sortMode => _sortMode;

  /// Always returns the total due from ALL customers regardless of active filter.
  double get totalDueAllCustomers =>
      _customers.fold(0.0, (sum, c) => sum + c.dueAmount);

  /// Map of customerId → oldest sale date (for due aging display).
  Map<int, DateTime> get oldestSaleDates => _oldestSaleDates;

  CustomerProvider() {
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    _khatas = await DatabaseHelper.instance.getAllKhatas();
    _customers = await DatabaseHelper.instance.getAllCustomers();
    _oldestSaleDates = await DatabaseHelper.instance.getOldestSaleDatePerCustomer();

    _applyFilters();

    _isLoading = false;
    notifyListeners();
  }

  // --- Khata Actions ---

  Future<void> addKhata(String name) async {
    final newKhata = Khata(name: name);
    await DatabaseHelper.instance.insertKhata(newKhata);
    await loadData();
  }

  Future<void> updateKhata(Khata khata, String oldName) async {
    await DatabaseHelper.instance.updateKhata(khata);
    await DatabaseHelper.instance.updateCustomerKhataName(oldName, khata.name);
    
    if (_selectedKhataFilter == oldName) {
      _selectedKhataFilter = khata.name;
    }
    
    await loadData();
  }

  Future<void> deleteKhata(int id) async {
    await DatabaseHelper.instance.deleteKhata(id);
    await loadData();
  }

  // --- Customer Actions ---

  Future<void> addCustomer(Customer customer) async {
    await DatabaseHelper.instance.insertCustomer(customer);
    await loadData();
  }

  Future<void> updateCustomer(Customer customer) async {
    await DatabaseHelper.instance.updateCustomer(customer);
    await loadData();
  }

  Future<void> deleteCustomer(int id) async {
    await DatabaseHelper.instance.deleteCustomer(id);
    await loadData();
  }

  Future<void> updateDueAmount(int customerId, double amount) async {
    await DatabaseHelper.instance.updateDueAmount(customerId, amount);
    await loadData();
  }
  
  Future<void> importCustomers(List<Customer> newCustomers) async {
    await DatabaseHelper.instance.insertCustomersBatch(newCustomers);
    await loadData();
  }

  // --- Transaction Actions ---

  Future<List<AppTransaction>> getTransactions(int customerId) async {
    return await DatabaseHelper.instance.getTransactionsForCustomer(customerId);
  }

  Future<void> addTransaction(AppTransaction transaction, Customer customer) async {
    // Insert the transaction
    await DatabaseHelper.instance.insertTransaction(transaction);

    // Fetch the LATEST customer data from DB to avoid stale dueAmount
    final allCustomers = await DatabaseHelper.instance.getAllCustomers();
    final latestCustomer = allCustomers.firstWhere((c) => c.id == customer.id);

    // Update the customer's due amount based on transaction type
    double newDue = latestCustomer.dueAmount;
    if (transaction.type == 'sale') {
      newDue += transaction.amount;
    } else if (transaction.type == 'payment') {
      newDue -= transaction.amount;
    }

    // Update due amount in DB
    await DatabaseHelper.instance.updateDueAmount(customer.id!, newDue);
    
    // Refresh list
    await loadData();
  }

  Future<void> deleteTransaction(AppTransaction tx, int customerId) async {
    // Fetch latest customer
    final allCustomers = await DatabaseHelper.instance.getAllCustomers();
    final latestCustomer = allCustomers.firstWhere((c) => c.id == customerId);

    // Reverse the transaction's effect on the current dueAmount
    double newDue = latestCustomer.dueAmount;
    if (tx.type == 'sale') {
      newDue -= tx.amount;
    } else if (tx.type == 'payment') {
      newDue += tx.amount;
    }

    // Delete and update
    await DatabaseHelper.instance.deleteTransaction(tx.id!);
    await DatabaseHelper.instance.updateDueAmount(customerId, newDue);
    await loadData();
  }

  Future<void> updateTransaction(AppTransaction updatedTx, Customer customer) async {
    // We need the OLD transaction to reverse its effect.
    final allTxs = await DatabaseHelper.instance.getTransactionsForCustomer(customer.id!);
    final oldTx = allTxs.firstWhere((t) => t.id == updatedTx.id);

    // Fetch latest customer
    final allCustomers = await DatabaseHelper.instance.getAllCustomers();
    final latestCustomer = allCustomers.firstWhere((c) => c.id == customer.id);

    // Reverse oldTx, apply updatedTx
    double newDue = latestCustomer.dueAmount;
    if (oldTx.type == 'sale') {
      newDue -= oldTx.amount;
    } else if (oldTx.type == 'payment') {
      newDue += oldTx.amount;
    }
    
    if (updatedTx.type == 'sale') {
      newDue += updatedTx.amount;
    } else if (updatedTx.type == 'payment') {
      newDue -= updatedTx.amount;
    }

    // Update DB
    await DatabaseHelper.instance.updateTransaction(updatedTx);
    await DatabaseHelper.instance.updateDueAmount(customer.id!, newDue);
    await loadData();
  }

  // --- Filtering & Searching ---

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
    notifyListeners();
  }

  void setKhataFilter(String khataName) {
    _selectedKhataFilter = khataName;
    _applyFilters();
    notifyListeners();
  }

  void setSortMode(CustomerSortMode mode) {
    _sortMode = mode;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    // 1. Filter
    var temp = _customers.where((customer) {
      final matchesSearch = customer.name.toLowerCase().contains(_searchQuery) ||
          customer.mobile.contains(_searchQuery) ||
          customer.pageNo.toLowerCase().contains(_searchQuery);
          
      final matchesKhata = _selectedKhataFilter == 'সব' || 
          customer.khataNo == _selectedKhataFilter;
          
      return matchesSearch && matchesKhata;
    }).toList();

    // 2. Sort
    if (_sortMode == CustomerSortMode.oldestDueFirst) {
      temp.sort((a, b) {
        // customers with no due go to bottom
        if (a.dueAmount <= 0 && b.dueAmount <= 0) return 0;
        if (a.dueAmount <= 0) return 1;
        if (b.dueAmount <= 0) return -1;
        
        final dateA = _oldestSaleDates[a.id];
        final dateB = _oldestSaleDates[b.id];
        
        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        
        return dateA.compareTo(dateB); // older dates first
      });
    } else if (_sortMode == CustomerSortMode.highestDueFirst) {
      temp.sort((a, b) {
        if (a.dueAmount <= 0 && b.dueAmount <= 0) return 0;
        if (a.dueAmount <= 0) return 1;
        if (b.dueAmount <= 0) return -1;
        
        return b.dueAmount.compareTo(a.dueAmount); // highest first
      });
    }
    // if defaultOrder, it's already sorted by id DESC from DB.

    _filteredCustomers = temp;
  }
}
