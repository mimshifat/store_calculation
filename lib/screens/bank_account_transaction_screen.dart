import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/bank_account.dart';
import '../models/bank_transaction.dart';
import '../providers/bank_provider.dart';
import '../utils/app_utils.dart';
import 'bank_transaction_form.dart';

class BankAccountTransactionScreen extends StatefulWidget {
  final BankAccount account;

  const BankAccountTransactionScreen({super.key, required this.account});

  @override
  State<BankAccountTransactionScreen> createState() => _BankAccountTransactionScreenState();
}

class _BankAccountTransactionScreenState extends State<BankAccountTransactionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BankProvider>(context, listen: false).loadTransactions(widget.account.id!);
    });
  }

  void _showTransactionOptions(BuildContext context, BankTransaction tx, int accountId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('এডিট করুন'),
              onTap: () {
                Navigator.pop(ctx);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                  builder: (context) => BankTransactionForm(transaction: tx, initialAccount: widget.account),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('ডিলিট করুন'),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteTransaction(context, tx, accountId);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteTransaction(BuildContext context, BankTransaction tx, int accountId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ট্রানজেকশন ডিলিট?'),
        content: const Text('আপনি কি নিশ্চিত যে এই ট্রানজেকশনটি ডিলিট করতে চান?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('বাতিল'),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<BankProvider>(context, listen: false).deleteTransaction(tx.id!, accountId);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('ডিলিট'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(widget.account.name),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: Consumer<BankProvider>(
        builder: (context, provider, child) {
          // Find the up-to-date account to show live balance
          final currentAccount = provider.accounts.firstWhere(
            (a) => a.id == widget.account.id,
            orElse: () => widget.account,
          );

          return Column(
            children: [
              // Balance Header
              Container(
                width: double.infinity,
                color: Colors.blue.shade800,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  children: [
                    const Text(
                      'বর্তমান ব্যালেন্স',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '৳${AppUtils.toBengali(currentAccount.balance.toStringAsFixed(0))}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Transaction List
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : provider.transactions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.history, size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  'এই অ্যাকাউন্টে কোনো লেনদেন নেই',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                            itemCount: provider.transactions.length,
                            itemBuilder: (context, index) {
                              final tx = provider.transactions[index];
                              final isPositive = tx.type == 'deposit' || tx.type == 'receive';

                              String typeLabel = '';
                              IconData typeIcon = Icons.swap_horiz;
                              Color typeColor = Colors.grey;

                              if (tx.type == 'deposit') {
                                typeLabel = 'জমা';
                                typeIcon = Icons.arrow_downward;
                                typeColor = Colors.green;
                              } else if (tx.type == 'receive') {
                                typeLabel = 'রিসিভ';
                                typeIcon = Icons.call_received;
                                typeColor = Colors.blue;
                              } else if (tx.type == 'cash_out') {
                                typeLabel = 'ক্যাশআউট';
                                typeIcon = Icons.arrow_upward;
                                typeColor = Colors.red;
                              } else if (tx.type == 'payment') {
                                typeLabel = 'পেমেন্ট';
                                typeIcon = Icons.call_made;
                                typeColor = Colors.orange;
                              }

                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: typeColor.withValues(alpha: 0.1),
                                    child: Icon(typeIcon, color: typeColor, size: 20),
                                  ),
                                  title: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(typeLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Text(
                                        '${isPositive ? '+' : '-'} ৳${AppUtils.toBengali(tx.amount.toStringAsFixed(0))}',
                                        style: TextStyle(
                                          color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (tx.description.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(tx.description, style: TextStyle(color: Colors.grey.shade700)),
                                      ],
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat('dd MMM yyyy, hh:mm a').format(tx.date),
                                        style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    _showTransactionOptions(context, tx, currentAccount.id!);
                                  },
                                ),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            builder: (context) => BankTransactionForm(initialAccount: widget.account),
          );
        },
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('নতুন লেনদেন'),
      ),
    );
  }
}
