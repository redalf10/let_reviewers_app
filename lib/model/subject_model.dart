import 'package:flutter/material.dart';

class Subject {
  final String name;
  final int totalParts;
  final List<Color> gradientColors;

  const Subject({
    required this.name,
    required this.totalParts,
    required this.gradientColors,
  });
}
