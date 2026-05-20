import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class TelegramService {
  static final TelegramService instance = TelegramService._init();
  
  TelegramService._init();

  Future<bool> isConfigured() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('telegram_bot_token');
    final chatId = prefs.getString('telegram_chat_id');
    return token != null && token.isNotEmpty && chatId != null && chatId.isNotEmpty;
  }

  Future<void> saveConfig(String token, String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('telegram_bot_token', token.trim());
    await prefs.setString('telegram_chat_id', chatId.trim());
  }
  
  Future<Map<String, String?>> getConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'token': prefs.getString('telegram_bot_token'),
      'chatId': prefs.getString('telegram_chat_id'),
    };
  }

  /// Sends the database file to Telegram.
  /// Returns a success message ('success') or an error message (worst case handling).
  Future<String> backupDatabase() async {
    try {
      final config = await getConfig();
      final token = config['token'];
      final chatId = config['chatId'];

      if (token == null || token.isEmpty || chatId == null || chatId.isEmpty) {
        return "টেলিগ্রাম বট কনফিগার করা নেই। সেটিংস থেকে টোকেন এবং চ্যাট আইডি দিন।";
      }

      final dbPath = await getDatabasesPath();
      final path = p.join(dbPath, 'shukriya_store.db');
      final file = File(path);
      
      if (!await file.exists()) {
        return "ডাটাবেস ফাইল পাওয়া যায়নি।";
      }

      final dateStr = DateTime.now().toIso8601String().split('T')[0];
      final fileName = 'shukriya_store_backup_$dateStr.db';

      final uri = Uri.parse('https://api.telegram.org/bot$token/sendDocument');
      var request = http.MultipartRequest('POST', uri)
        ..fields['chat_id'] = chatId
        ..fields['caption'] = 'Shukriya Store Backup: $dateStr'
        ..files.add(await http.MultipartFile.fromPath('document', file.path, filename: fileName));

      final response = await request.send();

      if (response.statusCode == 200) {
        // Update last backup date on success
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_telegram_backup_date', DateTime.now().toIso8601String());
        return "success";
      } else {
        final respStr = await response.stream.bytesToString();
        debugPrint("Telegram API Error: ${response.statusCode} - $respStr");
        if (response.statusCode == 401 || response.statusCode == 404) {
          return "Bot Token সঠিক নয়।";
        } else if (response.statusCode == 400) {
          return "Chat ID সঠিক নয় বা বটটি আপনার চ্যাটে অ্যাড করা হয়নি।";
        }
        return "সার্ভার এরর: ${response.statusCode}";
      }
    } on SocketException catch (_) {
      return "ইন্টারনেট কানেকশন নেই।";
    } catch (e) {
      debugPrint("Backup Exception: $e");
      return "অপ্রত্যাশিত সমস্যা: ${e.toString()}";
    }
  }

  Future<bool> shouldBackupNow() async {
    if (!await isConfigured()) return false; // Don't trigger if not configured

    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString('last_telegram_backup_date');
    if (dateStr == null) return true; // never backed up
    
    final lastBackup = DateTime.tryParse(dateStr);
    if (lastBackup == null) return true;
    
    final diff = DateTime.now().difference(lastBackup).inDays;
    return diff >= 1;
  }
}
