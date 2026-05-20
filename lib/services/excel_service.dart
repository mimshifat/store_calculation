import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/customer.dart';

class ExcelService {

  static Future<List<Customer>?> importExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null) {
        var file = result.files.single.path!;
        var bytes = File(file).readAsBytesSync();
        var excel = Excel.decodeBytes(bytes);

        List<Customer> importedCustomers = [];

        for (var table in excel.tables.keys) {
          var rows = excel.tables[table]?.rows;
          if (rows == null || rows.isEmpty) continue;

          // Skip header row (index 0)
          for (int i = 1; i < rows.length; i++) {
            var row = rows[i];

            // Expected Format:
            // 0: নাম, 1: পৃষ্ঠা নং, 2: খাতা নং, 3: সূচি ক্র: নং, 4: মোবাইল

            if (row[0]?.value == null && row[4]?.value == null) continue;

            String name = row[0]?.value?.toString() ?? '';
            String pageNo = row[1]?.value?.toString() ?? '';
            String khataNo = row[2]?.value?.toString() ?? '';
            String suchiNo = row[3]?.value?.toString() ?? '';
            String mobile = row[4]?.value?.toString() ?? '';
            String address = row[5]?.value?.toString() ?? '';
            double dueAmount = double.tryParse(row[6]?.value?.toString() ?? '0') ?? 0.0;

            importedCustomers.add(Customer(
              name: name,
              pageNo: pageNo,
              khataNo: khataNo,
              suchiNo: suchiNo,
              mobile: mobile,
              address: address,
              dueAmount: dueAmount,
            ));
          }
        }
        return importedCustomers;
      }
    } catch (e) {
      debugPrint("Error importing Excel: $e");
    }
    return null;
  }

  static Future<bool> exportExcel(List<Customer> customers) async {
    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Customers'];
      excel.setDefaultSheet('Customers');

      // Add Headers
      sheetObject.appendRow([
        TextCellValue('নাম'),
        TextCellValue('পৃষ্ঠা নং'),
        TextCellValue('খাতা নং'),
        TextCellValue('সূচি ক্র: নং'),
        TextCellValue('মোবাইল'),
        TextCellValue('ঠিকানা'),
        TextCellValue('বাকি (৳)')
      ]);

      // Add Data
      for (var customer in customers) {
        sheetObject.appendRow([
          TextCellValue(customer.name),
          TextCellValue(customer.pageNo),
          TextCellValue(customer.khataNo),
          TextCellValue(customer.suchiNo),
          TextCellValue(customer.mobile),
          TextCellValue(customer.address),
          DoubleCellValue(customer.dueAmount),
        ]);
      }

      // Save to temporary directory and share
      final dir = await getTemporaryDirectory();
      final path = "${dir.path}/shukriya_customers.xlsx";
      final file = File(path);

      final fileBytes = excel.encode();
      if (fileBytes != null) {
        await file.writeAsBytes(fileBytes);
        await Share.shareXFiles([XFile(path)], text: 'শুকরিয়া স্টোরের কাস্টমার তালিকা');
        return true;
      }
    } catch (e) {
      debugPrint("Error exporting Excel: $e");
    }
    return false;
  }
}
