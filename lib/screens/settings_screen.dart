import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/customer_provider.dart';
import '../services/excel_service.dart';
import '../services/backup_service.dart';
import '../services/telegram_service.dart';
import '../providers/supplier_provider.dart';
import '../providers/cash_provider.dart';
import '../providers/report_provider.dart';
import '../providers/bank_provider.dart';
import 'khata_manage_screen.dart';
import 'report_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _importExcel(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final provider = Provider.of<CustomerProvider>(context, listen: false);
    
    final importedData = await ExcelService.importExcel();
    
    if (importedData != null && importedData.isNotEmpty) {
      await provider.importCustomers(importedData);
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('✅ ${importedData.length} জন কাস্টমার ইমপোর্ট করা হয়েছে!')),
      );
    } else {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('❌ ইমপোর্ট ব্যর্থ হয়েছে বা ফাইল খালি ছিল।')),
      );
    }
  }

  void _exportExcel(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final customers = Provider.of<CustomerProvider>(context, listen: false).allCustomers;
    
    if (customers.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('এক্সপোর্ট করার মত কোনো ডাটা নেই!')),
      );
      return;
    }

    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('এক্সপোর্ট হচ্ছে...')),
    );

    final success = await ExcelService.exportExcel(customers);
    
    if (!success) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('❌ এক্সপোর্ট ব্যর্থ হয়েছে!')),
      );
    }
  }

  void _backupDatabase(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('ব্যাকআপ ফাইল তৈরি হচ্ছে...')),
    );
    final success = await BackupService.backupDatabase();
    if (!success) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('❌ ব্যাকআপ ব্যর্থ হয়েছে!')),
      );
    }
  }

  void _restoreDatabase(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final provider = Provider.of<CustomerProvider>(context, listen: false);
    
    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('ডাটাবেস রিস্টোর করা হচ্ছে...')),
    );
    
    final success = await BackupService.restoreDatabase();
    if (success) {
      try {
        await provider.loadData();
        if (context.mounted) {
          Provider.of<SupplierProvider>(context, listen: false).loadData();
          Provider.of<CashProvider>(context, listen: false).loadData();
          final now = DateTime.now();
          final monthStart = DateTime(now.year, now.month, 1);
          final monthEnd = DateTime(now.year, now.month + 1, 0);
          Provider.of<ReportProvider>(context, listen: false).loadReport(monthStart, monthEnd);
          Provider.of<BankProvider>(context, listen: false).loadAccounts();
        }
        if (context.mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('✅ ডাটাবেস সফলভাবে রিস্টোর হয়েছে!')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('❌ রিস্টোর করা ডাটাবেসটি সাপোর্ট করছে না! Error: $e')),
          );
        }
      }
    } else {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('❌ রিস্টোর বাতিল বা ব্যর্থ হয়েছে! (ফাইলটি সঠিক নাও হতে পারে)')),
      );
    }
  }

  void _configureTelegram(BuildContext context) async {
    final config = await TelegramService.instance.getConfig();
    final tokenController = TextEditingController(text: config['token'] ?? '');
    final chatIdController = TextEditingController(text: config['chatId'] ?? '');

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Telegram ব্যাকআপ সেটআপ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'আপনার Bot Token এবং Chat ID দিন।',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: tokenController,
              decoration: const InputDecoration(
                labelText: 'Bot Token',
                border: OutlineInputBorder(),
                hintText: '123456:ABC-DEF1234...',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: chatIdController,
              decoration: const InputDecoration(
                labelText: 'Chat ID',
                border: OutlineInputBorder(),
                hintText: '123456789',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('বাতিল', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final token = tokenController.text.trim();
              final chatId = chatIdController.text.trim();
              
              if (token.isEmpty || chatId.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('দয়া করে সঠিক টোকেন এবং চ্যাট আইডি দিন।')),
                );
                return;
              }

              await TelegramService.instance.saveConfig(token, chatId);
              if (ctx.mounted) Navigator.pop(ctx);
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('টেস্ট ব্যাকআপ পাঠানো হচ্ছে...')),
                );
                
                final result = await TelegramService.instance.backupDatabase();
                if (context.mounted) {
                  if (result == 'success') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ সফলভাবে টেলিগ্রামে ব্যাকআপ পাঠানো হয়েছে!')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('❌ এরর: $result')),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('সেভ ও টেস্ট করুন'),
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
        title: const Text('সেটিংস ও অন্যান্য'),
        backgroundColor: Colors.green.shade800,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('ম্যানেজমেন্ট'),
          _buildListTile(
            context,
            icon: Icons.library_books,
            title: 'খাতা ম্যানেজমেন্ট',
            subtitle: 'দোকানের খাতা যোগ করুন বা নাম পরিবর্তন করুন',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const KhataManageScreen()),
              );
            },
          ),
          _buildListTile(
            context,
            icon: Icons.bar_chart,
            title: 'বিজনেস রিপোর্ট',
            subtitle: 'মাসিক বা বাৎসরিক আয়-ব্যয়ের রিপোর্ট দেখুন',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReportScreen()),
              );
            },
          ),
          
          const SizedBox(height: 24),
          _buildSectionHeader('ডাটা ইমপোর্ট/এক্সপোর্ট'),
          _buildListTile(
            context,
            icon: Icons.upload_file,
            title: 'এক্সেল ইমপোর্ট',
            subtitle: 'পুরানো হিসাব এক্সেল থেকে আনুন',
            onTap: () => _importExcel(context),
          ),
          _buildListTile(
            context,
            icon: Icons.download,
            title: 'এক্সেল এক্সপোর্ট',
            subtitle: 'কাস্টমার লিস্ট এক্সেলে ডাউনলোড করুন',
            onTap: () => _exportExcel(context),
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('নিরাপত্তা ও ব্যাকআপ'),
          _buildListTile(
            context,
            icon: Icons.backup,
            title: 'ডাটাবেস ব্যাকআপ',
            subtitle: 'সম্পূর্ণ ডাটাবেস সেভ করে রাখুন',
            onTap: () => _backupDatabase(context),
          ),
          _buildListTile(
            context,
            icon: Icons.restore,
            title: 'ডাটাবেস রিস্টোর',
            subtitle: 'আগের ব্যাকআপ করা ডাটাবেস ফিরিয়ে আনুন',
            onTap: () => _restoreDatabase(context),
          ),
          _buildListTile(
            context,
            icon: Icons.telegram,
            title: 'Telegram ব্যাকআপ সেটআপ',
            subtitle: 'প্রতিদিন অটোমেটিক টেলিগ্রাম ব্যাকআপ হবে',
            onTap: () => _configureTelegram(context),
          ),
          
          const SizedBox(height: 32),
          const Center(
            child: Text(
              'শুকরিয়া স্টোর ভার্সন ১.০.০',
              style: TextStyle(color: Colors.grey),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.green.shade800,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildListTile(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.green.shade700),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
