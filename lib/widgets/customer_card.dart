import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/customer.dart';
import 'package:provider/provider.dart';
import '../providers/customer_provider.dart';
import '../providers/collection_provider.dart';
import '../screens/customer_form_screen.dart';
import '../screens/transaction_screen.dart';

class CustomerCard extends StatelessWidget {
  final Customer customer;

  const CustomerCard({super.key, required this.customer});


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
    if (days >= 90) return '$d দিন হলো বাকি! তাগাদা করুন';
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
    final hasDue = customer.dueAmount > 0;
    final provider = Provider.of<CustomerProvider>(context, listen: false);
    final oldestSaleDate =
        hasDue ? provider.oldestSaleDates[customer.id] : null;
    final agingDays = oldestSaleDate != null
        ? DateTime.now().difference(oldestSaleDate).inDays
        : 0;

    return Dismissible(
      key: Key(customer.id.toString()),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("নিশ্চিত করুন"),
              content: Text("${customer.name}-কে মুছে ফেলতে চান? উনার সাথে সম্পর্কিত সব লেনদেনও মুছে যাবে।"),
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
          Provider.of<CustomerProvider>(context, listen: false)
              .deleteCustomer(customer.id!);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('কাস্টমার মুছে ফেলা হয়েছে')),
          );
        }
        return false;
      },
      onDismissed: (direction) {},
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        // Highlight card if there's a due amount
        color: hasDue ? Colors.red.shade50 : null,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TransactionScreen(customer: customer),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Row 1: Name + Khata badge ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        customer.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.35),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Text(
                        "খাতা: ${customer.khataNo}",
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CustomerFormScreen(customer: customer),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(Icons.edit_outlined,
                            size: 20, color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // ── Row 2: Phone number (tappable) and SMS ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: customer.mobile.isNotEmpty
                          ? () async {
                              final Uri url = Uri.parse('tel:${customer.mobile}');
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url);
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('কল করা সম্ভব হচ্ছে না')),
                                  );
                                }
                              }
                            }
                          : null,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.phone,
                              size: 16,
                              color: customer.mobile.isNotEmpty
                                  ? Colors.blue
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              customer.mobile.isNotEmpty
                                  ? customer.mobile
                                  : 'মোবাইল নম্বর নেই',
                              style: TextStyle(
                                color: customer.mobile.isNotEmpty
                                    ? Colors.blue
                                    : Colors.grey.shade700,
                                decoration: customer.mobile.isNotEmpty
                                    ? TextDecoration.underline
                                    : TextDecoration.none,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (hasDue && customer.mobile.isNotEmpty)
                      InkWell(
                        onTap: () async {
                          final message = 'সম্মানিত গ্রাহক, আপনার বকেয়া টাকার পরিমাণ ৳${_toBengali(customer.dueAmount.toStringAsFixed(0))}। অনুগ্রহ করে বকেয়া পরিশোধ করুন।\n\nধন্যবাদান্তে,\nমেসার্স শুকরিয়া স্টোর\nবালিয়াডাঙ্গা বাজার';
                          final Uri url = Uri.parse('sms:${customer.mobile}?body=${Uri.encodeComponent(message)}');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url);
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('এসএমএস পাঠানো সম্ভব হচ্ছে না')),
                              );
                            }
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.message, size: 14, color: Colors.blue.shade700),
                              const SizedBox(width: 6),
                              Text(
                                'মেসেজ',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                if (customer.address.isNotEmpty) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          customer.address,
                          style: TextStyle(color: Colors.grey.shade800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // ── Row 3: Page, Suchi + Due amount ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.menu_book,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('পৃষ্ঠা: ${customer.pageNo}'),
                        const SizedBox(width: 12),
                        const Icon(Icons.list_alt,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('সূচি: ${customer.suchiNo}'),
                      ],
                    ),

                    // ── Due amount badge (tap → go to transactions to record payment) ──
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TransactionScreen(customer: customer),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: hasDue
                              ? Colors.red.shade600
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              hasDue
                                  ? Icons.warning_amber_rounded
                                  : Icons.check_circle_outline,
                              size: 13,
                              color:
                                  hasDue ? Colors.white : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              hasDue
                                  ? 'বাকি: ৳${_toBengali(customer.dueAmount.toStringAsFixed(0))}'
                                  : 'বাকি নেই',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: hasDue
                                    ? Colors.white
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // ── Aging badge and Collection List button ──
                if (hasDue) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (agingDays >= 1)
                        _buildAgingBadge(agingDays)
                      else
                        const SizedBox.shrink(),
                      Consumer<CollectionProvider>(
                        builder: (context, collectionProvider, child) {
                          final inCollection = collectionProvider.isInCollection(customer.id!);
                          return InkWell(
                            onTap: () async {
                              if (inCollection) {
                                await collectionProvider.removeFromCollection(customer.id!);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('আদায় লিস্ট থেকে সরানো হয়েছে'), duration: Duration(seconds: 1)),
                                  );
                                }
                              } else {
                                await collectionProvider.addToCollection(customer.id!);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('আদায় লিস্টে যোগ করা হয়েছে'), duration: Duration(seconds: 1)),
                                  );
                                }
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: inCollection ? Colors.grey.shade100 : Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: inCollection ? Colors.grey.shade400 : Colors.blue.shade200,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    inCollection ? Icons.playlist_add_check : Icons.playlist_add,
                                    size: 16,
                                    color: inCollection ? Colors.grey.shade700 : Colors.blue.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    inCollection ? 'লিস্টে আছে' : 'আদায় লিস্টে +',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: inCollection ? Colors.grey.shade700 : Colors.blue.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
