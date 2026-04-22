// quiz_page.dart
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jaa_reviewer/pages/components/quiz_history.dart';
import 'package:jaa_reviewer/pages/components/quiz_review.dart';
import 'package:path_provider/path_provider.dart';

// quiz_models.dart

class QuizResult {
  final String subjectName;
  final int partNumber;
  final int score;
  final int totalQuestions;
  final double percentage;
  final DateTime date;
  final Duration timeTaken;
  final List<QuizAnswer> answers;

  QuizResult({
    required this.subjectName,
    required this.partNumber,
    required this.score,
    required this.totalQuestions,
    required this.percentage,
    required this.date,
    required this.timeTaken,
    required this.answers,
  });

  // For backward compatibility
  int get correctAnswers => score;
  String get duration =>
      '${timeTaken.inMinutes}:${(timeTaken.inSeconds % 60).toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {
        'subjectName': subjectName,
        'partNumber': partNumber,
        'score': score,
        'totalQuestions': totalQuestions,
        'percentage': percentage,
        'date': date.toIso8601String(),
        'timeTaken': timeTaken.inSeconds,
        'answers': answers.map((a) => a.toJson()).toList(),
      };

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      subjectName: json['subjectName'],
      partNumber: json['partNumber'] ?? 1,
      score: json['score'] ?? json['correctAnswers'] ?? 0,
      totalQuestions: json['totalQuestions'],
      percentage: (json['percentage'] as num).toDouble(),
      date: DateTime.parse(json['date']),
      timeTaken: Duration(
        seconds: json['timeTaken'] ?? 0,
      ),
      answers: (json['answers'] as List<dynamic>?)
              ?.map((a) => QuizAnswer.fromJson(a))
              .toList() ??
          [],
    );
  }
}

class QuizAnswer {
  final String question;
  final String userAnswer;
  final String correctAnswer;
  final bool isCorrect;
  final int questionNumber;

  QuizAnswer({
    required this.question,
    required this.userAnswer,
    required this.correctAnswer,
    required this.isCorrect,
    required this.questionNumber,
  });

  Map<String, dynamic> toJson() => {
        'question': question,
        'userAnswer': userAnswer,
        'correctAnswer': correctAnswer,
        'isCorrect': isCorrect,
        'questionNumber': questionNumber,
      };

  factory QuizAnswer.fromJson(Map<String, dynamic> json) => QuizAnswer(
        question: json['question'],
        userAnswer: json['userAnswer'],
        correctAnswer: json['correctAnswer'],
        isCorrect: json['isCorrect'],
        questionNumber: json['questionNumber'],
      );
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final String correctAnswer;
  final int questionNumber;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.questionNumber,
  });
}

class QuizPage extends StatefulWidget {
  final String subjectName;
  final int partNumber;

  const QuizPage({
    super.key,
    required this.subjectName,
    required this.partNumber,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> with TickerProviderStateMixin {
  List<QuizQuestion> questions = [];
  Map<int, String> userAnswers = {};
  int currentQuestionIndex = 0;
  bool isLoading = true;
  bool isQuizCompleted = false;
  DateTime? startTime;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadQuestions();
    startTime = DateTime.now();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    try {
      setState(() {
        isLoading = true;
      });

      // Load questions from JSON file
      final questionsData = await _loadQuestionsFromAssets();

      // Check if questions are available
      if (questionsData.isEmpty) {
        setState(() {
          isLoading = false;
        });
        _showNoQuizAvailableDialog();
        return;
      }

      final random = Random();

      // Shuffle and take 20 questions
      questionsData.shuffle(random);
      final selectedQuestions = questionsData.take(20).toList();

      setState(() {
        questions = selectedQuestions;
        isLoading = false;
      });

      _animationController.forward();
      _updateProgress();
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showNoQuizAvailableDialog();
    }
  }

  void _showNoQuizAvailableDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('No Quiz Available'),
          content: const Text(
            'There are no quizzes available for this subject right now. '
            'Please try another subject or part.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context).pop(); // Go back to previous screen
              },
            ),
          ],
        );
      },
    );
  }

  Future<List<QuizQuestion>> _loadQuestionsFromAssets() async {
    try {
      String jsonString;
      try {
        // Try to load the JSON file
        jsonString = await rootBundle.loadString(
          'assets/questions/Part ${widget.partNumber} ${widget.subjectName.replaceAll(' ', ' ')} www.teachpinas.com.json',
        );
      } catch (e) {
        // If file not found, try alternative path format
        try {
          jsonString = await rootBundle.loadString(
            'assets/questions/Part${widget.partNumber}_${widget.subjectName.replaceAll(' ', '_')}.json',
          );
        } catch (e) {
          // If still not found, return empty list
          return [];
        }
      }

      final List<dynamic> questionsJson = json.decode(jsonString);

      // Validate that we got valid questions
      if (questionsJson.isEmpty) return [];

      return questionsJson.map((q) {
        // Validate each question has required fields
        if (q['question'] == null ||
            q['options'] == null ||
            q['correctAnswer'] == null) {
          throw FormatException('Invalid question format');
        }

        return QuizQuestion(
          question: q['question'],
          options: List<String>.from(q['options']),
          correctAnswer: q['correctAnswer'],
          questionNumber: q['questionNumber'] ?? 0,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error loading questions: $e');
      return [];
    }
  }

  void _updateProgress() {
    final progress = (currentQuestionIndex + 1) / questions.length;
    _progressController.animateTo(progress);
  }

  void _selectAnswer(String answer) {
    setState(() {
      userAnswers[currentQuestionIndex] = answer;
    });

    // Auto-advance after selection with delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (currentQuestionIndex < questions.length - 1) {
        _nextQuestion();
      } else {
        _finishQuiz();
      }
    });
  }

  void _nextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
      });
      _animationController.reset();
      _animationController.forward();
      _updateProgress();
    }
  }

  void _previousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() {
        currentQuestionIndex--;
      });
      _animationController.reset();
      _animationController.forward();
      _updateProgress();
    }
  }

  void _finishQuiz() {
    setState(() {
      isQuizCompleted = true;
    });
    _calculateAndSaveResults();
  }

  void _calculateAndSaveResults() async {
    final endTime = DateTime.now();
    final timeTaken = endTime.difference(startTime!);

    int score = 0;
    List<QuizAnswer> quizAnswers = [];

    for (int i = 0; i < questions.length; i++) {
      final question = questions[i];
      final userAnswer = userAnswers[i] ?? '';
      final isCorrect = userAnswer == question.correctAnswer;

      if (isCorrect) score++;

      quizAnswers.add(QuizAnswer(
        question: question.question,
        userAnswer: userAnswer,
        correctAnswer: question.correctAnswer,
        isCorrect: isCorrect,
        questionNumber: question.questionNumber,
      ));
    }

    final percentage = (score / questions.length) * 100;

    final result = QuizResult(
      subjectName: widget.subjectName,
      partNumber: widget.partNumber,
      score: score,
      totalQuestions: questions.length,
      percentage: percentage,
      date: DateTime.now(),
      timeTaken: timeTaken,
      answers: quizAnswers,
    );

    await _saveQuizResult(result);
    _showResultDialog(result);
  }

  Future<void> _saveQuizResult(QuizResult result) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/quiz_history.json');

      List<QuizResult> history = [];
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final List<dynamic> historyJson = json.decode(jsonString);
        history = historyJson.map((h) => QuizResult.fromJson(h)).toList();
      }

      history.add(result);
      await file
          .writeAsString(json.encode(history.map((h) => h.toJson()).toList()));
    } catch (e) {
      debugPrint('Error saving quiz result: $e');
    }
  }

  void _showResultDialog(QuizResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ResultDialog(result: result),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          '${widget.subjectName} Quiz',
          style: const TextStyle(
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
          IconButton(
            icon: const Icon(Icons.history, color: Colors.pinkAccent),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const QuizHistoryPage()),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.pinkAccent),
            )
          : isQuizCompleted
              ? const Center(
                  child: Text(
                    'Quiz Completed!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.pinkAccent,
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Progress Bar
                    Container(
                      padding: const EdgeInsets.all(20),
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Question ${currentQuestionIndex + 1} of ${questions.length}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                '${((currentQuestionIndex + 1) / questions.length * 100).toInt()}%',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.pinkAccent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          AnimatedBuilder(
                            animation: _progressAnimation,
                            builder: (context, child) {
                              return LinearProgressIndicator(
                                value: _progressAnimation.value,
                                backgroundColor: Colors.grey[300],
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.pinkAccent,
                                ),
                                minHeight: 8,
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // Question Content
                    Expanded(
                      child: AnimatedBuilder(
                        animation: _scaleAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnimation.value,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Card(
                                elevation: 8,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Question
                                      Text(
                                        questions[currentQuestionIndex]
                                            .question,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 30),

                                      // Options
                                      Expanded(
                                        child: ListView.builder(
                                          itemCount:
                                              questions[currentQuestionIndex]
                                                  .options
                                                  .length,
                                          itemBuilder: (context, index) {
                                            final option =
                                                questions[currentQuestionIndex]
                                                    .options[index];
                                            final isSelected = userAnswers[
                                                    currentQuestionIndex] ==
                                                option;

                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 12),
                                              child: OptionCard(
                                                option: option,
                                                label: String.fromCharCode(
                                                    65 + index), // A, B, C, D
                                                isSelected: isSelected,
                                                onTap: () =>
                                                    _selectAnswer(option),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Navigation Buttons
                    Container(
                      padding: const EdgeInsets.all(20),
                      color: Colors.white,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            onPressed: currentQuestionIndex > 0
                                ? _previousQuestion
                                : null,
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Previous'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[300],
                              foregroundColor: Colors.grey[700],
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed:
                                currentQuestionIndex < questions.length - 1
                                    ? _nextQuestion
                                    : _finishQuiz,
                            icon: Icon(
                                currentQuestionIndex < questions.length - 1
                                    ? Icons.arrow_forward
                                    : Icons.check),
                            label: Text(
                                currentQuestionIndex < questions.length - 1
                                    ? 'Next'
                                    : 'Finish'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pinkAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

class OptionCard extends StatelessWidget {
  final String option;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const OptionCard({
    super.key,
    required this.option,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        elevation: isSelected ? 8 : 2,
        borderRadius: BorderRadius.circular(15),
        color: isSelected ? Colors.pinkAccent : Colors.white,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isSelected ? Colors.pinkAccent : Colors.grey[300]!,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.pinkAccent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? Colors.pinkAccent : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    option,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ResultDialog extends StatelessWidget {
  final QuizResult result;

  const ResultDialog({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final isPass = result.percentage >= 70;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: isPass
                ? [Colors.green[400]!, Colors.green[600]!]
                : [Colors.red[400]!, Colors.red[600]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPass ? Icons.celebration : Icons.refresh,
              size: 60,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            Text(
              isPass ? 'Congratulations!' : 'Keep Learning!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You scored ${result.score} out of ${result.totalQuestions}',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${result.percentage.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Time Taken:',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      Text(
                        '${result.timeTaken.inMinutes}:${(result.timeTaken.inSeconds % 60).toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Subject: ',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      Expanded(
                        child: Text(
                          '${result.subjectName} Part ${result.partNumber}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuizReviewPage(result: result),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: isPass ? Colors.green : Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Review Answers'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
