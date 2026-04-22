// import 'package:flutter/material.dart';
// import 'package:jaa_reviewer/pages/components/subject_container.dart';
// import 'package:jaa_reviewer/pages/services/pdf_viewer.dart';

// class EnglishPage extends StatelessWidget {
//   const EnglishPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'English',
//           style: TextStyle(
//             color: Colors.pinkAccent,
//             fontFamily: 'Poppins',
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         leading: IconButton(
//           icon: const Icon(
//             Icons.arrow_circle_left_outlined,
//             color: Colors.pinkAccent,
//           ),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 'COVERAGE',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                   fontFamily: 'Poppins',
//                 ),
//               ),
//               const Text(
//                 'English for Specific Purposes; Introduction to Linguistics; Structure of English; Introduction to Stylistics; Literary Criticism; Literature; Mythology and Folklore; Afro-Asian Literature; English and American Literature; The Teaching of Speaking; Listening and Reading; Teaching of Literature; Preparation and Evaluation of Instructional Materials; Language and Literature Assessment; Language Research; Campus Journalism; Translation and Editing of Text; Speech and Stage Arts; Creative Writing.',
//                 style: TextStyle(
//                   fontSize: 12,
//                   fontFamily: 'Poppins',
//                   color: Colors.grey,
//                 ),
//                 textAlign: TextAlign.justify,
//               ),
//               SizedBox(height: 20),
//               InkWell(
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const PDFViewerScreen(
//                         pdfPath: 'assets/Part 1 English www.teachpinas.com.pdf',
//                       ),
//                     ),
//                   );
//                 },
//                 child: SubjectContainer(
//                   subjectName: 'Part 1',
//                   subjectDescription: '',
//                   imagePath: 'assets/book.png',
//                   color: [Colors.pinkAccent, Colors.orangeAccent],
//                 ),
//               ),
//               SizedBox(height: 30),
//               SubjectContainer(
//                 subjectName: 'Part 2',
//                 subjectDescription: '',
//                 imagePath: 'assets/book.png',
//                 color: [Colors.pinkAccent, Colors.orangeAccent],
//               ),
//               SizedBox(height: 30),
//               SubjectContainer(
//                 subjectName: 'Part 3',
//                 subjectDescription: '',
//                 imagePath: 'assets/book.png',
//                 color: [Colors.pinkAccent, Colors.orangeAccent],
//               ),
//               SizedBox(height: 30),
//               SubjectContainer(
//                 subjectName: 'Part 4',
//                 subjectDescription: '',
//                 imagePath: 'assets/book.png',
//                 color: [Colors.pinkAccent, Colors.orangeAccent],
//               ),
//               SizedBox(height: 30),
//               SubjectContainer(
//                 subjectName: 'Part 5',
//                 subjectDescription: '',
//                 imagePath: 'assets/book.png',
//                 color: [Colors.pinkAccent, Colors.orangeAccent],
//               ),
//               SizedBox(height: 30),
//               SubjectContainer(
//                 subjectName: 'Part 6',
//                 subjectDescription: '',
//                 imagePath: 'assets/book.png',
//                 color: [Colors.pinkAccent, Colors.orangeAccent],
//               ),
//               SizedBox(height: 30),
//               SubjectContainer(
//                 subjectName: 'Part 7',
//                 subjectDescription: '',
//                 imagePath: 'assets/book.png',
//                 color: [Colors.pinkAccent, Colors.orangeAccent],
//               ),
//               SubjectContainer(
//                 subjectName: 'Part 8',
//                 subjectDescription: '',
//                 imagePath: 'assets/book.png',
//                 color: [Colors.pinkAccent, Colors.orangeAccent],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
