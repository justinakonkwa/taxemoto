// ignore_for_file: prefer_const_constructors

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:taxaero/pages/history_page.dart';
import 'package:taxaero/pages/home_page.dart';
import 'package:taxaero/pages/scan_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int currentIndex = 0;

  final List<Widget> _widgetOptions = <Widget>[
    HomePage(),
    ScanPage(),
    HistoryPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(currentIndex),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Theme.of(context).colorScheme.background,
          selectedItemColor: Theme.of(context).colorScheme.onBackground,
          elevation: 0,
          showSelectedLabels: true,
          showUnselectedLabels: false,
          unselectedIconTheme: IconThemeData(color: Colors.grey),
          currentIndex: currentIndex,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(
                CupertinoIcons.house_alt,
              ),
              label: ('Home'),
            ),
            BottomNavigationBarItem(
              icon: Icon(
                CupertinoIcons.qrcode,
              ),
              label: ('Qr code'),
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.turned_in_not,
              ),
              label: ('History'),
            ),
          ],
          onTap: (index) {
            setState(
              () {
                currentIndex = index;
              },
            );
          },
        ),
      ),
    );
  }
}
