import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_clock_helper/model.dart';
import 'package:gdr_clock/clock.dart';

class Temperature extends LeafRenderObjectWidget {
  final TemperatureUnit unit;
  final String unitString;
  final double temperature, low, high;

  Temperature({
    Key key,
    @required this.unit,
    @required this.unitString,
    @required this.temperature,
    @required this.low,
    @required this.high,
  })  : assert(unit != null),
        assert(unitString != null),
        assert(temperature != null),
        assert(low != null),
        assert(high != null),
        super(key: key);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderTemperature(
      unit: unit,
      unitString: unitString,
      temperature: temperature,
      low: low,
      high: high,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderTemperature renderObject) {
    renderObject
      ..unit = unit
      ..unitString = unitString
      ..temperature = temperature
      ..low = low
      ..high = high
      ..markNeedsPaint();
  }
}

class RenderTemperature extends RenderCompositionChild {
  static const temperatureScale = {
    TemperatureUnit.celsius: [-16, 50],
    TemperatureUnit.fahrenheit: [3, 122],
  };

  RenderTemperature({
    this.unit,
    this.unitString,
    this.temperature,
    this.low,
    this.high,
  }) : super(ClockComponent.temperature);

  TemperatureUnit unit;
  String unitString;
  double temperature, low, high;

  @override
  bool get sizedByParent => true;

  @override
  void performResize() {
    size = Size(constraints.biggest.width, constraints.biggest.height / 1.2);
  }

  static const tubeColor = Color(0xffffe3d1), mountColor = Color(0xffa38d1c);

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;

    canvas.save();
    canvas.translate(offset.dx, offset.dy);

    final area = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(size.width / 36));

    //<editor-fold desc="Background">
    final backgroundGradient = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: const [
      Color(0xffcc9933),
      Color(0xffc9bd6c),
    ]);
    canvas.drawRRect(
        area,
        Paint()
          ..style = PaintingStyle.fill
          ..shader = backgroundGradient.createShader(Offset.zero & size));
    //</editor-fold>

    // Border
    canvas.drawRRect(
        area,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = const Color(0xff000000));

    //<editor-fold desc="Some kind of brad nails at the top and bottom">
    final bradRadius = size.width / 29,
        // Lighter in the center to give some depth based on the lighting
        bradGradient = const RadialGradient(colors: [
      Color(0xff898984),
      Color(0xff43464b),
    ]),
        bradIndent = size.width / 11;
    () {
      final topRect = Rect.fromCircle(center: Offset(size.width / 2, bradIndent), radius: bradRadius);
      canvas.drawOval(topRect, Paint()..shader = bradGradient.createShader(topRect));

      final bottomRect = Rect.fromCircle(center: Offset(size.width / 2, size.height - bradIndent), radius: bradRadius);
      canvas.drawOval(bottomRect, Paint()..shader = bradGradient.createShader(bottomRect));
    }();
    //</editor-fold>

    //<editor-fold desc="Unit">
    final unitIndent = size.width / 8,
        unitPainter = TextPainter(
      text: TextSpan(
        text: unitString,
        style: TextStyle(
          color: const Color(0xff000000),
          fontSize: size.width / 6,
        ),
      ),
      textDirection: TextDirection.ltr,
    ),
        freeUnitWidth = size.width - unitIndent * 2;
    unitPainter.layout(maxWidth: freeUnitWidth);
    unitPainter.paint(canvas, Offset(unitIndent + (freeUnitWidth / 2 - unitPainter.width / 2), unitIndent + bradIndent));
    //</editor-fold>

    // Constraints for the positioning of the numbers, lines, brackets, and tube.
    final addedIndentFactor = 3.2,
        mount = Line.fromEE(end: size.height - bradIndent * addedIndentFactor, extent: size.height / 13),
        tube = Line(end: mount.start, start: unitIndent + unitPainter.height / 1.4 + bradIndent * addedIndentFactor),
        brackets = Line.fromSEI(start: tube.start, end: tube.end, indent: tube.extent / 7.42),
        lines = Line.fromSEI(start: brackets.start, end: brackets.end, indent: -mount.extent / 3);

    _paintLines(canvas, lines);

    //<editor-fold desc="Glass tube">
    final tubePaint = Paint()
      ..color = tubeColor
      ..strokeWidth = bradRadius * 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(tube.startOffset(dx: size.width / 2), tube.endOffset(dx: size.width / 2), tubePaint);
    //</editor-fold>

    // todo paint max temperature

    // todo paint current temperature

    // todo paint min temperature

    //<editor-fold desc="Mount">
    () {
      final paint = Paint()
            ..color = mountColor
            ..strokeWidth = bradRadius * 1.33
            ..strokeCap = StrokeCap.round,
          start = mount.startOffset(dx: size.width / 2);

      canvas.drawLine(
        start,
        mount.endOffset(dx: size.width / 2),
        paint,
      );

      // Add square cap at the top
      canvas.drawLine(
        start,
        start,
        paint..strokeCap = StrokeCap.square,
      );
    }();
    //</editor-fold>

    //<editor-fold desc="Brackets">
    final bracketGradient = const LinearGradient(
            // Again, highlight in the center to show that the metal is shining.
            colors: [
          Color(0xff87898c),
          Color(0xffe0e1e2),
          Color(0xff87898c),
        ]),
        bracketWidth = tubePaint.strokeWidth * 1.42,
        bracketSize = Size(bracketWidth, bracketWidth / 2.3);
    () {
      final dx = size.width / 2 - bracketWidth / 2;

      final startRect = brackets.startOffset(dx: dx) & bracketSize;
      canvas.drawRect(startRect, Paint()..shader = bracketGradient.createShader(startRect));

      final endRect = brackets.endOffset(dx: dx) & bracketSize;
      canvas.drawRect(endRect, Paint()..shader = bracketGradient.createShader(endRect));
    }();
    //</editor-fold>

    canvas.restore();
  }

  void _paintLines(Canvas canvas, Line constraints) {
    final paint = Paint()..color = const Color(0xff000000);

    final majorValue = unit == TemperatureUnit.fahrenheit ? 20 : 10, intermediateValue = majorValue / 2, minorValue = intermediateValue / 5;

    final fontSize = size.width / 7.4,
        fontIndent = fontSize / 9,
        style = TextStyle(
      color: const Color(0xff000000),
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
    );

    final minMax = temperatureScale[unit], min = minMax[0], max = minMax[1], difference = constraints.extent / max.difference(min) * minorValue;

    var h = constraints.end;
    for (var i = min; i <= max; i++) {
      if (i % minorValue != 0 && i % intermediateValue != 0 && i % majorValue != 0) continue;

      if (i % majorValue == 0) {
        final line = Line.fromCenter(center: size.width / 2, extent: size.width / 1.46);

        canvas.drawLine(line.startOffset(dy: h), line.endOffset(dy: h), paint);

        final text = i == 0 ? '00' : '${i.abs()}', left = text.substring(0, 1), right = text.substring(1);

        final leftPainter = TextPainter(
          text: TextSpan(
            text: left,
            style: style,
          ),
          textDirection: TextDirection.ltr,
        ),
            rightPainter = TextPainter(
          text: TextSpan(
            text: right,
            style: style,
          ),
          textDirection: TextDirection.ltr,
        );

        // If the digits do not fit roughly line.extent / 4, the design is screwed anyway, hence, no constraints here.
        leftPainter.layout();
        rightPainter.layout();

        // The TextPainters will return slightly larger sizes than actually visible and
        // this is supposed to compensate exactly that.
        final heightReduction = 1.14;

        leftPainter.paint(canvas, Offset(line.start + fontIndent, h - leftPainter.height / heightReduction));
        rightPainter.paint(canvas, Offset(line.end - fontIndent - rightPainter.width, h - rightPainter.height / heightReduction));
      } else if (i % intermediateValue == 0) {
        final line = Line.fromCenter(center: size.width / 2, extent: size.width / 2.1);

        canvas.drawLine(line.startOffset(dy: h), line.endOffset(dy: h), paint);
      } else if (i % minorValue == 0) {
        final line = Line.fromCenter(center: size.width / 2, extent: size.width / 3.3);

        canvas.drawLine(line.startOffset(dy: h), line.endOffset(dy: h), paint);
      }

      h -= difference;
    }
  }
}
