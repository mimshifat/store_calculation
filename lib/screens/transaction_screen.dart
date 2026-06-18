import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../models/transaction.dart';
import '../providers/customer_provider.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/filter_bar.dart';

class TransactionScreen extends StatefulWidget {
  final Customer customer;

  const TransactionScreen({super.key, required this.customer});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  List<AppTransaction> _transactions = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  FilterMode _filterMode = FilterMode.monthly;
  DateTime? _customStart;
  DateTime? _customEnd;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    final provider = Provider.of<CustomerProvider>(context, listen: false);
    _transactions = await provider.getTransactions(widget.customer.id!);
    setState(() => _isLoading = false);
  }

  String _getMonthName(int month) {
    const months = [
      'জানুয়ারি',
      'ফেব্রুয়ারি',
      'মার্চ',
      'এপ্রিল',
      'মে',
      'জুন',
      'জুলাই',
      'আগস্ট',
      'সেপ্টেম্বর',
      'অক্টোবর',
      'নভেম্বর',
      'ডিসেম্বর'
    ];
    return months[month - 1];
  }

  String _toBengali(String input) {
    const bengaliDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    return input.replaceAllMapped(RegExp(r'[0-9]'), (match) {
      return bengaliDigits[int.parse(match.group(0)!)];
    });
  }

  List<AppTransaction> get _filteredTransactions {
    switch (_filterMode) {
      case FilterMode.monthly:
        return _transactions
            .where((t) =>
                t.date.year == _selectedDate.year &&
                t.date.month == _selectedDate.month)
            .toList();
      case FilterMode.yearly:
        return _transactions
            .where((t) => t.date.year == _selectedDate.year)
            .toList();
      case FilterMode.allTime:
        return List.from(_transactions);
      case FilterMode.custom:
        if (_customStart == null || _customEnd == null) {
          return List.from(_transactions);
        }
        final end = DateTime(
            _customEnd!.year, _customEnd!.month, _customEnd!.day, 23, 59, 59);
        return _transactions
            .where((t) =>
                t.date.isAfter(
                    _customStart!.subtract(const Duration(seconds: 1))) &&
                t.date.isBefore(end.add(const Duration(seconds: 1))))
            .toList();
    }
  }

  String _emptyMessage() {
    switch (_filterMode) {
      case FilterMode.monthly:
        return 'এই মাসে কোনো লেনদেন নেই!';
      case FilterMode.yearly:
        return 'এই বছরে কোনো লেনদেন নেই!';
      case FilterMode.allTime:
        return 'কোনো লেনদেন নেই!';
      case FilterMode.custom:
        return 'এই সীমায় কোনো লেনদেন নেই!';
    }
  }

  void _showAddTransactionDialog(String type) {
    final amountController = TextEditingController();
    final descController = TextEditingController();
    final isSale = type == 'sale';
    DateTime selectedDateTime = DateTime.now();
    String paymentMethod = 'Cash';
    final paymentOptions = ['Cash', 'bKash', 'Nagad', 'Bank', 'Others'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(isSale ? 'বাকি বিক্রি এন্ট্রি' : 'জমা/পেমেন্ট এন্ট্রি'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'পরিমান (৳)',
                      prefixIcon: Icon(
                          isSale
                              ? Icons.remove_circle_outline
                              : Icons.add_circle_outline,
                          color: isSale ? Colors.red : Colors.green),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'বিবরণ (ঐচ্ছিক)',
                      prefixIcon: Icon(Icons.notes),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!isSale) ...[
                    DropdownButtonFormField<String>(
                      initialValue: paymentMethod,
                      decoration: const InputDecoration(
                        labelText: 'পেমেন্ট মেথড',
                        prefixIcon: Icon(Icons.payment),
                        border: OutlineInputBorder(),
                      ),
                      items: paymentOptions.map((method) {
                        return DropdownMenuItem(
                            value: method, child: Text(method));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setStateDialog(() => paymentMethod = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  InkWell(
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDateTime,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        if (!context.mounted) return;
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                        );
                        if (pickedTime != null) {
                          setStateDialog(() {
                            selectedDateTime = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );
                          });
                        }
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'তারিখ ও সময়',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        "${selectedDateTime.day}/${selectedDateTime.month}/${selectedDateTime.year} ${TimeOfDay.fromDateTime(selectedDateTime).format(context)}",
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('বাতিল'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final amount =
                      double.tryParse(amountController.text.trim()) ?? 0.0;
                  if (amount > 0) {
                    final transaction = AppTransaction(
                      customerId: widget.customer.id!,
                      type: type,
                      amount: amount,
                      description: descController.text.trim(),
                      date: selectedDateTime,
                      paymentMethod: isSale ? 'Cash' : paymentMethod,
                    );

                    Navigator.pop(context); // Close dialog

                    setState(() => _isLoading = true);
                    final provider =
                        Provider.of<CustomerProvider>(context, listen: false);
                    await provider.addTransaction(transaction, widget.customer);
                    await _loadTransactions();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isSale ? Colors.red.shade600 : Colors.green.shade600,
                  foregroundColor: Colors.white,
                ),
                child: const Text('সংরক্ষণ'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditTransactionDialog(AppTransaction tx) {
    final amountController =
        TextEditingController(text: tx.amount.toStringAsFixed(0));
    final descController = TextEditingController(text: tx.description);
    final isSale = tx.type == 'sale';
    DateTime selectedDateTime = tx.date;
    String paymentMethod = tx.paymentMethod;
    final paymentOptions = ['Cash', 'bKash', 'Nagad', 'Bank', 'Others'];

    if (!paymentOptions.contains(paymentMethod)) {
      paymentMethod = 'Cash'; // Fallback
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title:
                Text(isSale ? 'বাকি বিক্রি সম্পাদনা' : 'জমা/পেমেন্ট সম্পাদনা'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'পরিমান (৳)',
                      prefixIcon: Icon(
                          isSale
                              ? Icons.remove_circle_outline
                              : Icons.add_circle_outline,
                          color: isSale ? Colors.red : Colors.green),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'বিবরণ (ঐচ্ছিক)',
                      prefixIcon: Icon(Icons.notes),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!isSale) ...[
                    DropdownButtonFormField<String>(
                      initialValue: paymentMethod,
                      decoration: const InputDecoration(
                        labelText: 'পেমেন্ট মেথড',
                        prefixIcon: Icon(Icons.payment),
                        border: OutlineInputBorder(),
                      ),
                      items: paymentOptions.map((method) {
                        return DropdownMenuItem(
                            value: method, child: Text(method));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setStateDialog(() => paymentMethod = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  InkWell(
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDateTime,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        if (!context.mounted) return;
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                        );
                        if (pickedTime != null) {
                          setStateDialog(() {
                            selectedDateTime = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );
                          });
                        }
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'তারিখ ও সময়',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        "${selectedDateTime.day}/${selectedDateTime.month}/${selectedDateTime.year} ${TimeOfDay.fromDateTime(selectedDateTime).format(context)}",
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('বাতিল'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final amount =
                      double.tryParse(amountController.text.trim()) ?? 0.0;
                  if (amount > 0) {
                    final updatedTx = AppTransaction(
                      id: tx.id,
                      customerId: widget.customer.id!,
                      type: tx.type,
                      amount: amount,
                      description: descController.text.trim(),
                      date: selectedDateTime,
                      paymentMethod: isSale ? 'Cash' : paymentMethod,
                    );

                    Navigator.pop(context); // Close dialog

                    setState(() => _isLoading = true);
                    final provider =
                        Provider.of<CustomerProvider>(context, listen: false);
                    await provider.updateTransaction(
                        updatedTx, widget.customer);
                    await _loadTransactions();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isSale ? Colors.red.shade600 : Colors.green.shade600,
                  foregroundColor: Colors.white,
                ),
                child: const Text('আপডেট'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CustomerProvider>(
      builder: (context, provider, child) {
        final currentCustomer = provider.customers.firstWhere(
          (c) => c.id == widget.customer.id,
          orElse: () => widget.customer,
        );

        final filtered = _filteredTransactions;

        // Group by date
        final Map<String, List<AppTransaction>> grouped = {};
        for (var tx in filtered) {
          final dateStr =
              "${tx.date.day} ${_getMonthName(tx.date.month)} ${tx.date.year}";
          if (!grouped.containsKey(dateStr)) {
            grouped[dateStr] = [];
          }
          grouped[dateStr]!.add(tx);
        }
        // Sort date groups newest-first, independent of DB insertion order
        final sortedDates = grouped.keys.toList()
          ..sort((a, b) => grouped[b]!.first.date.compareTo(grouped[a]!.first.date));

        return Scaffold(
          appBar: AppBar(
            title: Text(currentCustomer.name),
            backgroundColor: Colors.green.shade800,
          ),
          body: Column(
            children: [
              // Header Card
              Container(
                width: double.infinity,
                color: Colors.green.shade800,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'মোট বকেয়া',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '৳${_toBengali(currentCustomer.dueAmount.toStringAsFixed(0))}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.account_balance_wallet,
                              color: Colors.white, size: 32),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // ── Filter Bar ──
              FilterBar(
                filterMode: _filterMode,
                selectedDate: _selectedDate,
                customStart: _customStart,
                customEnd: _customEnd,
                onFilterModeChanged: (mode) =>
                    setState(() => _filterMode = mode),
                onPrevious: () => setState(() {
                  if (_filterMode == FilterMode.monthly) {
                    _selectedDate =
                        DateTime(_selectedDate.year, _selectedDate.month - 1);
                  } else if (_filterMode == FilterMode.yearly) {
                    _selectedDate = DateTime(_selectedDate.year - 1);
                  }
                }),
                onNext: () => setState(() {
                  if (_filterMode == FilterMode.monthly) {
                    _selectedDate =
                        DateTime(_selectedDate.year, _selectedDate.month + 1);
                  } else if (_filterMode == FilterMode.yearly) {
                    _selectedDate = DateTime(_selectedDate.year + 1);
                  }
                }),
                onCustomRangeSelected: (start, end) async {
                  setState(() {
                    _customStart = start;
                    _customEnd = end;
                    _filterMode = FilterMode.custom;
                  });
                },
              ),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showAddTransactionDialog('sale'),
                        icon: const Icon(Icons.remove_circle_outline,
                            color: Colors.white),
                        label: const Text('বাকি বিক্রি',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showAddTransactionDialog('payment'),
                        icon: const Icon(Icons.add_circle_outline,
                            color: Colors.white),
                        label: const Text('জমা/পেমেন্ট',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Timeline
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.green))
                    : filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.history,
                                    size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  _emptyMessage(),
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: sortedDates.length,
                            itemBuilder: (context, dateIndex) {
                              final dateStr = sortedDates[dateIndex];
                              final dayTxs = grouped[dateStr]!;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Date Header
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 20, 16, 8),
                                    child: Row(
                                      children: [
                                        Expanded(
                                            child: Divider(
                                                color: Colors.grey.shade300)),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12),
                                          child: Text(
                                            _toBengali(dateStr),
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                            child: Divider(
                                                color: Colors.grey.shade300)),
                                      ],
                                    ),
                                  ),
                                  ...dayTxs.map((tx) => TransactionTile(
                                        transaction: tx,
                                        customerMobile: currentCustomer.mobile,
                                        customerDueAmount: currentCustomer.dueAmount,
                                        onDelete: () async {
                                          await provider.deleteTransaction(
                                              tx, currentCustomer.id!);
                                          await _loadTransactions();
                                        },
                                        onEdit: () =>
                                            _showEditTransactionDialog(tx),
                                      )),
                                ],
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}
