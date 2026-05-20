import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/collection_provider.dart';
import '../widgets/customer_card.dart';
import '../utils/app_utils.dart';

class CollectionListScreen extends StatelessWidget {
  const CollectionListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('বাকি আদায় লিস্ট'),
        backgroundColor: Colors.green.shade800,
        actions: [
          Consumer<CollectionProvider>(
            builder: (context, collectionProvider, child) {
              if (collectionProvider.collectionIds.isEmpty) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(Icons.delete_sweep),
                tooltip: 'সব রিমুভ করুন',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('নিশ্চিত করুন'),
                      content: const Text('লিস্ট থেকে সব কাস্টমার রিমুভ করতে চান?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('না'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('হ্যাঁ'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    if (!context.mounted) return;
                    await collectionProvider.clearCollection();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('লিস্ট ক্লিয়ার করা হয়েছে')),
                      );
                    }
                  }
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<CollectionProvider>(
        builder: (context, collectionProvider, child) {
          if (collectionProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final customers = collectionProvider.collectionCustomers;

          if (customers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.playlist_add_check, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'আদায় লিস্ট খালি।\nকাস্টমার কার্ড থেকে যোগ করুন।',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          final totalDue = customers.fold(0.0, (sum, c) => sum + c.dueAmount);

          return Column(
            children: [
              // Summary Header
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.green.shade50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'মোট কাস্টমার',
                          style: TextStyle(color: Colors.green.shade800, fontSize: 13),
                        ),
                        Text(
                          '${AppUtils.toBengali(customers.length.toString())} জন',
                          style: TextStyle(
                            color: Colors.green.shade900,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'মোট আদায়যোগ্য',
                          style: TextStyle(color: Colors.green.shade800, fontSize: 13),
                        ),
                        Text(
                          '৳${AppUtils.toBengali(totalDue.toStringAsFixed(0))}',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // List
              Expanded(
                child: ListView.builder(
                  itemCount: customers.length,
                  itemBuilder: (context, index) {
                    // Reusing CustomerCard directly. It already handles the "Remove" action inside itself.
                    return CustomerCard(customer: customers[index]);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
