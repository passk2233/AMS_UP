import 'package:flutter/material.dart';
import 'package:frontend/app/widgets/widget.dart';

/// Horizontal four-cell stat strip mirroring the official transcript header
/// (total subjects · total credits · overall GPA · term progress).
class TranscriptStatStrip extends StatelessWidget {
  final List<TranscriptStatCell> cells;
  const TranscriptStatStrip({super.key, required this.cells});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppColors.cardRadius),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (final cell in cells)
              Expanded(
                child: Container(
                  color: cell.color,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 6,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          cell.value,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: cell.valueColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        cell.label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.2,
                          color: cell.labelColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One cell definition for [TranscriptStatStrip].
class TranscriptStatCell {
  final String value;
  final String label;
  final Color color;
  final Color valueColor;
  final Color labelColor;

  const TranscriptStatCell({
    required this.value,
    required this.label,
    required this.color,
    this.valueColor = Colors.white,
    this.labelColor = Colors.white,
  });
}
