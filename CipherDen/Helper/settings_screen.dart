import 'package:flutter/material.dart';
import 'package:iplus_flutter/utils/app_navigator.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Settings')),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              AppNavigator.popToNative();
            },
            child: const Text('Go Back'),
          ),
        ),
      ),
    );
  }
}
