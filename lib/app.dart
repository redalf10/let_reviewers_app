import 'package:flutter/material.dart';
import 'package:jaa_reviewer/splashscreen.dart';

class JaaApp extends StatelessWidget {
  const JaaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}
