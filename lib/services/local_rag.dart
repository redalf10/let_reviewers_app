import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// On-device retrieval over the PDF study guides bundled with the app.
/// It has no network client and never sends questions or study data anywhere.
class LocalRagService {
  LocalRagService._();

  static final LocalRagService instance = LocalRagService._();
  Future<List<_Passage>>? _indexFuture;

  Future<List<LocalRagHit>> search(String query, {String? subject}) async {
    final terms = _tokens(query).toSet();
    if (terms.isEmpty) return const [];
    final passages = await _index();
    final scoped = subject == null || subject == 'All subjects'
        ? passages
        : passages.where((passage) => passage.subject == subject).toList();
    if (scoped.isEmpty) return const [];

    final documentFrequency = <String, int>{};
    for (final passage in scoped) {
      for (final term in terms) {
        if (passage.termCounts.containsKey(term)) {
          documentFrequency.update(term, (count) => count + 1,
              ifAbsent: () => 1);
        }
      }
    }

    final ranked = <({double score, _Passage passage})>[];
    for (final passage in scoped) {
      var score = 0.0;
      for (final term in terms) {
        final frequency = passage.termCounts[term] ?? 0;
        if (frequency == 0) continue;
        final inverseFrequency =
            math.log(1 + scoped.length / (1 + (documentFrequency[term] ?? 0)));
        score += inverseFrequency *
            (frequency / (frequency + 1.2 + 0.75 * passage.termCount / 120));
      }
      if (score > 0) ranked.add((score: score, passage: passage));
    }
    ranked.sort((a, b) => b.score.compareTo(a.score));

    final hits = <LocalRagHit>[];
    final seen = <String>{};
    for (final item in ranked) {
      final normalized = item.passage.text.toLowerCase();
      if (!seen.add(normalized)) continue;
      hits.add(LocalRagHit(
        text: item.passage.text,
        subject: item.passage.subject,
        part: item.passage.part,
        page: item.passage.page,
        score: item.score,
      ));
      if (hits.length == 4) break;
    }
    return hits;
  }

  Future<List<_Passage>> _index() => _indexFuture ??= _buildIndex();

  Future<List<_Passage>> _buildIndex() async {
    final directory = await getApplicationSupportDirectory();
    final cacheFile = File('${directory.path}/local_rag_index_v1.json');
    if (await cacheFile.exists()) {
      try {
        final cached = json.decode(await cacheFile.readAsString()) as List;
        return cached
            .map((item) => _Passage.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (_) {
        // A damaged or outdated local index is rebuilt from bundled PDFs.
      }
    }

    final passages = <_Passage>[];
    const partCounts = {
      'English': 8,
      'Filipino': 7,
      'General Education': 8,
      'Mathematics': 5,
      'Physical Science': 8,
      'Professional Education': 8,
      'Social Science': 8,
      'Values Education': 4,
    };
    for (final subject in partCounts.keys) {
      for (var part = 1; part <= partCounts[subject]!; part++) {
        final asset = 'assets/Part $part $subject www.teachpinas.com.pdf';
        final data = await rootBundle.load(asset);
        final document = PdfDocument(inputBytes: data.buffer.asUint8List());
        try {
          final extractor = PdfTextExtractor(document);
          for (var page = 0; page < document.pages.count; page++) {
            final text = extractor.extractText(
              startPageIndex: page,
              endPageIndex: page,
            );
            for (final chunk in _chunks(text)) {
              final tokens = _tokens(chunk);
              if (tokens.length < 5) continue;
              final counts = <String, int>{};
              for (final token in tokens) {
                counts.update(token, (count) => count + 1, ifAbsent: () => 1);
              }
              passages.add(_Passage(
                text: chunk,
                subject: subject,
                part: part,
                page: page + 1,
                termCounts: counts,
                termCount: tokens.length,
              ));
            }
          }
        } finally {
          document.dispose();
        }
      }
    }
    await directory.create(recursive: true);
    await cacheFile.writeAsString(
      json.encode(passages.map((passage) => passage.toJson()).toList()),
      flush: true,
    );
    return passages;
  }

  static List<String> _chunks(String input) {
    final clean = input.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.isEmpty) return const [];
    final sentences = clean.split(RegExp(r'(?<=[.!?])\s+'));
    final result = <String>[];
    var buffer = '';
    for (final sentence in sentences) {
      if (buffer.isNotEmpty && buffer.length + sentence.length > 700) {
        result.add(buffer.trim());
        buffer = '';
      }
      buffer = buffer.isEmpty ? sentence : '$buffer $sentence';
    }
    if (buffer.trim().isNotEmpty) result.add(buffer.trim());
    return result;
  }

  static List<String> _tokens(String text) =>
      RegExp(r"[\p{L}\p{N}]{2,}", unicode: true)
          .allMatches(text.toLowerCase())
          .map((match) => match.group(0)!)
          .where((token) => !_stopWords.contains(token))
          .toList();

  static const _stopWords = {
    'the',
    'and',
    'for',
    'that',
    'with',
    'this',
    'from',
    'are',
    'was',
    'were',
    'you',
    'your',
    'what',
    'when',
    'where',
    'which',
    'who',
    'how',
    'why',
    'does',
    'did',
    'has',
    'have',
    'had',
    'not',
    'but',
    'can',
    'could',
    'would',
    'should',
    'into',
    'about',
    'than',
    'then',
    'them',
    'they',
    'their',
    'there',
    'its',
    'our',
    'out',
    'all',
    'any',
    'also',
    'use',
    'used',
    'using',
    'one',
    'two',
    'such',
    'each',
    'more',
    'most',
    'some',
    'other',
    'through',
    'being',
  };
}

class LocalRagHit {
  final String text;
  final String subject;
  final int part;
  final int page;
  final double score;

  const LocalRagHit({
    required this.text,
    required this.subject,
    required this.part,
    required this.page,
    required this.score,
  });
}

class _Passage {
  final String text;
  final String subject;
  final int part;
  final int page;
  final Map<String, int> termCounts;
  final int termCount;

  const _Passage({
    required this.text,
    required this.subject,
    required this.part,
    required this.page,
    required this.termCounts,
    required this.termCount,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'subject': subject,
        'part': part,
        'page': page,
        'termCounts': termCounts,
        'termCount': termCount,
      };

  factory _Passage.fromJson(Map<String, dynamic> json) => _Passage(
        text: json['text'] as String,
        subject: json['subject'] as String,
        part: json['part'] as int,
        page: json['page'] as int,
        termCounts: (json['termCounts'] as Map<String, dynamic>).map(
          (term, count) => MapEntry(term, count as int),
        ),
        termCount: json['termCount'] as int,
      );
}
