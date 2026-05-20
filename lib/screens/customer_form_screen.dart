import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../models/customer.dart';
import '../providers/customer_provider.dart';

class CustomerFormScreen extends StatefulWidget {
  final Customer? customer;

  const CustomerFormScreen({super.key, this.customer});

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _pageNoController;
  late TextEditingController _suchiNoController;
  late TextEditingController _mobileController;
  late TextEditingController _addressController;

  String? _selectedKhata;
  bool _isPickingContact = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer?.name ?? '');
    _pageNoController =
        TextEditingController(text: widget.customer?.pageNo ?? '');
    _suchiNoController =
        TextEditingController(text: widget.customer?.suchiNo ?? '');
    _mobileController =
        TextEditingController(text: widget.customer?.mobile ?? '');
    _addressController =
        TextEditingController(text: widget.customer?.address ?? '');
    _selectedKhata = widget.customer?.khataNo;

    // Auto-format if existing mobile has issues
    if (_mobileController.text.isNotEmpty) {
      _mobileController.text =
          _formatPhoneNumber(_mobileController.text);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pageNoController.dispose();
    _suchiNoController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  /// Formats a raw phone number to a clean 11-digit Bangladeshi number.
  /// Handles: +8801..., 8801..., 01..., hyphens, spaces, +৮৮০, ০১... (Bangla digits)
  String _formatPhoneNumber(String raw) {
    // Convert Bangla digits to English
    String number = _convertBanglaToEnglish(raw.trim());

    // Remove all non-digit characters (spaces, hyphens, +, etc.)
    number = number.replaceAll(RegExp(r'[^\d]'), '');

    // Remove country codes: 880 prefix
    if (number.startsWith('880') && number.length > 11) {
      number = '0${number.substring(3)}';
    }
    // 00880 prefix
    if (number.startsWith('00880') && number.length > 13) {
      number = '0${number.substring(5)}';
    }

    // Trim to 11 digits if still longer
    if (number.length > 11) {
      // Try to find '01' within the string
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

      // Fetch full contact with phone details
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

      // Pick the first phone number and format it
      final rawPhone = full.phones.first.number;
      final formatted = _formatPhoneNumber(rawPhone);

      if (mounted) {
        // Validate the formatted number
        if (formatted.length == 11 && formatted.startsWith('01')) {
          _mobileController.text = formatted;
          // Also fill name if empty
          if (_nameController.text.isEmpty && full.displayName.isNotEmpty) {
            _nameController.text = full.displayName;
          }
        } else {
          // Show dialog if number is still invalid after formatting
          _mobileController.text = formatted;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'নম্বর সঠিক নয়: "$formatted" — ম্যানুয়ালি ঠিক করুন'),
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

  void _saveCustomer() {
    if (_formKey.currentState!.validate()) {
      if (_selectedKhata == null || _selectedKhata!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('অনুগ্রহ করে খাতা নির্বাচন করুন')),
        );
        return;
      }

      final dueAmount = widget.customer?.dueAmount ?? 0.0;

      final customer = Customer(
        id: widget.customer?.id,
        name: _nameController.text.trim(),
        pageNo: _pageNoController.text.trim(),
        khataNo: _selectedKhata!,
        suchiNo: _suchiNoController.text.trim(),
        mobile: _mobileController.text.trim(),
        address: _addressController.text.trim(),
        dueAmount: dueAmount,
      );

      final provider = Provider.of<CustomerProvider>(context, listen: false);
      if (widget.customer == null) {
        provider.addCustomer(customer);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('কাস্টমার সফলভাবে যোগ করা হয়েছে')),
        );
      } else {
        provider.updateCustomer(customer);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('কাস্টমার তথ্য আপডেট করা হয়েছে')),
        );
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final khatas = Provider.of<CustomerProvider>(context).khatas;
    final isEditing = widget.customer != null;

    if (_selectedKhata != null &&
        !khatas.any((k) => k.name == _selectedKhata)) {
      _selectedKhata = null;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'কাস্টমার সম্পাদনা' : 'নতুন কাস্টমার যোগ'),
        backgroundColor: Colors.green.shade800,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                controller: _nameController,
                label: 'কাস্টমারের নাম *',
                icon: Icons.person,
                validator: (val) =>
                    val == null || val.isEmpty ? 'নাম লিখুন' : null,
              ),
              const SizedBox(height: 16),

              // ── Mobile field with contact picker button ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      maxLength: 11,
                      onChanged: _onMobileChanged,
                      decoration: InputDecoration(
                        labelText: 'মোবাইল নম্বর',
                        prefixIcon:
                            Icon(Icons.phone, color: Colors.green.shade700),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                              color: Colors.green.shade700, width: 2),
                        ),
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
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.green.shade700,
                          borderRadius: BorderRadius.circular(10),
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
              const Padding(
                padding: EdgeInsets.only(left: 12, top: 4, bottom: 12),
                child: Text(
                  '01XXXXXXXXX (১১ সংখ্যা)',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _addressController,
                label: 'ঠিকানা (ঐচ্ছিক)',
                icon: Icons.location_on,
              ),
              const SizedBox(height: 16),

              // Dropdown for Khata
              DropdownButtonFormField<String>(
                initialValue: _selectedKhata,
                decoration: InputDecoration(
                  labelText: 'খাতা নির্বাচন করুন *',
                  prefixIcon:
                      Icon(Icons.menu_book, color: Colors.green.shade700),
                  filled: true,
                  fillColor: Colors.green.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: Colors.green.shade700, width: 2),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                ),
                icon:
                    Icon(Icons.arrow_drop_down_circle, color: Colors.green.shade700),
                dropdownColor: Colors.white,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
                items: khatas.map((khata) {
                  return DropdownMenuItem<String>(
                    value: khata.name,
                    child: Text(khata.name,
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedKhata = val;
                  });
                },
                validator: (val) => val == null ? 'খাতা নির্বাচন করুন' : null,
                hint: const Text('কোন খাতায় আছে?'),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _pageNoController,
                      label: 'পৃষ্ঠা নং',
                      icon: Icons.find_in_page,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _suchiNoController,
                      label: 'সূচি ক্র: নং',
                      icon: Icons.format_list_numbered,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: _saveCustomer,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  isEditing ? 'আপডেট করুন' : 'সংরক্ষণ করুন',
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.green.shade700),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.green.shade700, width: 2),
        ),
      ),
    );
  }
}
