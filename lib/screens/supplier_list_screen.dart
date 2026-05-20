import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/supplier_provider.dart';
import '../widgets/supplier_card.dart';
import '../widgets/dashboard_card.dart';
import '../utils/app_utils.dart';
import 'supplier_form_screen.dart';

class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({super.key});

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('সাপ্লায়ার / কোম্পানি', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
      ),
      body: Consumer<SupplierProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.orange));
          }

          // Calculate total due we owe to suppliers
          final totalSupplierDue = provider.totalDueAllSuppliers;

          return Column(
            children: [
              // Dashboard Area
              Container(
                width: double.infinity,
                color: Colors.orange.shade800,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: DashboardCard(
                  title: 'আমাদের মোট দেনা (সাপ্লায়ার/কোম্পানির কাছে)',
                  amount: '৳${AppUtils.toBengali(totalSupplierDue.toStringAsFixed(0))}',
                  icon: Icons.account_balance_wallet,
                  gradientColors: [Colors.red.shade400, Colors.red.shade700],
                ),
              ),

              // Search Bar Area
              Transform.translate(
                offset: const Offset(0, -20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => provider.setSearchQuery(val),
                      decoration: InputDecoration(
                        hintText: 'নাম, কোম্পানি বা মোবাইল দিয়ে খুঁজুন...',
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.grey),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon:
                                    const Icon(Icons.clear, color: Colors.grey),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                  });
                                  provider.setSearchQuery('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                ),
              ),

              // Total Count Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'সাপ্লায়ার তালিকা',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.orange.shade100),
                      ),
                      child: Text(
                        'মোট: ${provider.suppliers.length} জন',
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),

              // Supplier List
              Expanded(
                child: provider.suppliers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_add_disabled, size: 80, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              'কোনো সাপ্লায়ার পাওয়া যায়নি',
                              style: TextStyle(fontSize: 18, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: provider.suppliers.length,
                        itemBuilder: (context, index) {
                          return SupplierCard(supplier: provider.suppliers[index]);
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
            MaterialPageRoute(builder: (context) => const SupplierFormScreen()),
          );
        },
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('নতুন সাপ্লায়ার'),
      ),
    );
  }
}
