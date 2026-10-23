import 'package:flutter/material.dart';

class SubjectContainer extends StatelessWidget {
  final String subjectName;
  final String subjectDescription;
  final String imagePath;
  final List<Color> color;
  final double? height;
  final double? width;

  const SubjectContainer({
    super.key,
    required this.subjectName,
    required this.subjectDescription,
    required this.imagePath,
    required this.color,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: width ?? double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: color,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        subjectName,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      if (subjectDescription.isNotEmpty)
                        Text(
                          subjectDescription,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.8),
                            fontFamily: 'Poppins',
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: -30,
          right: -10,
          child: Image.asset(
            imagePath,
            width: 100,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.error, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
