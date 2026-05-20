import 'package:flutter/material.dart';
import '../models/supplier.dart';
import 'package:provider/provider.dart';
import '../providers/supplier_provider.dart';
import '../screens/supplier_form_screen.dart';
import '../screens/supplier_transaction_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class SupplierCard extends StatelessWidget {
  final Supplier supplier;

  const SupplierCard({super.key, required this.supplier});

  String _toBengali(String input) {
    const bengaliDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    return input.replaceAllMapped(RegExp(r'[0-9]'), (match) {
      return bengaliDigits[int.parse(match.group(0)!)];
    });
  }

  Color _agingColor(int days) {
    if (days >= 90) return const Color(0xFFB71C1C); // dark red
    if (days >= 60) return Colors.red.shade600;
    if (days >= 30) return Colors.orange.shade700;
    return Colors.amber.shade700;
  }

  String _agingLabel(int days) {
    final d = _toBengali(days.toString());
    if (days >= 90) return '$d দিন হলো বাকি! পরিশোধ করুন';
    if (days >= 60) return '$d দিন হলো বাকি';
    if (days >= 30) return '$d দিন হলো বাকি';
    return '$d দিন হলো বাকি';
  }

  Widget _buildAgingBadge(int days) {
    final color = _agingColor(days);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            _agingLabel(days),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasDue = supplier.dueAmount > 0;
    final provider = Provider.of<SupplierProvider>(context, listen: false);
    final oldestPurchaseDate = hasDue ? provider.oldestPurchaseDates[supplier.id] : null;
    final agingDays = oldestPurchaseDate != null
        ? DateTime.now().difference(oldestPurchaseDate).inDays
        : 0;
    final theme = Theme.of(context);

    return Dismissible(
      key: Key(supplier.id.toString()),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("নিশ্চিত করুন"),
              content: Text(
                  "${supplier.name}-কে মুছে ফেলতে চান? উনার সাথে সম্পর্কিত সব লেনদেনও মুছে যাবে।"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("না"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("হ্যাঁ"),
                ),
              ],
            );
          },
        );
        if (confirm == true) {
          if (!context.mounted) return false;
          Provider.of<SupplierProvider>(context, listen: false)
              .deleteSupplier(supplier.id!);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('সাপ্লায়ার মুছে ফেলা হয়েছে')),
          );
        }
        return false;
      },
      onDismissed: (direction) {},
      background: Container(
        color: Colors.red.shade700,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        color: hasDue ? Colors.orange.shade50.withValues(alpha: 0.5) : Colors.white,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    SupplierTransactionScreen(supplier: supplier),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name & Edit
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        supplier.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SupplierFormScreen(supplier: supplier),
                          ),
                        );
                      },
                      child: Icon(Icons.edit_outlined,
                          size: 20, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Company & Phone
                if (supplier.companyName.isNotEmpty ||
                    supplier.mobile.isNotEmpty)
                  Row(
                    children: [
                      if (supplier.companyName.isNotEmpty) ...[
                        Icon(Icons.business,
                            size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          supplier.companyName,
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(width: 16),
                      ],
                      if (supplier.mobile.isNotEmpty) ...[
                        InkWell(
                          onTap: () async {
                            final Uri url = Uri.parse('tel:${supplier.mobile}');
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('কল করা সম্ভব হচ্ছে না')),
                                );
                              }
                            }
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.phone, size: 14, color: Colors.blue),
                              const SizedBox(width: 4),
                              Text(
                                supplier.mobile,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                const SizedBox(height: 12),

                // Debt Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'আমাদের মোট দেনা',
                      style: theme.textTheme.bodySmall,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: hasDue
                            ? Colors.orange.shade600
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '৳${_toBengali(supplier.dueAmount.toStringAsFixed(0))}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: hasDue ? Colors.white : Colors.green.shade800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                if (hasDue && agingDays >= 15) ...[
                  const SizedBox(height: 8),
                  _buildAgingBadge(agingDays),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
