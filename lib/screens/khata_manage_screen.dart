import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/customer_provider.dart';

class KhataManageScreen extends StatelessWidget {
  const KhataManageScreen({super.key});

  void _showAddKhataDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('নতুন খাতা যোগ করুন'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'খাতার নাম বা নম্বর (যেমন: খাতা ১)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('বাতিল'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  Provider.of<CustomerProvider>(context, listen: false)
                      .addKhata(controller.text);
                  Navigator.pop(context);
                }
              },
              child: const Text('সংরক্ষণ'),
            ),
          ],
        );
      },
    );
  }

  void _showEditKhataDialog(BuildContext context, dynamic khata) {
    final TextEditingController controller = TextEditingController(text: khata.name);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('খাতা সম্পাদনা করুন'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'খাতার নতুন নাম (যেমন: খাতা ১)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('বাতিল'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  final provider = Provider.of<CustomerProvider>(context, listen: false);
                  final oldName = khata.name;
                  khata.name = controller.text;
                  provider.updateKhata(khata, oldName);
                  Navigator.pop(context);
                }
              },
              child: const Text('আপডেট করুন'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('খাতা ম্যানেজমেন্ট'),
        backgroundColor: Colors.green.shade800,
      ),
      body: Consumer<CustomerProvider>(
        builder: (context, provider, child) {
          if (provider.khatas.isEmpty) {
            return const Center(child: Text('কোনো খাতা যোগ করা হয়নি'));
          }

          return ListView.builder(
            itemCount: provider.khatas.length,
            itemBuilder: (context, index) {
              final khata = provider.khatas[index];
              return ListTile(
                leading: const Icon(Icons.book, color: Colors.green),
                title: Text(khata.name, style: const TextStyle(fontSize: 18)),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    _showEditKhataDialog(context, khata);
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green.shade600,
        onPressed: () => _showAddKhataDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
