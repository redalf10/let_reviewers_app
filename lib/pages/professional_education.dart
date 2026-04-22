import 'package:flutter/material.dart';
import 'package:jaa_reviewer/pages/components/subject_container.dart';

class ProfessionalEducationPage extends StatelessWidget {
  const ProfessionalEducationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Professional Education',
            style: TextStyle(
                color: Colors.blueAccent,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_circle_left_outlined,
            color: Colors.blueAccent,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: const SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            children: [
              SizedBox(height: 20),
              SubjectContainer(
                subjectName: 'Pedagogical Principles',
                subjectDescription: '',
                imagePath:
                    'assets/hot-air-balloon-cartoon-sticker-free-vector-removebg-preview.png',
                color: [Colors.blueAccent, Colors.lightBlueAccent],
              ),
              SizedBox(height: 30),
              SubjectContainer(
                subjectName: 'Curriculum Development',
                subjectDescription: '',
                imagePath:
                    'assets/hot-air-balloon-cartoon-sticker-free-vector-removebg-preview.png',
                color: [Colors.blueAccent, Colors.lightBlueAccent],
              ),
              SizedBox(height: 30),
              SubjectContainer(
                subjectName: 'Classroom Management',
                subjectDescription: '',
                imagePath:
                    'assets/hot-air-balloon-cartoon-sticker-free-vector-removebg-preview.png',
                color: [Colors.blueAccent, Colors.lightBlueAccent],
              ),
              SizedBox(height: 30),
              SubjectContainer(
                subjectName: 'Assessment',
                subjectDescription: '',
                imagePath:
                    'assets/hot-air-balloon-cartoon-sticker-free-vector-removebg-preview.png',
                color: [Colors.blueAccent, Colors.lightBlueAccent],
              ),
              SizedBox(height: 30),
              SubjectContainer(
                subjectName: 'Educational Philosophies',
                subjectDescription: '',
                imagePath:
                    'assets/hot-air-balloon-cartoon-sticker-free-vector-removebg-preview.png',
                color: [Colors.blueAccent, Colors.lightBlueAccent],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
