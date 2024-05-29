// ignore_for_file: prefer_const_constructors, library_private_types_in_public_api

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:taxaero/language/language_preferences.dart';
import 'package:taxaero/pages/authantification/login_page.dart';
import 'package:taxaero/pages/authantification/main_page.dart';
import 'package:taxaero/pages/detail_page.dart';
import 'package:taxaero/pages/home_page.dart';
import 'package:taxaero/pages/intro/Intro.dart';
import 'package:taxaero/pages/mainpage.dart';
import 'package:taxaero/pages/scan_page.dart';
import 'package:taxaero/pages/settings_page.dart';
import 'package:taxaero/theme/theme_provider.dart';
import 'package:permission_handler/permission_handler.dart';

// Add this line

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.bluetooth.request();
  await Permission.location.request();

  SharedPreferences prefs = await SharedPreferences.getInstance();

  String? savedLanguage = prefs.getString('language');

  var delegate = await LocalizationDelegate.create(
    fallbackLocale: 'en_US',
    supportedLocales: [
      'en_US',
      'fr',
    ],
    preferences: TranslatePreferences(savedLanguage),
  );

  runApp(
    ChangeNotifierProvider<ThemeProvider>(
      create: (context) => ThemeProvider()..initializeTheme(),
      child: LocalizedApp(
        delegate,
        const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    var localizationDelegate = LocalizedApp.of(context).delegate;
    return LocalizationProvider(
      state: LocalizationProvider.of(context).state,
      child: Consumer<ThemeProvider>(
        builder: (context, provider, child) {
          return MaterialApp(
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              DefaultCupertinoLocalizations.delegate,
            ],
            supportedLocales: localizationDelegate.supportedLocales,
            locale: localizationDelegate.currentLocale,
            theme: provider.themeData,
            debugShowCheckedModeBanner: false,
            initialRoute: '/',
            routes: {
              '/': (context) => AuthVerification(),
              '/intro': (context) => Intro(),
              '/home': (context) => HomePage(),
              '/scan': (context) => ScanPage(),
              '/user': (context) => SettingsPage(),
              '/main': (context) => MainPage(),
              '/detail': (context) => DetailPage(numero: '', date: '', amount: 0, taxateur: '', parking: '',),
              '/authent': (context) => LoginPage()
            },
          );
        },
      ),
    );
  }
}
