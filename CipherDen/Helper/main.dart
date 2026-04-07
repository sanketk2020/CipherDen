import 'package:flutter/material.dart';
import 'package:iplus_flutter/utils/app_navigator.dart';
import 'package:iplus_flutter/utils/channels_registration.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ChannelsRegistration.registerHandlers();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: AppNavigator.navigatorKey,
      home: const SizedBox.shrink(),
    );
  }
}
