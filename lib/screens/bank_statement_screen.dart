import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bank_provider.dart';
import '../models/bank_account.dart';
import '../utils/app_utils.dart';
import 'bank_account_form.dart';
import 'bank_account_transaction_screen.dart';

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
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Accounts List
              Expanded(
                child: provider.accounts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.account_balance, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              'কোনো অ্যাকাউন্ট নেই।\nনিচের + বাটনে ক্লিক করে যোগ করুন।',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        itemCount: provider.accounts.length,
                        itemBuilder: (context, index) {
                          return _buildAccountCard(context, provider, provider.accounts[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BankAccountForm()),
          );
        },
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('নতুন অ্যাকাউন্ট'),
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context, BankProvider provider, BankAccount account) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => BankAccountTransactionScreen(account: account)),
          );
        },
        onLongPress: () {
          _showAccountOptions(context, account);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: _getAccountColor(account.type).withValues(alpha: 0.1),
                radius: 24,
                child: _getAccountIcon(account.type),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      account.type == 'bank' && account.bankName != null
                          ? '${account.bankName} • ${account.accountNumber}'
                          : account.accountNumber,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '৳${AppUtils.toBengali(account.balance.toStringAsFixed(0))}',
                style: TextStyle(
                  color: account.balance < 0 ? Colors.red : Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getAccountColor(String type) {
    switch (type) {
      case 'bkash': return Colors.pink;
      case 'nagad': return Colors.orange;
      case 'rocket': return Colors.purple;
      case 'bank': return Colors.blue.shade700;
      default: return Colors.green;
    }
  }

  Widget _getAccountIcon(String type) {
    IconData iconData;
    switch (type) {
      case 'bkash': iconData = Icons.account_balance_wallet; break;
      case 'nagad': iconData = Icons.money; break;
      case 'rocket': iconData = Icons.rocket_launch; break;
      case 'bank': iconData = Icons.account_balance; break;
      default: iconData = Icons.payments;
    }
    return Icon(iconData, color: _getAccountColor(type), size: 28);
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
}
