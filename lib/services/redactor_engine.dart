import 'package:flutter/material.dart';

enum RedactionTool { move, paint, rect, circle }

class RedactionShape {
  final String id;
  final RedactionTool type;
  final Rect? rect;
  final List<Offset>? points;
  final String? label; // e.g. 'NIR', 'IBAN', 'Adresse'

  RedactionShape({
    required this.id,
    required this.type,
    this.rect,
    this.points,
    this.label,
  });
}

class RedactorEngine {
  final List<RedactionShape> _shapes = [];
  final List<RedactionShape> _redoStack = [];

  List<RedactionShape> get shapes => List.unmodifiable(_shapes);
  bool get canUndo => _shapes.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void addShape(RedactionShape shape) {
    _shapes.add(shape);
    _redoStack.clear();
  }

  void undo() {
    if (_shapes.isNotEmpty) {
      final removed = _shapes.removeLast();
      _redoStack.add(removed);
    }
  }

  void redo() {
    if (_redoStack.isNotEmpty) {
      final restored = _redoStack.removeLast();
      _shapes.add(restored);
    }
  }

  void clearAll() {
    _shapes.clear();
    _redoStack.clear();
  }

  /// Automatically generate RGPD redaction boxes for sensitive regions
  void generateRgpdAutoMasks(Size docSize) {
    _shapes.clear();
    _redoStack.clear();

    // 1. Employee Name & Address (Top Right)
    _shapes.add(
      RedactionShape(
        id: 'rgpd-name-address',
        type: RedactionTool.rect,
        label: 'Nom & Adresse',
        rect: Rect.fromLTWH(
          docSize.width * 0.52,
          docSize.height * 0.16,
          docSize.width * 0.44,
          docSize.height * 0.08,
        ),
      ),
    );

    // 2. NIR (Numéro de Sécurité Sociale - Top Right Info Box)
    _shapes.add(
      RedactionShape(
        id: 'rgpd-nir',
        type: RedactionTool.rect,
        label: 'NIR / Securité Sociale',
        rect: Rect.fromLTWH(
          docSize.width * 0.62,
          docSize.height * 0.09,
          docSize.width * 0.34,
          docSize.height * 0.022,
        ),
      ),
    );

    // 3. IBAN / BIC / Bank Account (Bottom Right Virement Box)
    _shapes.add(
      RedactionShape(
        id: 'rgpd-iban',
        type: RedactionTool.rect,
        label: 'IBAN & Coordonnées Bancaires',
        rect: Rect.fromLTWH(
          docSize.width * 0.50,
          docSize.height * 0.81,
          docSize.width * 0.46,
          docSize.height * 0.065,
        ),
      ),
    );

    // 4. SIRET & Employer Details (Top Left)
    _shapes.add(
      RedactionShape(
        id: 'rgpd-siret',
        type: RedactionTool.rect,
        label: 'SIRET Employeur',
        rect: Rect.fromLTWH(
          docSize.width * 0.04,
          docSize.height * 0.06,
          docSize.width * 0.40,
          docSize.height * 0.07,
        ),
      ),
    );
  }
}

class RedactionCanvasPainter extends CustomPainter {
  final List<RedactionShape> shapes;
  final bool isMaskVisible;
  final RedactionShape? currentDraftShape;

  RedactionCanvasPainter({
    required this.shapes,
    required this.isMaskVisible,
    this.currentDraftShape,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isMaskVisible) return;

    final maskPaint = Paint()
      ..color = const Color(0xFF0F172A) // Solid dark slate / black block
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = const Color(0xFF3B82F6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (var shape in shapes) {
      _drawShape(canvas, shape, maskPaint, outlinePaint);
    }

    if (currentDraftShape != null) {
      final draftPaint = Paint()
        ..color = const Color(0xFF3B82F6).withValues(alpha: 0.6)
        ..style = PaintingStyle.fill;
      _drawShape(canvas, currentDraftShape!, draftPaint, outlinePaint);
    }
  }

  void _drawShape(Canvas canvas, RedactionShape shape, Paint fillPaint, Paint strokePaint) {
    switch (shape.type) {
      case RedactionTool.rect:
        if (shape.rect != null) {
          final rrect = RRect.fromRectAndRadius(shape.rect!, const Radius.circular(4));
          canvas.drawRRect(rrect, fillPaint);
          canvas.drawRRect(rrect, strokePaint);
        }
        break;
      case RedactionTool.circle:
        if (shape.rect != null) {
          canvas.drawOval(shape.rect!, fillPaint);
          canvas.drawOval(shape.rect!, strokePaint);
        }
        break;
      case RedactionTool.paint:
        if (shape.points != null && shape.points!.length > 1) {
          final strokeBrush = Paint()
            ..color = const Color(0xFF0F172A)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 16
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round;

          for (int i = 0; i < shape.points!.length - 1; i++) {
            canvas.drawLine(shape.points![i], shape.points![i + 1], strokeBrush);
          }
        }
        break;
      case RedactionTool.move:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
