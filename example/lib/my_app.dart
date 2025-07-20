import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haishin_kit_example/screen_view.dart';
import 'package:haishin_kit_example/setting_screen.dart';

import 'app_controller.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _selectedIndex = 0;


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildScreenView() {
    return const ScreenView();
  }

  Widget _buildSettingView() {
    return const SettingScreen();
  }

@override
  void initState() {
    super.initState();
    Get.put(AppController());
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: _selectedIndex == 0 ? _buildScreenView() : _buildSettingView(),
        bottomNavigationBar: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.tv),
              label: 'ScreenView',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Setting',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
