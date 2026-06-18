import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/transaction.dart';
import '../utils/app_utils.dart';

class TransactionTile extends StatelessWidget {
  final AppTransaction transaction;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;
  final String? customerMobile;
  final double? customerDueAmount;

  const TransactionTile({
    super.key,
    required this.transaction,
    required this.onDelete,
    this.onEdit,
    this.customerMobile,
    this.customerDueAmount,
  });

  String _toBengali(String input) {
    const bengaliDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    return input.replaceAllMapped(RegExp(r'[0-9]'), (match) {
      return bengaliDigits[int.parse(match.group(0)!)];
    });
  }

  Future<void> _sendSms(BuildContext context) async {
    if (customerMobile == null || customerMobile!.isEmpty || customerDueAmount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('কাস্টমারের মোবাইল নম্বর পাওয়া যায়নি')),
      );
      return;
    }

    final currentDue = customerDueAmount!;
    final isSale = transaction.type == 'sale';

    // Back-calculate previous due from current due
    // If this was a sale: currentDue = previousDue + saleAmount → previousDue = currentDue - saleAmount
    // If this was a payment: currentDue = previousDue - paymentAmount → previousDue = currentDue + paymentAmount
    final double previousDue = isSale
        ? currentDue - transaction.amount
        : currentDue + transaction.amount;

    final parts = <String>[
      'সম্মানিত গ্রাহক, আপনার',
      if (previousDue != 0)
        'পূর্বের বকেয়া ৳${_toBengali(previousDue.toStringAsFixed(0))}',
      if (isSale)
        'আজকের কেনা ৳${_toBengali(transaction.amount.toStringAsFixed(0))}',
      if (!isSale)
        'জমা ৳${_toBengali(transaction.amount.toStringAsFixed(0))}',
      'অবশিষ্ট বকেয়া ৳${_toBengali(currentDue.toStringAsFixed(0))}।',
      'অনুগ্রহ করে বকেয়া পরিশোধ করুন।',
      '',
      'ধন্যবাদান্তে,',
      'মেসার্স শুকরিয়া স্টোর',
      'বালিয়াডাঙ্গা বাজার',
    ];
    final message = parts.join('\n');

    final phoneNumber = AppUtils.formatPhoneNumber(customerMobile!);
    final smsUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      queryParameters: {'body': message},
    );

    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('মেসেজ অ্যাপ ওপেন করা যায়নি')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSale = transaction.type == 'sale';
    final color = isSale ? Colors.red.shade600 : Colors.green.shade600;
    final icon = isSale ? Icons.arrow_downward : Icons.arrow_upward;
    final typeText = isSale ? 'বাকি বিক্রি' : 'জমা/পেমেন্ট';
    final theme = Theme.of(context);

    return Dismissible(
      key: Key('tx_${transaction.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('নিশ্চিত করুন'),
            content: const Text('এই লেনদেন মুছে ফেলতে চান?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('না'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('হ্যাঁ'),
              ),
            ],
          ),
        );
        if (confirm == true) {
          onDelete();
        }
        return false;
      },
      onDismissed: (direction) {},
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          typeText,
          style: theme.textTheme.titleMedium?.copyWith(fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              '${AppUtils.toBengali(DateFormat('hh:mm a').format(transaction.date))} • ${transaction.paymentMethod}',
              style: theme.textTheme.bodySmall,
            ),
            if (transaction.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                transaction.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.black87,
                ),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '৳${AppUtils.toBengali(transaction.amount.toStringAsFixed(0))}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (customerMobile != null && customerMobile!.isNotEmpty) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.sms_outlined, size: 20, color: Colors.teal),
                tooltip: 'মেসেজ পাঠান',
                onPressed: () => _sendSms(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
            if (onEdit != null) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blueGrey),
                onPressed: onEdit,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
