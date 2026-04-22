import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:jaa_reviewer/services/quiz.dart';
import 'package:path_provider/path_provider.dart';

enum DrawingMode {
  none,
  pen,
  highlighter,
  eraser,
}

class DrawingPoint {
  final Offset point;
  final Color color;
  final double strokeWidth;
  final DrawingMode mode;

  DrawingPoint({
    required this.point,
    required this.color,
    required this.strokeWidth,
    required this.mode,
  });

  Map<String, dynamic> toJson() => {
        'dx': point.dx,
        'dy': point.dy,
        'color': color.value,
        'strokeWidth': strokeWidth,
        'mode': mode.index,
      };

  factory DrawingPoint.fromJson(Map<String, dynamic> json) => DrawingPoint(
        point: Offset(json['dx'] as double, json['dy'] as double),
        color: Color(json['color'] as int),
        strokeWidth: json['strokeWidth'] as double,
        mode: DrawingMode.values[json['mode'] as int],
      );
}

class DrawingStroke {
  final List<DrawingPoint> points;
  final Color color;
  final double strokeWidth;
  final DrawingMode mode;

  DrawingStroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.mode,
  });

  Map<String, dynamic> toJson() => {
        'points': points.map((p) => p.toJson()).toList(),
        'color': color.value,
        'strokeWidth': strokeWidth,
        'mode': mode.index,
      };

  factory DrawingStroke.fromJson(Map<String, dynamic> json) => DrawingStroke(
        points: (json['points'] as List)
            .map((p) => DrawingPoint.fromJson(p as Map<String, dynamic>))
            .toList(),
        color: Color(json['color'] as int),
        strokeWidth: json['strokeWidth'] as double,
        mode: DrawingMode.values[json['mode'] as int],
      );
}

class PDFViewerScreen extends StatefulWidget {
  final String subjectName;
  final int partNumber;
  final int totalParts;

  const PDFViewerScreen({
    super.key,
    required this.subjectName,
    required this.partNumber,
    required this.totalParts,
  });

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  String? localPath;
  bool isLoading = true;
  String errorMessage = '';

  // Drawing variables
  DrawingMode currentMode = DrawingMode.none;
  Color currentColor = Colors.red;
  double currentStrokeWidth = 3.0;

  // Store drawings per page
  Map<int, List<DrawingStroke>> pageDrawings = {};
  int currentPage = 0;
  List<DrawingPoint> currentStroke = [];

  // PDF controller
  PDFViewController? pdfController;
  double pdfWidth = 0;
  double pdfHeight = 0;
  double scaleFactor = 1.0;
  Offset offset = Offset.zero;

  // Unique identifier for this PDF
  String get pdfIdentifier =>
      'Part_${widget.partNumber}_${widget.subjectName.replaceAll(' ', '_')}';

  @override
  void initState() {
    super.initState();
    loadPDF();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> loadPDF() async {
    try {
      final pdfPath =
          'assets/Part ${widget.partNumber} ${widget.subjectName} www.teachpinas.com.pdf';
      final file = await _copyAssetToLocal(pdfPath);

      // Load saved annotations
      await _loadAnnotations();

      setState(() {
        localPath = file.path;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading PDF: $e';
        isLoading = false;
      });
    }
  }

  Future<File> _copyAssetToLocal(String assetPath) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/${assetPath.split('/').last}');
    if (await file.exists()) return file;
    final data = await rootBundle.load(assetPath);
    await file.writeAsBytes(data.buffer.asUint8List());
    return file;
  }

  Future<void> _saveAnnotations() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$pdfIdentifier.annotations');

      // Convert drawings to JSON
      final jsonData = {};
      pageDrawings.forEach((page, strokes) {
        jsonData[page.toString()] = strokes.map((s) => s.toJson()).toList();
      });

      await file.writeAsString(json.encode(jsonData));
    } catch (e) {
      debugPrint('Error saving annotations: $e');
    }
  }

  Future<void> _loadAnnotations() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$pdfIdentifier.annotations');

      if (await file.exists()) {
        final jsonData = json.decode(await file.readAsString());

        final loadedDrawings = <int, List<DrawingStroke>>{};
        jsonData.forEach((page, strokes) {
          loadedDrawings[int.parse(page)] =
              (strokes as List).map((s) => DrawingStroke.fromJson(s)).toList();
        });

        setState(() {
          pageDrawings = loadedDrawings;
        });
      }
    } catch (e) {
      debugPrint('Error loading annotations: $e');
    }
  }

  void _onPanStart(DragStartDetails details) {
    if (currentMode == DrawingMode.none) return;

    final point = _convertToPdfCoordinates(details.localPosition);
    setState(() {
      currentStroke = [
        DrawingPoint(
          point: point,
          color: currentColor,
          strokeWidth: currentStrokeWidth,
          mode: currentMode,
        )
      ];
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (currentMode == DrawingMode.none) return;

    final point = _convertToPdfCoordinates(details.localPosition);
    setState(() {
      currentStroke.add(
        DrawingPoint(
          point: point,
          color: currentColor,
          strokeWidth: currentStrokeWidth,
          mode: currentMode,
        ),
      );
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (currentMode == DrawingMode.none || currentStroke.isEmpty) return;

    setState(() {
      if (pageDrawings[currentPage] == null) {
        pageDrawings[currentPage] = [];
      }

      pageDrawings[currentPage]!.add(
        DrawingStroke(
          points: List.from(currentStroke),
          color: currentColor,
          strokeWidth: currentStrokeWidth,
          mode: currentMode,
        ),
      );

      currentStroke = [];
      _saveAnnotations(); // Save after each stroke
    });
  }

  Offset _convertToPdfCoordinates(Offset screenPoint) {
    // Convert screen coordinates to PDF coordinates accounting for zoom/pan
    if (pdfWidth == 0 || pdfHeight == 0) return screenPoint;

    // Calculate the visible PDF area
    final viewportWidth = MediaQuery.of(context).size.width;
    final viewportHeight =
        MediaQuery.of(context).size.height - 60; // Toolbar height

    // Calculate the PDF's display dimensions
    final displayWidth = pdfWidth * scaleFactor;
    final displayHeight = pdfHeight * scaleFactor;

    // Calculate the offset (centering)
    final offsetX = (viewportWidth - displayWidth) / 2 + offset.dx;
    final offsetY = (viewportHeight - displayHeight) / 2 + offset.dy;

    // Convert screen point to PDF point
    final pdfX = (screenPoint.dx - offsetX) / scaleFactor;
    final pdfY = (screenPoint.dy - offsetY) / scaleFactor;

    return Offset(pdfX, pdfY);
  }

  void _clearCurrentPage() {
    setState(() {
      pageDrawings[currentPage] = [];
      _saveAnnotations();
    });
  }

  void _undoLastStroke() {
    setState(() {
      if (pageDrawings[currentPage] != null &&
          pageDrawings[currentPage]!.isNotEmpty) {
        pageDrawings[currentPage]!.removeLast();
        _saveAnnotations();
      }
    });
  }

  void _eraseAtPoint(Offset screenPoint) {
    final point = _convertToPdfCoordinates(screenPoint);
    setState(() {
      if (pageDrawings[currentPage] != null) {
        pageDrawings[currentPage]!.removeWhere((stroke) {
          return stroke.points.any((strokePoint) {
            final distance = (strokePoint.point - point).distance;
            return distance <
                30.0 / scaleFactor; // Scale erase radius with zoom
          });
        });
        _saveAnnotations();
      }
    });
  }

  void _setDrawingMode(DrawingMode mode) {
    setState(() {
      currentMode = mode;
      if (mode == DrawingMode.highlighter) {
        currentColor = Colors.yellow.withOpacity(0.5);
        currentStrokeWidth = 15.0;
      } else if (mode == DrawingMode.pen) {
        currentColor = Colors.red;
        currentStrokeWidth = 3.0;
      } else if (mode == DrawingMode.eraser) {
        currentColor = Colors.transparent;
        currentStrokeWidth = 15.0;
      }
    });
  }

  Widget _buildDrawingToolbar() {
    return Container(
      height: 60,
      color: Colors.grey[200],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildToolButton(
            icon: Icons.touch_app,
            label: 'Select',
            isSelected: currentMode == DrawingMode.none,
            onTap: () => _setDrawingMode(DrawingMode.none),
          ),
          _buildToolButton(
            icon: Icons.edit,
            label: 'Pen',
            isSelected: currentMode == DrawingMode.pen,
            onTap: () => _setDrawingMode(DrawingMode.pen),
          ),
          _buildToolButton(
            icon: Icons.highlight,
            label: 'Highlight',
            isSelected: currentMode == DrawingMode.highlighter,
            onTap: () => _setDrawingMode(DrawingMode.highlighter),
          ),
          _buildToolButton(
            icon: Icons.cleaning_services,
            label: 'Eraser',
            isSelected: currentMode == DrawingMode.eraser,
            onTap: () => _setDrawingMode(DrawingMode.eraser),
          ),
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _undoLastStroke,
            tooltip: 'Undo',
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearCurrentPage,
            tooltip: 'Clear Page',
          ),
          if (currentMode == DrawingMode.pen)
            PopupMenuButton<Color>(
              icon: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: currentColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey),
                ),
              ),
              onSelected: (color) {
                setState(() {
                  currentColor = color;
                });
              },
              itemBuilder: (context) => [
                Colors.red,
                Colors.blue,
                Colors.green,
                Colors.black,
                Colors.purple,
                Colors.orange,
              ]
                  .map((color) => PopupMenuItem(
                        value: color,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.pinkAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 20,
            ),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuizPage(
                subjectName: widget.subjectName,
                partNumber: widget.partNumber,
              ),
            ),
          );
        },
        label: const Text('Take A Quiz', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.question_answer, color: Colors.white),
        backgroundColor: Colors.pinkAccent,
      ),
      appBar: AppBar(
        title: Text(
          '${widget.subjectName} - Part ${widget.partNumber}',
          style: const TextStyle(
            color: Colors.pinkAccent,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_circle_left_outlined,
            color: Colors.pinkAccent,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.save, color: Colors.pinkAccent),
        //     onPressed: () {
        //       ScaffoldMessenger.of(context).showSnackBar(
        //         const SnackBar(
        //             content: Text('Annotations saved automatically')),
        //       );
        //     },
        //   ),
        // ],
      ),
      body: Column(
        children: [
          _buildDrawingToolbar(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage.isNotEmpty
                    ? Center(child: Text(errorMessage))
                    : Stack(
                        children: [
                          PDFView(
                            filePath: localPath,
                            enableSwipe: true,
                            onViewCreated: (controller) {
                              pdfController = controller;
                            },
                            onPageChanged: (page, total) {
                              setState(() {
                                currentPage = page ?? 0;
                              });
                            },
                            onRender: (pages) {
                              if (pages != null && pages > 0) {
                                // Estimate PDF dimensions based on aspect ratio
                                // This is a workaround since getPageSize isn't available
                                setState(() {
                                  pdfWidth = MediaQuery.of(context).size.width;
                                  pdfHeight = pdfWidth *
                                      1.414; // Assuming A4 aspect ratio (1:√2)
                                });
                              }
                            },
                          ),

                          // Drawing overlay
                          Positioned.fill(
                            child: IgnorePointer(
                              ignoring: currentMode == DrawingMode.none,
                              child: GestureDetector(
                                onPanStart: (details) {
                                  if (currentMode == DrawingMode.eraser) {
                                    _eraseAtPoint(details.localPosition);
                                  } else if (currentMode != DrawingMode.none) {
                                    _onPanStart(details);
                                  }
                                },
                                onPanUpdate: (details) {
                                  if (currentMode == DrawingMode.eraser) {
                                    _eraseAtPoint(details.localPosition);
                                  } else if (currentMode != DrawingMode.none) {
                                    _onPanUpdate(details);
                                  }
                                },
                                onPanEnd: (details) {
                                  if (currentMode != DrawingMode.none &&
                                      currentMode != DrawingMode.eraser) {
                                    _onPanEnd(details);
                                  }
                                },
                                child: CustomPaint(
                                  painter: DrawingPainter(
                                    strokes: pageDrawings[currentPage] ?? [],
                                    currentStroke: currentStroke,
                                    currentColor: currentColor,
                                    currentStrokeWidth: currentStrokeWidth,
                                    currentMode: currentMode,
                                    scaleFactor: scaleFactor,
                                    pdfWidth: pdfWidth,
                                    pdfHeight: pdfHeight,
                                  ),
                                ),
                              ),
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

class DrawingPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final List<DrawingPoint> currentStroke;
  final Color currentColor;
  final double currentStrokeWidth;
  final DrawingMode currentMode;
  final double scaleFactor;
  final double pdfWidth;
  final double pdfHeight;

  DrawingPainter({
    required this.strokes,
    required this.currentStroke,
    required this.currentColor,
    required this.currentStrokeWidth,
    required this.currentMode,
    required this.scaleFactor,
    required this.pdfWidth,
    required this.pdfHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (pdfWidth == 0 || pdfHeight == 0) return;

    // Calculate the visible PDF area
    final viewportWidth = size.width;
    final viewportHeight = size.height;

    // Calculate the PDF's display dimensions
    final displayWidth = pdfWidth * scaleFactor;
    final displayHeight = pdfHeight * scaleFactor;

    // Calculate the offset (centering)
    final offsetX = (viewportWidth - displayWidth) / 2;
    final offsetY = (viewportHeight - displayHeight) / 2;

    // Apply transformation to match PDF zoom/pan
    canvas.save();
    canvas.translate(offsetX, offsetY);
    canvas.scale(scaleFactor, scaleFactor);

    // Draw completed strokes
    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (stroke.mode == DrawingMode.highlighter) {
        paint.blendMode = BlendMode.multiply;
      }

      if (stroke.points.isNotEmpty) {
        final path = Path();
        path.moveTo(stroke.points.first.point.dx, stroke.points.first.point.dy);

        for (int i = 1; i < stroke.points.length; i++) {
          path.lineTo(stroke.points[i].point.dx, stroke.points[i].point.dy);
        }

        canvas.drawPath(path, paint);
      }
    }

    // Draw current stroke
    if (currentStroke.isNotEmpty && currentMode != DrawingMode.eraser) {
      final paint = Paint()
        ..color = currentColor
        ..strokeWidth = currentStrokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (currentMode == DrawingMode.highlighter) {
        paint.blendMode = BlendMode.multiply;
      }

      final path = Path();
      path.moveTo(currentStroke.first.point.dx, currentStroke.first.point.dy);

      for (int i = 1; i < currentStroke.length; i++) {
        path.lineTo(currentStroke[i].point.dx, currentStroke[i].point.dy);
      }

      canvas.drawPath(path, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
