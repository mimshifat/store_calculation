import 'package:flutter/foundation.dart';
import '../models/bank_account.dart';
import '../models/bank_transaction.dart';
import '../database/database_helper.dart';

class BankProvider with ChangeNotifier {
  List<BankAccount> _accounts = [];
  List<BankTransaction> _transactions = [];
  bool _isLoading = false;
  int? _selectedAccountId;

  List<BankAccount> get accounts => _accounts;
  List<BankTransaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  int? get selectedAccountId => _selectedAccountId;

  BankProvider() {
    loadAccounts();
  }

  double get totalBalance {
    return _accounts.fold(0.0, (sum, acc) => sum + acc.balance);
  }

  Future<void> loadAccounts() async {
    _isLoading = true;
    notifyListeners();
    _accounts = await DatabaseHelper.instance.getAllBankAccounts();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadTransactions(int accountId) async {
    _isLoading = true;
    _selectedAccountId = accountId;
    notifyListeners();
    _transactions = await DatabaseHelper.instance.getTransactionsForAccount(accountId);
    _isLoading = false;
    notifyListeners();
  }

  void clearSelectedAccount() {
    _selectedAccountId = null;
    _transactions = [];
    notifyListeners();
  }

  // --- Bank Account Operations ---

  Future<void> addAccount(BankAccount account) async {
    await DatabaseHelper.instance.insertBankAccount(account);
    await loadAccounts();
  }

  Future<void> updateAccount(BankAccount account) async {
    await DatabaseHelper.instance.updateBankAccount(account);
    await loadAccounts();
  }

  Future<void> deleteAccount(int id) async {
    await DatabaseHelper.instance.deleteBankAccount(id);
    if (_selectedAccountId == id) {
      clearSelectedAccount();
    }
    await loadAccounts();
  }

  // --- Bank Transaction Operations ---

  Future<void> addTransaction(BankTransaction transaction) async {
    await DatabaseHelper.instance.insertBankTransaction(transaction);
    await _recalculateBalance(transaction.accountId);
    if (_selectedAccountId == transaction.accountId) {
      await loadTransactions(transaction.accountId);
    }
  }

  Future<void> updateTransaction(BankTransaction transaction, {int? oldAccountId}) async {
    await DatabaseHelper.instance.updateBankTransaction(transaction);
    await _recalculateBalance(transaction.accountId);
    
    if (oldAccountId != null && oldAccountId != transaction.accountId) {
      await _recalculateBalance(oldAccountId);
    }

    if (_selectedAccountId == transaction.accountId || _selectedAccountId == oldAccountId) {
      await loadTransactions(_selectedAccountId!);
    }
  }

  Future<void> deleteTransaction(int id, int accountId) async {
    await DatabaseHelper.instance.deleteBankTransaction(id);
    await _recalculateBalance(accountId);
    if (_selectedAccountId == accountId) {
      await loadTransactions(accountId);
    }
  }

  // --- Helper ---

  Future<void> _recalculateBalance(int accountId) async {
    final txs = await DatabaseHelper.instance.getTransactionsForAccount(accountId);
    double balance = 0.0;
    
    for (var tx in txs) {
      if (tx.type == 'deposit' || tx.type == 'receive') {
        balance += tx.amount;
      } else if (tx.type == 'cash_out' || tx.type == 'payment') {
        balance -= tx.amount;
      }
    }

    await DatabaseHelper.instance.updateBankAccountBalance(accountId, balance);
    await loadAccounts(); // Refresh account list with new balance
  }
}
