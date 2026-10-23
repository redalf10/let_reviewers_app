// quiz_review_page.dart
import 'package:flutter/material.dart';
import 'package:jaa_reviewer/services/quiz.dart';

class QuizReviewPage extends StatefulWidget {
  final QuizResult result;

  const QuizReviewPage({super.key, required this.result});

  @override
  State<QuizReviewPage> createState() => _QuizReviewPageState();
}

class _QuizReviewPageState extends State<QuizReviewPage> {
  int currentQuestionIndex = 0;
  String filterType = 'All'; // All, Correct, Incorrect

  List<QuizAnswer> get filteredAnswers {
    switch (filterType) {
      case 'Correct':
        return widget.result.answers
            .where((answer) => answer.isCorrect)
            .toList();
      case 'Incorrect':
        return widget.result.answers
            .where((answer) => !answer.isCorrect)
            .toList();
      default:
        return widget.result.answers;
    }
  }

  @override
  Widget build(BuildContext context) {
    final answers = filteredAnswers;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Review Answers',
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
                filterType = value;
                currentQuestionIndex = 0;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All', child: Text('All Questions')),
              const PopupMenuItem(
                  value: 'Correct', child: Text('Correct Only')),
              const PopupMenuItem(
                  value: 'Incorrect', child: Text('Incorrect Only')),
            ],
          ),
        ],
      ),
      body: answers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    filterType == 'Correct' ? Icons.check_circle : Icons.cancel,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    filterType == 'Correct'
                        ? 'No correct answers found'
                        : 'No incorrect answers found',
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Header with stats
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: widget.result.percentage >= 70
                          ? [Colors.green[400]!, Colors.green[600]!]
                          : [Colors.red[400]!, Colors.red[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('Score',
                              '${widget.result.score}/${widget.result.totalQuestions}'),
                          _buildStatItem('Percentage',
                              '${widget.result.percentage.toStringAsFixed(1)}%'),
                          _buildStatItem('Time', widget.result.duration),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${widget.result.subjectName} - Part ${widget.result.partNumber}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // Navigation header
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Question ${currentQuestionIndex + 1} of ${answers.length}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: currentQuestionIndex > 0
                                ? () => setState(() => currentQuestionIndex--)
                                : null,
                            icon: const Icon(Icons.arrow_back_ios, size: 20),
                            color: Colors.pinkAccent,
                          ),
                          IconButton(
                            onPressed: currentQuestionIndex < answers.length - 1
                                ? () => setState(() => currentQuestionIndex++)
                                : null,
                            icon: const Icon(Icons.arrow_forward_ios, size: 20),
                            color: Colors.pinkAccent,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Question content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _buildQuestionCard(answers[currentQuestionIndex]),
                  ),
                ),

                // Bottom navigation
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: currentQuestionIndex > 0
                              ? () => setState(() => currentQuestionIndex--)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.grey[700],
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Previous'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: currentQuestionIndex < answers.length - 1
                              ? () => setState(() => currentQuestionIndex++)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pinkAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Next'),
                        ),
                      ),
                    ],
                  ),
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
            fontSize: 20,
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

  Widget _buildQuestionCard(QuizAnswer answer) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question number and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.pinkAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Question ${answer.questionNumber}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.pinkAccent,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: answer.isCorrect ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        answer.isCorrect ? Icons.check : Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        answer.isCorrect ? 'Correct' : 'Incorrect',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Question text
            Text(
              answer.question,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // User's answer
            _buildAnswerSection(
              'Your Answer',
              answer.userAnswer,
              answer.isCorrect ? Colors.green : Colors.red,
              answer.isCorrect ? Icons.check_circle : Icons.cancel,
            ),
            const SizedBox(height: 16),

            // Correct answer (if user was wrong)
            if (!answer.isCorrect)
              _buildAnswerSection(
                'Correct Answer',
                answer.correctAnswer,
                Colors.green,
                Icons.check_circle,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerSection(
      String title, String answer, Color color, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
