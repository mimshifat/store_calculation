import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cash_entry.dart';
import '../providers/cash_provider.dart';
import 'package:intl/intl.dart';
import '../utils/app_utils.dart';
import '../widgets/filter_bar.dart';

class CashBookScreen extends StatefulWidget {
  const CashBookScreen({super.key});

  @override
  State<CashBookScreen> createState() => _CashBookScreenState();
}

class _CashBookScreenState extends State<CashBookScreen> {

  // ── Add Dialog ──────────────────────────────────────────────────
  void _showAddEntryDialog(BuildContext context) {
    final amountController = TextEditingController();
    final categoryController = TextEditingController();
    final descController = TextEditingController();
    
    // New fields for rent
    final shopNameController = TextEditingController();
    final ownerNameController = TextEditingController();
    final receiptController = TextEditingController();
    final paidViaController = TextEditingController();
    
    DateTime selectedDateTime = DateTime.now();
    String paymentMethod = 'Cash';
    final paymentOptions = ['Cash', 'bKash', 'Nagad', 'Bank', 'Others'];
    
    String selectedCategory = 'অন্যান্য';
    final categoryOptions = ['দোকান ভাড়া', 'কেনাকাটা', 'বিদ্যুৎ', 'পরিবহন', 'অন্যান্য'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          return AlertDialog(
            title: const Text('নতুন খরচ'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'পরিমান (৳)',
                      prefixIcon: Icon(Icons.remove_circle, color: Colors.red),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'ক্যাটাগরি নির্বাচন করুন',
                      prefixIcon: Icon(Icons.category),
                      border: OutlineInputBorder(),
                    ),
                    items: categoryOptions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setStateDialog(() {
                          selectedCategory = val;
                          if (val != 'অন্যান্য') {
                            categoryController.text = val;
                          } else {
                            categoryController.clear();
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  if (selectedCategory == 'অন্যান্য')
                    TextField(
                      controller: categoryController,
                      decoration: const InputDecoration(
                        labelText: 'ক্যাটাগরির নাম লিখুন',
                        prefixIcon: Icon(Icons.edit),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  if (selectedCategory == 'অন্যান্য') const SizedBox(height: 12),
                  
                  if (selectedCategory == 'দোকান ভাড়া') ...[
                    TextField(
                      controller: shopNameController,
                      decoration: const InputDecoration(
                        labelText: 'দোকানের নাম',
                        prefixIcon: Icon(Icons.store),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: ownerNameController,
                      decoration: const InputDecoration(
                        labelText: 'মালিকের নাম',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: receiptController,
                      decoration: const InputDecoration(
                        labelText: 'রশিদ/ট্রান্জেকশন নাম্বার (ঐচ্ছিক)',
                        prefixIcon: Icon(Icons.receipt),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: paidViaController,
                      decoration: const InputDecoration(
                        labelText: 'মাধ্যম (কার হাতে দিয়েছেন)',
                        prefixIcon: Icon(Icons.handshake),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
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
                  DropdownButtonFormField<String>(
                    initialValue: paymentMethod,
                    decoration: const InputDecoration(
                      labelText: 'পেমেন্ট মেথড',
                      prefixIcon: Icon(Icons.payment),
                      border: OutlineInputBorder(),
                    ),
                    items: paymentOptions.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (val) {
                      if (val != null) setStateDialog(() => paymentMethod = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  _dateTimePicker(ctx, () => selectedDateTime, (dt) => setStateDialog(() => selectedDateTime = dt)),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
              ElevatedButton(
                onPressed: () {
                  final amount = double.tryParse(amountController.text.trim()) ?? 0.0;
                  if (amount > 0 && categoryController.text.isNotEmpty) {
                    final entry = CashEntry(
                      type: 'expense',
                      category: categoryController.text.trim(),
                      amount: amount,
                      description: descController.text.trim(),
                      date: selectedDateTime,
                      paymentMethod: paymentMethod,
                      shopName: selectedCategory == 'দোকান ভাড়া' ? shopNameController.text.trim() : null,
                      ownerName: selectedCategory == 'দোকান ভাড়া' ? ownerNameController.text.trim() : null,
                      receiptNumber: selectedCategory == 'দোকান ভাড়া' ? receiptController.text.trim() : null,
                      paidVia: selectedCategory == 'দোকান ভাড়া' ? paidViaController.text.trim() : null,
                    );
                    Provider.of<CashProvider>(context, listen: false).addEntry(entry);
                    Navigator.pop(ctx);
                  } else {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('সঠিক পরিমান ও ক্যাটাগরি দিন')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
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

  // ── Edit Dialog ─────────────────────────────────────────────────
  void _showEditEntryDialog(BuildContext context, CashEntry entry, CashProvider provider) {
    final amountController = TextEditingController(text: entry.amount.toStringAsFixed(0));
    final categoryController = TextEditingController(text: entry.category);
    final descController = TextEditingController(text: entry.description);
    
    final shopNameController = TextEditingController(text: entry.shopName ?? '');
    final ownerNameController = TextEditingController(text: entry.ownerName ?? '');
    final receiptController = TextEditingController(text: entry.receiptNumber ?? '');
    final paidViaController = TextEditingController(text: entry.paidVia ?? '');

    DateTime selectedDateTime = entry.date;
    final paymentOptions = ['Cash', 'bKash', 'Nagad', 'Bank', 'Others'];
    String paymentMethod = paymentOptions.contains(entry.paymentMethod) ? entry.paymentMethod : 'Cash';
    
    final categoryOptions = ['দোকান ভাড়া', 'কেনাকাটা', 'বিদ্যুৎ', 'পরিবহন', 'অন্যান্য'];
    String selectedCategory = categoryOptions.contains(entry.category) ? entry.category : 'অন্যান্য';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          return AlertDialog(
            title: const Text('খরচ সম্পাদনা'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'পরিমান (৳)',
                      prefixIcon: Icon(Icons.remove_circle, color: Colors.red),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'ক্যাটাগরি নির্বাচন করুন',
                      prefixIcon: Icon(Icons.category),
                      border: OutlineInputBorder(),
                    ),
                    items: categoryOptions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setStateDialog(() {
                          selectedCategory = val;
                          if (val != 'অন্যান্য') {
                            categoryController.text = val;
                          } else {
                            categoryController.clear();
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  if (selectedCategory == 'অন্যান্য')
                    TextField(
                      controller: categoryController,
                      decoration: const InputDecoration(
                        labelText: 'ক্যাটাগরির নাম লিখুন',
                        prefixIcon: Icon(Icons.edit),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  if (selectedCategory == 'অন্যান্য') const SizedBox(height: 12),

                  if (selectedCategory == 'দোকান ভাড়া') ...[
                    TextField(
                      controller: shopNameController,
                      decoration: const InputDecoration(
                        labelText: 'দোকানের নাম',
                        prefixIcon: Icon(Icons.store),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: ownerNameController,
                      decoration: const InputDecoration(
                        labelText: 'মালিকের নাম',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: receiptController,
                      decoration: const InputDecoration(
                        labelText: 'রশিদ/ট্রান্জেকশন নাম্বার (ঐচ্ছিক)',
                        prefixIcon: Icon(Icons.receipt),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: paidViaController,
                      decoration: const InputDecoration(
                        labelText: 'মাধ্যম (কার হাতে দিয়েছেন)',
                        prefixIcon: Icon(Icons.handshake),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
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
                  DropdownButtonFormField<String>(
                    initialValue: paymentMethod,
                    decoration: const InputDecoration(
                      labelText: 'পেমেন্ট মেথড',
                      prefixIcon: Icon(Icons.payment),
                      border: OutlineInputBorder(),
                    ),
                    items: paymentOptions.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (val) {
                      if (val != null) setStateDialog(() => paymentMethod = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  _dateTimePicker(ctx, () => selectedDateTime, (dt) => setStateDialog(() => selectedDateTime = dt)),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
              ElevatedButton(
                onPressed: () {
                  final amount = double.tryParse(amountController.text.trim()) ?? 0.0;
                  if (amount > 0 && categoryController.text.isNotEmpty) {
                    final updatedEntry = CashEntry(
                      id: entry.id,
                      type: entry.type,
                      category: categoryController.text.trim(),
                      amount: amount,
                      description: descController.text.trim(),
                      date: selectedDateTime,
                      paymentMethod: paymentMethod,
                      shopName: selectedCategory == 'দোকান ভাড়া' ? shopNameController.text.trim() : null,
                      ownerName: selectedCategory == 'দোকান ভাড়া' ? ownerNameController.text.trim() : null,
                      receiptNumber: selectedCategory == 'দোকান ভাড়া' ? receiptController.text.trim() : null,
                      paidVia: selectedCategory == 'দোকান ভাড়া' ? paidViaController.text.trim() : null,
                    );
                    provider.updateEntry(updatedEntry);
                    Navigator.pop(ctx);
                  } else {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('সঠিক পরিমান ও ক্যাটাগরি দিন')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
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

  // ── Date/Time Picker helper ──────────────────────────────────────
  Widget _dateTimePicker(BuildContext context, DateTime Function() getCurrent, ValueChanged<DateTime> onChanged) {
    return StatefulBuilder(
      builder: (ctx, setState) {
        final current = getCurrent();
        return InkWell(
          onTap: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: current,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (pickedDate != null) {
              if (!context.mounted) return;
              final pickedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(current),
              );
              if (pickedTime != null) {
                final newDt = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
                onChanged(newDt);
                setState(() {});
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
              '${current.day}/${current.month}/${current.year} ${TimeOfDay.fromDateTime(current).format(context)}',
            ),
          ),
        );
      },
    );
  }



  String _cashEmptyMessage(FilterMode mode) {
    switch (mode) {
      case FilterMode.monthly: return 'এই মাসে কোনো খরচ নেই!';
      case FilterMode.yearly: return 'এই বছরে কোনো খরচ নেই!';
      case FilterMode.allTime: return 'কোনো খরচ নেই!';
      case FilterMode.custom: return 'এই সীমায় কোনো খরচ নেই!';
    }
  }

  // ── Build ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('খরচ বই'),
        backgroundColor: Colors.green.shade800,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => Provider.of<CashProvider>(context, listen: false).loadData(),
          ),
        ],
      ),
      body: Consumer<CashProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }

          final entries = provider.filteredEntries;

          // Group entries by date
          final Map<String, List<CashEntry>> groupedEntries = {};
          for (var entry in entries) {
            final dateStr = '${entry.date.day} ${AppUtils.getMonthName(entry.date.month)} ${entry.date.year}';
            groupedEntries.putIfAbsent(dateStr, () => []).add(entry);
          }
          final sortedDates = groupedEntries.keys.toList()
            ..sort((a, b) => groupedEntries[b]!.first.date.compareTo(groupedEntries[a]!.first.date));

          return Column(
            children: [
              // ── Filter Bar ──
              FilterBar(
                filterMode: provider.filterMode,
                selectedDate: provider.selectedDate,
                customStart: provider.customStart,
                customEnd: provider.customEnd,
                onFilterModeChanged: (mode) => provider.setFilterMode(mode),
                onPrevious: () {
                  if (provider.filterMode == FilterMode.monthly) {
                    provider.previousMonth();
                  } else if (provider.filterMode == FilterMode.yearly) {
                    provider.previousYear();
                  }
                },
                onNext: () {
                  if (provider.filterMode == FilterMode.monthly) {
                    provider.nextMonth();
                  } else if (provider.filterMode == FilterMode.yearly) {
                    provider.nextYear();
                  }
                },
                onCustomRangeSelected: (start, end) async {
                  provider.setCustomRange(start, end);
                },
              ),

              // ── Expense Summary ──
              Container(
                color: Colors.green.shade800,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Row(
                  children: [
                    _buildSummaryCard(context, 'মোট খরচ', provider.filteredExpense,
                        Colors.red.shade50, Colors.red.shade700, Icons.trending_down),
                  ],
                ),
              ),

              // ── List Area ──
              Expanded(
                child: entries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_note, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              _cashEmptyMessage(provider.filterMode),
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 100),
                        itemCount: sortedDates.length,
                        itemBuilder: (context, dateIndex) {
                          final dateStr = sortedDates[dateIndex];
                          final dayEntries = groupedEntries[dateStr]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Date Header
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                child: Row(
                                  children: [
                                    Expanded(child: Divider(color: Colors.grey.shade300)),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Text(
                                        AppUtils.toBengali(dateStr),
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Expanded(child: Divider(color: Colors.grey.shade300)),
                                  ],
                                ),
                              ),
                              // Day Entries
                              ...dayEntries.map((entry) => _buildEntryTile(context, entry, provider)),
                            ],
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'expenseBtn',
        onPressed: () => _showAddEntryDialog(context),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('খরচ যোগ করুন'),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, double amount,
      Color bgColor, Color textColor, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(
                '৳${AppUtils.toBengali(amount.toStringAsFixed(0))}',
                style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryTile(BuildContext context, CashEntry entry, CashProvider provider) {
    final theme = Theme.of(context);

    return Dismissible(
      key: Key('ce_${entry.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('নিশ্চিত করুন'),
            content: const Text('এই এন্ট্রি মুছে ফেলতে চান?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('না')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('হ্যাঁ')),
            ],
          ),
        );
        if (confirm == true) {
          await provider.deleteEntry(entry.id!);
        }
        return false;
      },
      onDismissed: (direction) {},
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.remove,
            color: Colors.red.shade700,
            size: 20,
          ),
        ),
        title: Text(entry.category, style: theme.textTheme.titleMedium?.copyWith(fontSize: 15)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              '${AppUtils.toBengali(DateFormat('hh:mm a').format(entry.date))} • ${entry.paymentMethod}',
              style: theme.textTheme.bodySmall,
            ),
            if (entry.isRentEntry) ...[
              const SizedBox(height: 4),
              Text(
                'দোকান: ${entry.shopName ?? 'N/A'}${entry.ownerName?.isNotEmpty == true ? ' • মালিক: ${entry.ownerName}' : ''}',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.black87),
              ),
              if (entry.receiptNumber?.isNotEmpty == true || entry.paidVia?.isNotEmpty == true)
                Text(
                  '${entry.receiptNumber?.isNotEmpty == true ? 'রশিদ: ${entry.receiptNumber}' : ''}${entry.receiptNumber?.isNotEmpty == true && entry.paidVia?.isNotEmpty == true ? ' • ' : ''}${entry.paidVia?.isNotEmpty == true ? 'মাধ্যম: ${entry.paidVia}' : ''}',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.black87),
                ),
            ],
            if (entry.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(entry.description, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black87)),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '- ৳${AppUtils.toBengali(entry.amount.toStringAsFixed(0))}',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blueGrey),
              onPressed: () => _showEditEntryDialog(context, entry, provider),
            ),
          ],
        ),
      ),
    );
  }
}
