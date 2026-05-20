import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' show join;
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../database/database_helper.dart';

class BackupService {
  static const String _dbName = 'shukriya_store.db';

  /// Backup the database file using SharePlus so the user can save it anywhere.
  static Future<bool> backupDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, _dbName);
      
      final file = File(path);
      if (await file.exists()) {
        // Share the file so the user can save to Drive, Downloads, etc.
        await Share.shareXFiles([XFile(path)], text: 'Shukriya Store Database Backup');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Backup Error: $e');
      return false;
    }
  }

  /// Restore the database file by picking a file from the device.
  static Future<bool> restoreDatabase() async {
    try {
      // Pick the backup file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any, // Allow any to ensure they can select the .db file
      );

      if (result != null && result.files.single.path != null) {
        final backupFilePath = result.files.single.path!;
        final backupFile = File(backupFilePath);
        
        // Ensure it's not empty and exists
          // Check if it's a valid SQLite database by checking the first 16 bytes
          final header = await backupFile.openRead(0, 16).first;
          final isSqlite = String.fromCharCodes(header).contains('SQLite format 3');
          if (!isSqlite) {
            debugPrint('Restore Error: Invalid SQLite file');
            return false;
          }

          // Close the current database connection before overwriting
          await DatabaseHelper.instance.close();

          final dbPath = await getDatabasesPath();
          final path = join(dbPath, _dbName);
          
          // Overwrite the current database with the backup
          await backupFile.copy(path);
          
          return true;
      }
      return false;
    } catch (e) {
      debugPrint('Restore Error: $e');
      return false;
    }
  }
}
