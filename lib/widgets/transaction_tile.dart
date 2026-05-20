import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../utils/app_utils.dart';

class TransactionTile extends StatelessWidget {
  final AppTransaction transaction;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;

  const TransactionTile({
    super.key,
    required this.transaction,
    required this.onDelete,
    this.onEdit,
  });

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
            if (onEdit != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blueGrey),
                onPressed: onEdit,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
