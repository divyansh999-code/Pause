import 'package:flutter/material.dart';
import 'package:pause/core/theme.dart';
import 'package:pause/screens/home_screen.dart';

class PauseApp extends StatelessWidget {
  const PauseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pause',
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
