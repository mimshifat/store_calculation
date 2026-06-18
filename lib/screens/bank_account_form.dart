import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/bank_account.dart';
import '../providers/bank_provider.dart';

class BankAccountForm extends StatefulWidget {
  final BankAccount? account;

  const BankAccountForm({super.key, this.account});

  @override
  State<BankAccountForm> createState() => _BankAccountFormState();
}

class _BankAccountFormState extends State<BankAccountForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _numberController;
  late TextEditingController _bankNameController;
  late TextEditingController _branchNameController;
  String _selectedType = 'bkash';

  final List<Map<String, String>> _accountTypes = [
    {'value': 'bkash', 'label': 'বিকাশ'},
    {'value': 'nagad', 'label': 'নগদ'},
    {'value': 'rocket', 'label': 'রকেট'},
    {'value': 'upay', 'label': 'উপায়'},
    {'value': 'bank', 'label': 'ব্যাংক অ্যাকাউন্ট'},
    {'value': 'cash', 'label': 'ক্যাশ/অন্যান্য'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account?.name ?? '');
    _numberController = TextEditingController(text: widget.account?.accountNumber ?? '');
    _bankNameController = TextEditingController(text: widget.account?.bankName ?? '');
    _branchNameController = TextEditingController(text: widget.account?.branchName ?? '');
    if (widget.account != null) {
      _selectedType = widget.account!.type;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _bankNameController.dispose();
    _branchNameController.dispose();
    super.dispose();
  }

  void _saveForm() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final number = _numberController.text.trim();

      final newAccount = BankAccount(
        id: widget.account?.id,
        name: name,
        accountNumber: number,
        type: _selectedType,
        balance: widget.account?.balance ?? 0.0,
        bankName: _selectedType == 'bank' ? _bankNameController.text.trim() : null,
        branchName: _selectedType == 'bank' ? _branchNameController.text.trim() : null,
      );

      final provider = Provider.of<BankProvider>(context, listen: false);

      if (widget.account == null) {
        await provider.addAccount(newAccount);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('অ্যাকাউন্ট যোগ করা হয়েছে')),
          );
        }
      } else {
        await provider.updateAccount(newAccount);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('অ্যাকাউন্ট আপডেট করা হয়েছে')),
          );
        }
      }

      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.account == null ? 'নতুন অ্যাকাউন্ট' : 'এডিট অ্যাকাউন্ট'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'অ্যাকাউন্টের ধরন',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance),
                ),
                items: _accountTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type['value'],
                    child: Text(type['label']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'অ্যাকাউন্টের নাম (যেমন: আমার বিকাশ)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'নাম লিখুন' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _numberController,
                decoration: const InputDecoration(
                  labelText: 'অ্যাকাউন্ট/মোবাইল নম্বর',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'নম্বর লিখুন' : null,
              ),
              const SizedBox(height: 16),
              if (_selectedType == 'bank') ...[
                TextFormField(
                  controller: _bankNameController,
                  decoration: const InputDecoration(
                    labelText: 'ব্যাংকের নাম (যেমন: ডাচ-বাংলা ব্যাংক)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.account_balance),
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'ব্যাংকের নাম লিখুন' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _branchNameController,
                  decoration: const InputDecoration(
                    labelText: 'শাখার নাম (যেমন: মিরপুর শাখা)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_city),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: const Text('সেভ করুন'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
