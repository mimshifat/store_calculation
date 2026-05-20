import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/bank_transaction.dart';
import '../models/bank_account.dart';
import '../providers/bank_provider.dart';

class BankTransactionForm extends StatefulWidget {
  final BankTransaction? transaction;
  final BankAccount? initialAccount;

  const BankTransactionForm({super.key, this.transaction, this.initialAccount});

  @override
  State<BankTransactionForm> createState() => _BankTransactionFormState();
}

class _BankTransactionFormState extends State<BankTransactionForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _descController;
  DateTime _selectedDate = DateTime.now();
  String _selectedType = 'deposit';
  BankAccount? _selectedAccount;

  final List<Map<String, dynamic>> _transactionTypes = [
    {'value': 'deposit', 'label': 'জমা (Deposit)', 'icon': Icons.arrow_downward, 'color': Colors.green},
    {'value': 'receive', 'label': 'রিসিভ (Receive)', 'icon': Icons.call_received, 'color': Colors.blue},
    {'value': 'cash_out', 'label': 'ক্যাশআউট (Cash Out)', 'icon': Icons.arrow_upward, 'color': Colors.red},
    {'value': 'payment', 'label': 'পেমেন্ট (Payment)', 'icon': Icons.call_made, 'color': Colors.orange},
  ];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.transaction != null ? widget.transaction!.amount.toStringAsFixed(0) : '',
    );
    _descController = TextEditingController(text: widget.transaction?.description ?? '');
    
    if (widget.transaction != null) {
      _selectedDate = widget.transaction!.date;
      _selectedType = widget.transaction!.type;
    }

    final provider = Provider.of<BankProvider>(context, listen: false);
    if (widget.transaction != null) {
      _selectedAccount = provider.accounts.firstWhere((a) => a.id == widget.transaction!.accountId);
    } else if (widget.initialAccount != null) {
      _selectedAccount = widget.initialAccount;
    } else if (provider.accounts.isNotEmpty) {
      _selectedAccount = provider.accounts.first;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _saveForm() async {
    if (_formKey.currentState!.validate() && _selectedAccount != null) {
      final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
      final desc = _descController.text.trim();

      final newTransaction = BankTransaction(
        id: widget.transaction?.id,
        accountId: _selectedAccount!.id!,
        type: _selectedType,
        amount: amount,
        description: desc,
        date: _selectedDate,
      );

      final provider = Provider.of<BankProvider>(context, listen: false);

      if (widget.transaction == null) {
        await provider.addTransaction(newTransaction);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ট্রানজেকশন যোগ করা হয়েছে')),
          );
        }
      } else {
        await provider.updateTransaction(newTransaction);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ট্রানজেকশন আপডেট করা হয়েছে')),
          );
        }
      }

      if (mounted) Navigator.pop(context);
    } else if (_selectedAccount == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('দয়া করে একটি অ্যাকাউন্ট সিলেক্ট করুন')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction == null ? 'নতুন ট্রানজেকশন' : 'এডিট ট্রানজেকশন'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Consumer<BankProvider>(
                builder: (context, provider, child) {
                  if (provider.accounts.isEmpty) {
                    return const Text('কোনো অ্যাকাউন্ট নেই। আগে অ্যাকাউন্ট তৈরি করুন।', style: TextStyle(color: Colors.red));
                  }
                  return DropdownButtonFormField<BankAccount>(
                    initialValue: _selectedAccount,
                    decoration: const InputDecoration(
                      labelText: 'অ্যাকাউন্ট নির্বাচন করুন',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.account_balance),
                    ),
                    items: provider.accounts.map((acc) {
                      return DropdownMenuItem<BankAccount>(
                        value: acc,
                        child: Text('${acc.name} (${acc.accountNumber})'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedAccount = value;
                      });
                    },
                    validator: (value) => value == null ? 'অ্যাকাউন্ট সিলেক্ট করুন' : null,
                  );
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'ট্রানজেকশন ধরন',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.swap_horiz),
                ),
                items: _transactionTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type['value'] as String,
                    child: Row(
                      children: [
                        Icon(type['icon'], color: type['color'], size: 20),
                        const SizedBox(width: 8),
                        Text(type['label']),
                      ],
                    ),
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
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'পরিমাণ (টাকা)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'পরিমাণ লিখুন' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'বিবরণ (অপশনাল)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text('তারিখ: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                trailing: TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = picked;
                      });
                    }
                  },
                  child: const Text('পরিবর্তন করুন'),
                ),
              ),
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
