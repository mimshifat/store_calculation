import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:workmanager/workmanager.dart';
import 'services/telegram_service.dart';
import 'providers/customer_provider.dart';
import 'providers/cash_provider.dart';
import 'providers/supplier_provider.dart';
import 'providers/report_provider.dart';
import 'providers/bank_provider.dart';
import 'providers/collection_provider.dart';
import 'screens/home_screen.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final telegramService = TelegramService.instance;
    if (await telegramService.shouldBackupNow()) {
      await telegramService.backupDatabase();
    }
    return Future.value(true);
  });
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  Workmanager().initialize(
    callbackDispatcher,
  );
  
  Workmanager().registerPeriodicTask(
    "backup-task",
    "telegramBackup",
    frequency: const Duration(hours: 24),
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => CashProvider()),
        ChangeNotifierProvider(create: (_) => SupplierProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => BankProvider()),
        ChangeNotifierProvider(create: (_) => CollectionProvider()),
      ],
      child: const ShukriyaStoreApp(),
    ),
  );
}

class ShukriyaStoreApp extends StatelessWidget {
  const ShukriyaStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'শুকরিয়া স্টোর',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green.shade800,
          primary: Colors.green.shade800,
          secondary: Colors.amber.shade700,
          surface: Colors.white,
          error: Colors.red.shade700,
        ),
        scaffoldBackgroundColor: Colors.grey.shade50,
        useMaterial3: true,
        textTheme: GoogleFonts.notoSansBengaliTextTheme(
          Theme.of(context).textTheme,
        ).copyWith(
          displayLarge: GoogleFonts.notoSansBengali(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
          headlineMedium: GoogleFonts.notoSansBengali(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
          titleLarge: GoogleFonts.notoSansBengali(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
          titleMedium: GoogleFonts.notoSansBengali(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
          bodyLarge: GoogleFonts.notoSansBengali(fontSize: 15, color: Colors.black87),
          bodyMedium: GoogleFonts.notoSansBengali(fontSize: 14, color: Colors.black87),
          bodySmall: GoogleFonts.notoSansBengali(fontSize: 13, color: Colors.black54),
          labelSmall: GoogleFonts.notoSansBengali(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black54),
        ),
        appBarTheme: AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: Colors.green.shade800,
          foregroundColor: Colors.white,
          titleTextStyle: GoogleFonts.notoSansBengali(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        cardTheme: const CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          color: Colors.white,
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('bn', 'BD'),
        Locale('en', 'US'),
      ],
      home: const HomeScreen(),
    );
  }
}
