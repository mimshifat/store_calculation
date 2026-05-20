import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/customer_provider.dart';
import '../providers/supplier_provider.dart';
import '../widgets/customer_card.dart';
import '../widgets/filter_chips.dart';
import '../widgets/dashboard_card.dart';
import '../utils/app_utils.dart';
import 'customer_form_screen.dart';
import 'cash_book_screen.dart';
import 'settings_screen.dart';
import 'khata_manage_screen.dart';
import 'supplier_list_screen.dart';
import 'bank_statement_screen.dart';
import 'collection_list_screen.dart';
import '../providers/bank_provider.dart';
import '../providers/collection_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const _HomeTab(),
    const SupplierListScreen(),
    const CashBookScreen(),
    const BankStatementScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CollectionProvider>(context, listen: false).loadCollectionList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'কাস্টমার',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'সাপ্লায়ার',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'ক্যাশবুক',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_outlined),
            selectedIcon: Icon(Icons.account_balance),
            label: 'ব্যাংক',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'সেটিংস',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
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
        title: Row(
          children: [
            Image.asset('assets/images/sukriyastore.jpeg',
                height: 32,
                width: 32,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.store)),
            const SizedBox(width: 8),
            const Text('মেসার্স শুকরিয়া স্টোর',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.green.shade800,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          Consumer<CollectionProvider>(
            builder: (context, collectionProvider, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.receipt_long),
                    tooltip: 'বাকি আদায় লিস্ট',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CollectionListScreen(),
                        ),
                      );
                    },
                  ),
                  if (collectionProvider.count > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          AppUtils.toBengali(collectionProvider.count.toString()),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer3<CustomerProvider, SupplierProvider, BankProvider>(
        builder: (context, customerProvider, supplierProvider, bankProvider, child) {
          if (customerProvider.isLoading || supplierProvider.isLoading || bankProvider.isLoading) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.green));
          }

          // Calculate total due from ALL customers (unfiltered)
          final totalCustomerDue = customerProvider.totalDueAllCustomers;
          // Calculate total due to ALL suppliers (unfiltered)
          final totalSupplierDue = supplierProvider.totalDueAllSuppliers;

          return Column(
            children: [
              // Dashboard Area - Net Position
              Container(
                width: double.infinity,
                color: Colors.green.shade800,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DashboardCard(
                            title: 'আমার পাওনা (কাস্টমার)',
                            amount: '৳${AppUtils.toBengali(totalCustomerDue.toStringAsFixed(0))}',
                            icon: Icons.call_received,
                            gradientColors: [Colors.green.shade400, Colors.green.shade600],
                            amountFontSize: 18,
                            titleFontSize: 11,
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DashboardCard(
                            title: 'আমার দেনা (সাপ্লায়ার)',
                            amount: '৳${AppUtils.toBengali(totalSupplierDue.toStringAsFixed(0))}',
                            icon: Icons.call_made,
                            gradientColors: [Colors.red.shade400, Colors.red.shade600],
                            amountFontSize: 18,
                            titleFontSize: 11,
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Search Bar Area (overlapping the dashboard slightly)
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
                      onChanged: (val) => customerProvider.setSearchQuery(val),
                      decoration: InputDecoration(
                        hintText: 'নাম, মোবাইল বা পৃষ্ঠা নং দিয়ে খুঁজুন...',
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
                                  customerProvider.setSearchQuery('');
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

              // Filter Chips
              Transform.translate(
                offset: const Offset(0, -10),
                child: const FilterChipsWidget(),
              ),

              // Total Count and Sort Button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Text(
                      'কাস্টমার তালিকা',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<CustomerSortMode>(
                      icon: const Icon(Icons.sort, color: Colors.green),
                      tooltip: 'সর্ট করুন',
                      onSelected: (mode) {
                        customerProvider.setSortMode(mode);
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: CustomerSortMode.defaultOrder,
                          child: Row(
                            children: [
                              Icon(Icons.sort_by_alpha,
                                  color: customerProvider.sortMode == CustomerSortMode.defaultOrder ? Colors.green : Colors.grey),
                              const SizedBox(width: 8),
                              const Text('ডিফল্ট (নতুন আগে)'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: CustomerSortMode.oldestDueFirst,
                          child: Row(
                            children: [
                              Icon(Icons.access_time,
                                  color: customerProvider.sortMode == CustomerSortMode.oldestDueFirst ? Colors.green : Colors.grey),
                              const SizedBox(width: 8),
                              const Text('পুরানো বাকি আগে'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: CustomerSortMode.highestDueFirst,
                          child: Row(
                            children: [
                              Icon(Icons.attach_money,
                                  color: customerProvider.sortMode == CustomerSortMode.highestDueFirst ? Colors.green : Colors.grey),
                              const SizedBox(width: 8),
                              const Text('বেশি বাকি আগে'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green.shade100),
                      ),
                      child: Text(
                        'মোট: ${AppUtils.toBengali(customerProvider.customers.length.toString())}',
                        style: TextStyle(
                          color: Colors.green.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Customer List
              Expanded(
                child: customerProvider.customers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_search,
                                size: 80, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              'কোনো কাস্টমার পাওয়া যায়নি',
                              style: TextStyle(
                                  fontSize: 18, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: customerProvider.customers.length,
                        itemBuilder: (context, index) {
                          return CustomerCard(
                              customer: customerProvider.customers[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final provider =
              Provider.of<CustomerProvider>(context, listen: false);
          if (provider.khatas.isEmpty) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('সতর্কতা'),
                content: const Text(
                    'কাস্টমার যোগ করার আগে দয়া করে অন্তত একটি খাতা যোগ করুন।'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('ঠিক আছে'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const KhataManageScreen()),
                      );
                    },
                    child: const Text('খাতা যোগ করুন'),
                  ),
                ],
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const CustomerFormScreen()),
            );
          }
        },
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('নতুন কাস্টমার'),
      ),
    );
  }
}
