// quiz_history_page.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:jaa_reviewer/pages/components/quiz_review.dart';
import 'package:jaa_reviewer/services/quiz.dart';
import 'package:path_provider/path_provider.dart';

class QuizHistoryPage extends StatefulWidget {
  const QuizHistoryPage({super.key});

  @override
  State<QuizHistoryPage> createState() => _QuizHistoryPageState();
}

class _QuizHistoryPageState extends State<QuizHistoryPage> {
  List<QuizResult> history = [];
  bool isLoading = true;
  String filterSubject = 'All';
  List<String> subjects = ['All'];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/quiz_history.json');

      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final List<dynamic> historyJson = json.decode(jsonString);
        final loadedHistory =
            historyJson.map((h) => QuizResult.fromJson(h)).toList();

        // Sort by date (newest first)
        loadedHistory.sort((a, b) => b.date.compareTo(a.date));

        // Get unique subjects
        final subjectSet = <String>{'All'};
        for (final result in loadedHistory) {
          subjectSet.add(result.subjectName);
        }

        setState(() {
          history = loadedHistory;
          subjects = subjectSet.toList();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint('Error loading history: $e');
    }
  }

  List<QuizResult> get filteredHistory {
    if (filterSubject == 'All') {
      return history;
    }
    return history
        .where((result) => result.subjectName == filterSubject)
        .toList();
  }

  Future<void> _deleteResult(QuizResult result) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/quiz_history.json');

      history.remove(result);
      await file
          .writeAsString(json.encode(history.map((h) => h.toJson()).toList()));

      // Update subjects list
      final subjectSet = <String>{'All'};
      for (final result in history) {
        subjectSet.add(result.subjectName);
      }

      setState(() {
        subjects = subjectSet.toList();
        if (!subjects.contains(filterSubject)) {
          filterSubject = 'All';
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quiz result deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting result: $e')),
      );
    }
  }

  void _showDeleteDialog(QuizResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Result'),
        content:
            const Text('Are you sure you want to delete this quiz result?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteResult(result);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(QuizResult result) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${result.subjectName} - Part ${result.partNumber}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.pinkAccent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(result.date),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  onSelected: (value) {
                    if (value == 'review') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuizReviewPage(result: result),
                        ),
                      );
                    } else if (value == 'delete') {
                      _showDeleteDialog(result);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'review',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Review Answers'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Score display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: result.percentage >= 70
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: result.percentage >= 70
                      ? Colors.green.withOpacity(0.3)
                      : Colors.red.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        result.percentage >= 80
                            ? Icons.star
                            : result.percentage >= 60
                                ? Icons.star_half
                                : Icons.star_border,
                        color: result.percentage >= 80
                            ? Colors.amber
                            : result.percentage >= 60
                                ? Colors.orange
                                : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Score: ${result.score}/${result.totalQuestions}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${result.percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color:
                          result.percentage >= 70 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Duration
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.grey, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Duration: ${result.duration}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Quiz History',
          style: TextStyle(
            color: Colors.pinkAccent,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.pinkAccent),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.pinkAccent),
            onSelected: (value) {
              setState(() {
                filterSubject = value;
              });
            },
            itemBuilder: (context) => subjects
                .map((subject) => PopupMenuItem(
                      value: subject,
                      child: Text(subject),
                    ))
                .toList(),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.pinkAccent))
          : filteredHistory.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No quiz history found',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Statistics Card
                    if (filteredHistory.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.pinkAccent, Colors.pink],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem('Total Quizzes',
                                filteredHistory.length.toString()),
                            _buildStatItem('Average Score',
                                '${(filteredHistory.fold(0.0, (sum, result) => sum + result.percentage) / filteredHistory.length).toStringAsFixed(1)}%'),
                            _buildStatItem('Best Score',
                                '${filteredHistory.map((r) => r.percentage).reduce((a, b) => a > b ? a : b).toStringAsFixed(1)}%'),
                          ],
                        ),
                      ),

                    // History List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredHistory.length,
                        itemBuilder: (context, index) {
                          final result = filteredHistory[index];
                          return _buildHistoryCard(result);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
