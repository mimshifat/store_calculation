import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:provider/provider.dart';
import '../models/supplier.dart';
import '../providers/supplier_provider.dart';

class SupplierFormScreen extends StatefulWidget {
  final Supplier? supplier;

  const SupplierFormScreen({super.key, this.supplier});

  @override
  State<SupplierFormScreen> createState() => _SupplierFormScreenState();
}

class _SupplierFormScreenState extends State<SupplierFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _mobileController = TextEditingController();
  bool _isPickingContact = false;

  @override
  void initState() {
    super.initState();
    if (widget.supplier != null) {
      _nameController.text = widget.supplier!.name;
      _companyController.text = widget.supplier!.companyName;
      _mobileController.text = widget.supplier!.mobile;
      // Auto-format if existing mobile has issues
      if (_mobileController.text.isNotEmpty) {
        _mobileController.text = _formatPhoneNumber(_mobileController.text);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  /// Formats a raw phone number to a clean 11-digit Bangladeshi number.
  String _formatPhoneNumber(String raw) {
    String number = _convertBanglaToEnglish(raw.trim());
    number = number.replaceAll(RegExp(r'[^\d]'), '');

    if (number.startsWith('880') && number.length > 11) {
      number = '0${number.substring(3)}';
    }
    if (number.startsWith('00880') && number.length > 13) {
      number = '0${number.substring(5)}';
    }
    if (number.length > 11) {
      final idx = number.indexOf('01');
      if (idx != -1 && number.length - idx >= 11) {
        number = number.substring(idx, idx + 11);
      } else {
        number = number.substring(number.length - 11);
      }
    }
    return number;
  }

  String _convertBanglaToEnglish(String input) {
    const banglaDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    String result = input;
    for (int i = 0; i < banglaDigits.length; i++) {
      result = result.replaceAll(banglaDigits[i], '$i');
    }
    return result;
  }

  void _onMobileChanged(String value) {
    final formatted = _formatPhoneNumber(value);
    if (formatted != value) {
      _mobileController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  Future<void> _pickContact() async {
    setState(() => _isPickingContact = true);
    try {
      if (!await FlutterContacts.requestPermission(readonly: true)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('কন্টাক্ট অ্যাক্সেসের অনুমতি দিন')),
          );
        }
        return;
      }

      final contact = await FlutterContacts.openExternalPick();
      if (contact == null) return;

      final full = await FlutterContacts.getContact(contact.id,
          withProperties: true);
      if (full == null || full.phones.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('এই কন্টাক্টে কোনো নম্বর নেই')),
          );
        }
        return;
      }

      final rawPhone = full.phones.first.number;
      final formatted = _formatPhoneNumber(rawPhone);

      if (mounted) {
        if (formatted.length == 11 && formatted.startsWith('01')) {
          _mobileController.text = formatted;
          if (_nameController.text.isEmpty && full.displayName.isNotEmpty) {
            _nameController.text = full.displayName;
          }
        } else {
          _mobileController.text = formatted;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('নম্বর সঠিক নয়: "$formatted" — ম্যানুয়ালি ঠিক করুন'),
              backgroundColor: Colors.orange.shade700,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('কন্টাক্ট পাওয়া যায়নি: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingContact = false);
    }
  }

  void _saveSupplier() async {
    if (_formKey.currentState!.validate()) {
      final supplier = Supplier(
        id: widget.supplier?.id,
        name: _nameController.text.trim(),
        companyName: _companyController.text.trim(),
        mobile: _mobileController.text.trim(),
        dueAmount: widget.supplier?.dueAmount ?? 0.0,
      );

      final provider = Provider.of<SupplierProvider>(context, listen: false);

      if (widget.supplier == null) {
        await provider.addSupplier(supplier);
      } else {
        await provider.updateSupplier(supplier);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.supplier != null;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(isEditing ? 'সাপ্লায়ার আপডেট' : 'নতুন সাপ্লায়ার'),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 40,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.orange.shade800,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -20),
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          isEditing ? 'সাপ্লায়ারের তথ্য আপডেট করুন' : 'সাপ্লায়ারের তথ্য দিন',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // Name
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'নাম *',
                            prefixIcon: const Icon(Icons.person, color: Colors.orange),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'দয়া করে নাম দিন';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Company
                        TextFormField(
                          controller: _companyController,
                          decoration: InputDecoration(
                            labelText: 'কোম্পানির নাম',
                            prefixIcon: const Icon(Icons.business, color: Colors.orange),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Mobile with contact picker
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _mobileController,
                                keyboardType: TextInputType.phone,
                                maxLength: 11,
                                onChanged: _onMobileChanged,
                                decoration: InputDecoration(
                                  labelText: 'মোবাইল নম্বর',
                                  prefixIcon: const Icon(Icons.phone, color: Colors.orange),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.orange.shade700, width: 2),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  counterText: '',
                                ),
                                validator: (val) {
                                  if (val != null && val.isNotEmpty) {
                                    if (val.length != 11) {
                                      return 'মোবাইল নম্বর ১১ ডিজিটের হতে হবে';
                                    }
                                    if (!val.startsWith('01')) {
                                      return 'সঠিক মোবাইল নম্বর দিন (যেমন: 01...)';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Tooltip(
                              message: 'কন্টাক্ট থেকে নম্বর নিন',
                              child: InkWell(
                                onTap: _isPickingContact ? null : _pickContact,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade700,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: _isPickingContact
                                      ? const Padding(
                                          padding: EdgeInsets.all(14),
                                          child: CircularProgressIndicator(
                                              color: Colors.white, strokeWidth: 2),
                                        )
                                      : const Icon(Icons.contacts,
                                          color: Colors.white, size: 26),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
                          child: Text(
                            '01XXXXXXXXX (১১ সংখ্যা)',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Save Button
                        ElevatedButton(
                          onPressed: _saveSupplier,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                          child: const Text(
                            'সেভ করুন',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
