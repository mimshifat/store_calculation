import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/supplier.dart';
import '../models/supplier_transaction.dart';
import '../providers/supplier_provider.dart';
import 'package:intl/intl.dart';
import '../widgets/filter_bar.dart';

class SupplierTransactionScreen extends StatefulWidget {
  final Supplier supplier;

  const SupplierTransactionScreen({super.key, required this.supplier});

  @override
  State<SupplierTransactionScreen> createState() =>
      _SupplierTransactionScreenState();
}

class _SupplierTransactionScreenState extends State<SupplierTransactionScreen> {
  List<SupplierTransaction> _transactions = [];
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
    final provider = Provider.of<SupplierProvider>(context, listen: false);
    _transactions = await provider.getTransactions(widget.supplier.id!);
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

  List<SupplierTransaction> get _filteredTransactions {
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
    final isPurchase = type == 'purchase';
    DateTime selectedDateTime = DateTime.now();
    String paymentMethod = 'Cash';
    final paymentOptions = ['Cash', 'bKash', 'Nagad', 'Bank', 'Others'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(isPurchase
                ? 'বাকি কেনা এন্ট্রি'
                : 'পেমেন্ট এন্ট্রি (টাকা দেওয়া)'),
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
                          isPurchase ? Icons.add_shopping_cart : Icons.payment,
                          color: isPurchase ? Colors.orange : Colors.green),
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
                  if (!isPurchase) ...[
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
                    final transaction = SupplierTransaction(
                      supplierId: widget.supplier.id!,
                      type: type,
                      amount: amount,
                      description: descController.text.trim(),
                      date: selectedDateTime,
                      paymentMethod: isPurchase ? 'Cash' : paymentMethod,
                    );

                    Navigator.pop(context); // Close dialog

                    setState(() => _isLoading = true);
                    final provider =
                        Provider.of<SupplierProvider>(context, listen: false);
                    await provider.addTransaction(transaction, widget.supplier);
                    await _loadTransactions();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPurchase
                      ? Colors.orange.shade600
                      : Colors.green.shade600,
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

  void _showEditTransactionDialog(SupplierTransaction tx) {
    final amountController =
        TextEditingController(text: tx.amount.toStringAsFixed(0));
    final descController = TextEditingController(text: tx.description);
    final isPurchase = tx.type == 'purchase';
    DateTime selectedDateTime = tx.date;
    String paymentMethod = tx.paymentMethod;
    final paymentOptions = ['Cash', 'bKash', 'Nagad', 'Bank', 'Others'];
    if (!paymentOptions.contains(paymentMethod)) paymentMethod = 'Cash';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(isPurchase ? 'বাকি কেনা সম্পাদনা' : 'পেমেন্ট সম্পাদনা'),
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
                        isPurchase ? Icons.add_shopping_cart : Icons.payment,
                        color: isPurchase ? Colors.orange : Colors.green,
                      ),
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
                  if (!isPurchase) ...[
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
                        labelText: 'তারিখ ও সময়',
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
                    final updatedTx = SupplierTransaction(
                      id: tx.id,
                      supplierId: widget.supplier.id!,
                      type: tx.type,
                      amount: amount,
                      description: descController.text.trim(),
                      date: selectedDateTime,
                      paymentMethod: isPurchase ? 'Cash' : paymentMethod,
                    );
                    Navigator.pop(context);
                    setState(() => _isLoading = true);
                    final provider =
                        Provider.of<SupplierProvider>(context, listen: false);
                    await provider.updateTransaction(
                        updatedTx, widget.supplier);
                    await _loadTransactions();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPurchase
                      ? Colors.orange.shade600
                      : Colors.green.shade600,
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
    return Consumer<SupplierProvider>(
      builder: (context, provider, child) {
        final currentSupplier = provider.suppliers.firstWhere(
          (s) => s.id == widget.supplier.id,
          orElse: () => widget.supplier,
        );

        final filtered = _filteredTransactions;

        // Group by date
        final Map<String, List<SupplierTransaction>> grouped = {};
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
            title: Text(currentSupplier.name),
            backgroundColor: Colors.green.shade800,
          ),
          body: Column(
            children: [
              // Header Card
              Container(
                width: double.infinity,
                color: Colors.green.shade800,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'আমাদের মোট দেনা',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '৳${_toBengali(currentSupplier.dueAmount.toStringAsFixed(0))}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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
                        onPressed: () => _showAddTransactionDialog('purchase'),
                        icon: const Icon(Icons.shopping_cart,
                            color: Colors.white),
                        label: const Text('বাকি কেনা',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade600,
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
                        icon: const Icon(Icons.payment, color: Colors.white),
                        label: const Text('পেমেন্ট দিলাম',
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
                        child: CircularProgressIndicator(color: Colors.orange))
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
                                  ...dayTxs.map((tx) {
                                    final isPurchase = tx.type == 'purchase';
                                    final color = isPurchase
                                        ? Colors.orange.shade600
                                        : Colors.green.shade600;
                                    final icon = isPurchase
                                        ? Icons.arrow_downward
                                        : Icons.arrow_upward;
                                    final typeText = isPurchase
                                        ? 'বাকি কেনা'
                                        : 'পেমেন্ট দেওয়া';
                                    final theme = Theme.of(context);

                                    return Dismissible(
                                      key: Key('stx_${tx.id}'),
                                      direction: DismissDirection.endToStart,
                                      background: Container(
                                        color: Colors.red,
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20),
                                        child: const Icon(Icons.delete,
                                            color: Colors.white),
                                      ),
                                      confirmDismiss: (direction) async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('নিশ্চিত করুন'),
                                            content: const Text(
                                                'এই লেনদেন মুছে ফেলতে চান?'),
                                            actions: [
                                              TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx, false),
                                                  child: const Text('না')),
                                              TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx, true),
                                                  child: const Text('হ্যাঁ')),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          await provider.deleteTransaction(
                                              tx, currentSupplier.id!);
                                          await _loadTransactions();
                                        }
                                        return false;
                                      },
                                      onDismissed: (direction) {},
                                      child: ListTile(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 4),
                                        leading: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(icon,
                                              color: color, size: 20),
                                        ),
                                        title: Text(typeText,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(fontSize: 15)),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 2),
                                            Text(
                                              '${_toBengali(DateFormat('hh:mm a').format(tx.date))} • ${tx.paymentMethod}',
                                              style: theme.textTheme.bodySmall,
                                            ),
                                            if (tx.description.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(tx.description,
                                                  style: theme
                                                      .textTheme.bodyMedium
                                                      ?.copyWith(
                                                          color:
                                                              Colors.black87)),
                                            ],
                                          ],
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '৳${_toBengali(tx.amount.toStringAsFixed(0))}',
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                      color: color,
                                                      fontWeight:
                                                          FontWeight.bold),
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.edit_outlined,
                                                  size: 20,
                                                  color: Colors.blueGrey),
                                              onPressed: () =>
                                                  _showEditTransactionDialog(
                                                      tx),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
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
