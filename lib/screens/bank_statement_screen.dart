import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/bank_provider.dart';
import '../models/bank_account.dart';
import '../models/bank_transaction.dart';
import '../utils/app_utils.dart';
import 'bank_account_form.dart';
import 'bank_transaction_form.dart';

class BankStatementScreen extends StatelessWidget {
  const BankStatementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('ব্যাংক স্টেটমেন্ট'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: Consumer<BankProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.accounts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Total Balance Header
              Container(
                width: double.infinity,
                color: Colors.blue.shade800,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  children: [
                    const Text(
                      'মোট ব্যাংক ব্যালেন্স',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '৳${AppUtils.toBengali(provider.totalBalance.toStringAsFixed(0))}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Accounts List (Horizontal Scroll)
              Container(
                height: 140,
                padding: const EdgeInsets.symmetric(vertical: 16),
                color: Colors.white,
                child: provider.accounts.isEmpty
                    ? Center(
                        child: Text(
                          'কোনো অ্যাকাউন্ট নেই।\nনিচের + বাটনে ক্লিক করে যোগ করুন।',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: provider.accounts.length + 1, // +1 for Add button
                        itemBuilder: (context, index) {
                          if (index == provider.accounts.length) {
                            return _buildAddAccountCard(context);
                          }
                          return _buildAccountCard(context, provider, provider.accounts[index]);
                        },
                      ),
              ),
              const Divider(height: 1, thickness: 1),

              // Transaction History
              Expanded(
                child: provider.selectedAccountId == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.touch_app, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              'ট্রানজেকশন দেখতে উপরে একটি\nঅ্যাকাউন্ট সিলেক্ট করুন',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : _buildTransactionList(context, provider),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final provider = Provider.of<BankProvider>(context, listen: false);
          BankAccount? initialAcc;
          if (provider.selectedAccountId != null) {
            initialAcc = provider.accounts.firstWhere((a) => a.id == provider.selectedAccountId);
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BankTransactionForm(initialAccount: initialAcc),
            ),
          );
        },
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('নতুন লেনদেন'),
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context, BankProvider provider, BankAccount account) {
    final isSelected = provider.selectedAccountId == account.id;
    return GestureDetector(
      onTap: () {
        if (isSelected) {
          provider.clearSelectedAccount();
        } else {
          provider.loadTransactions(account.id!);
        }
      },
      onLongPress: () {
        _showAccountOptions(context, account);
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue.shade400 : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.blue.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _getAccountIcon(account.type),
                const Spacer(),
                if (isSelected) const Icon(Icons.check_circle, color: Colors.blue, size: 16),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              account.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              account.accountNumber,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Text(
              '৳${AppUtils.toBengali(account.balance.toStringAsFixed(0))}',
              style: TextStyle(
                color: account.balance < 0 ? Colors.red : Colors.green.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddAccountCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BankAccountForm()),
        );
      },
      child: Container(
        width: 60,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: Colors.blue.shade700, size: 28),
            const SizedBox(height: 4),
            Text('অ্যাকাউন্ট', style: TextStyle(color: Colors.grey.shade700, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _getAccountIcon(String type) {
    IconData iconData;
    Color color;
    switch (type) {
      case 'bkash':
        iconData = Icons.account_balance_wallet;
        color = Colors.pink;
        break;
      case 'nagad':
        iconData = Icons.money;
        color = Colors.orange;
        break;
      case 'rocket':
        iconData = Icons.rocket_launch;
        color = Colors.purple;
        break;
      case 'bank':
        iconData = Icons.account_balance;
        color = Colors.blue.shade700;
        break;
      default:
        iconData = Icons.payments;
        color = Colors.green;
    }
    return Icon(iconData, color: color, size: 24);
  }

  Widget _buildTransactionList(BuildContext context, BankProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (provider.transactions.isEmpty) {
      return Center(
        child: Text('এই অ্যাকাউন্টে কোনো লেনদেন নেই', style: TextStyle(color: Colors.grey.shade600)),
      );
    }

    final account = provider.accounts.firstWhere((a) => a.id == provider.selectedAccountId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            '${account.name} এর লেনদেন সমূহ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80), // Space for FAB
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
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                    _showTransactionOptions(context, tx, provider.selectedAccountId!);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAccountOptions(BuildContext context, BankAccount account) {
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BankAccountForm(account: account)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('ডিলিট করুন'),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteAccount(context, account);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, BankAccount account) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('অ্যাকাউন্ট ডিলিট?'),
        content: Text('আপনি কি নিশ্চিত যে "${account.name}" অ্যাকাউন্টটি ডিলিট করতে চান? এর সাথে থাকা সব লেনদেনও ডিলিট হয়ে যাবে।'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('বাতিল'),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<BankProvider>(context, listen: false).deleteAccount(account.id!);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('ডিলিট'),
          ),
        ],
      ),
    );
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BankTransactionForm(transaction: tx)),
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
}
