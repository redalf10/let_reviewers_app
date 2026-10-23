import 'package:flutter/material.dart';
import 'package:jaa_reviewer/services/local_rag.dart';

class LocalTutorPage extends StatefulWidget {
  const LocalTutorPage({super.key});

  @override
  State<LocalTutorPage> createState() => _LocalTutorPageState();
}

class _LocalTutorPageState extends State<LocalTutorPage> {
  static const _subjects = [
    'All subjects',
    'English',
    'Filipino',
    'General Education',
    'Mathematics',
    'Physical Science',
    'Professional Education',
    'Social Science',
    'Values Education',
  ];

  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <_TutorMessage>[];
  String _subject = _subjects.first;
  bool _isSearching = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _ask() async {
    final question = _controller.text.trim();
    if (question.isEmpty || _isSearching) return;
    _controller.clear();
    setState(() {
      _isSearching = true;
      _error = null;
      _messages.add(_TutorMessage(question: question, isUser: true));
    });
    _scrollToEnd();
    try {
      final hits = await LocalRagService.instance.search(
        question,
        subject: _subject,
      );
      if (!mounted) return;
      setState(() {
        _messages.add(_TutorMessage(
          question: question,
          isUser: false,
          hits: hits,
        ));
        _isSearching = false;
      });
      _scrollToEnd();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _error = 'Could not read the bundled study guides. $error';
      });
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Local AI Tutor',
          style: TextStyle(
            color: Colors.pinkAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.pinkAccent),
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.offline_bolt, color: Colors.green, size: 19),
                    SizedBox(width: 7),
                    Text(
                      'Offline and private',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  'Answers are retrieved from the study PDFs bundled with this app. Nothing is sent to a server.',
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _subject,
                  decoration: const InputDecoration(
                    labelText: 'Study material',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: _subjects
                      .map((subject) => DropdownMenuItem(
                            value: subject,
                            child: Text(subject),
                          ))
                      .toList(),
                  onChanged: _isSearching
                      ? null
                      : (value) => setState(() => _subject = value!),
                ),
              ],
            ),
          ),
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.menu_book,
                              size: 56, color: Colors.pinkAccent[100]),
                          const SizedBox(height: 12),
                          const Text(
                            'Ask about a topic in your LET reviewer.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'For example: “What are the stages of Piaget’s cognitive development?”',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) => _MessageCard(
                      message: _messages[index],
                    ),
                  ),
          ),
          if (_isSearching)
            const Column(
              children: [
                LinearProgressIndicator(color: Colors.pinkAccent),
                Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                      'Searching locally. The first search may take longer.'),
                ),
              ],
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _ask(),
                      decoration: const InputDecoration(
                        hintText: 'Ask a study question…',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _isSearching ? null : _ask,
                    icon: const Icon(Icons.send),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TutorMessage {
  final String question;
  final bool isUser;
  final List<LocalRagHit> hits;

  const _TutorMessage({
    required this.question,
    required this.isUser,
    this.hits = const [],
  });
}

class _MessageCard extends StatelessWidget {
  final _TutorMessage message;

  const _MessageCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final user = message.isUser;
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 640),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: user ? Colors.pinkAccent : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: user
              ? null
              : [
                  BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 8)
                ],
        ),
        child: user
            ? Text(message.question,
                style: const TextStyle(color: Colors.white))
            : _answer(context),
      ),
    );
  }

  Widget _answer(BuildContext context) {
    if (message.hits.isEmpty) {
      return const Text(
        'I could not find a matching passage in the selected study material. Try different keywords or choose All subjects.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Relevant passages from your reviewer',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        for (var i = 0; i < message.hits.length; i++) ...[
          if (i > 0) const Divider(height: 18),
          Text(message.hits[i].text, style: const TextStyle(height: 1.4)),
          const SizedBox(height: 5),
          Text(
            '${message.hits[i].subject} · Part ${message.hits[i].part} · p. ${message.hits[i].page}',
            style: TextStyle(
              color: Colors.pinkAccent[700],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          'These are retrieved source excerpts; check the cited page for full context.',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }
}
