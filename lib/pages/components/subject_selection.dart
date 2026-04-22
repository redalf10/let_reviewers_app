import 'package:flutter/material.dart';
import 'package:jaa_reviewer/pages/components/subject_container.dart';
import 'package:jaa_reviewer/services/pdf_viewer.dart';

class SubjectSelectionScreen extends StatelessWidget {
  final String subjectName;
  final List<Color> gradientColors;
  final int totalParts; // Add this field

  const SubjectSelectionScreen({
    super.key,
    required this.subjectName,
    required this.gradientColors,
    required this.totalParts, // Initialize this
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(subjectName,
            style: const TextStyle(
                color: Colors.pinkAccent,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_circle_left_outlined,
            color: Colors.pinkAccent,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: totalParts, // Use the dynamic count
        itemBuilder: (context, index) {
          final partNumber = index + 1;
          return Padding(
            padding: const EdgeInsets.only(bottom: 30),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PDFViewerScreen(
                      subjectName: subjectName,
                      partNumber: partNumber,
                      totalParts: totalParts,
                    ),
                  ),
                );
              },
              child: SubjectContainer(
                subjectName: 'Part $partNumber',
                subjectDescription: '',
                imagePath: 'assets/book.png',
                color: gradientColors,
              ),
            ),
          );
        },
      ),
    );
  }
}
