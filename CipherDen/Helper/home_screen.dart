import 'package:flutter/material.dart';
import 'package:iplus_flutter/utils/app_navigator.dart';
import 'package:iplus_flutter/settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Home')),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              AppNavigator.push(const SettingsScreen());
            },
            child: const Text('Go To Settings'),
          ),
        ),
      ),
    );
  }
}
