// eb_category_dot.dart
import 'package:flutter/material.dart';
import 'package:beach_circle_flutter/community_goods/event_board/models/eb_event.dart';

// ── Single dot ───────────────────────────────────────────────────────────────

class EbCategoryDot extends StatelessWidget {
  final EventBoardCategory category;
  final double size;
  final bool isSelected;

  const EbCategoryDot({
    super.key,
    required this.category,
    this.size = 10,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isSelected ? size * 1.3 : size,
      height: isSelected ? size * 1.3 : size,
      decoration: BoxDecoration(
        color: category.color,
        shape: BoxShape.circle,
        border: isSelected
            ? Border.all(color: Colors.black38, width: 1.5)
            : null,
      ),
    );
  }
}

// ── Row of dots for a day ────────────────────────────────────────────────────

class EbCategoryDotRow extends StatelessWidget {
  final List<EventBoardCategory> categories;
  final double dotSize;
  final double spacing;

  const EbCategoryDotRow({
    super.key,
    required this.categories,
    this.dotSize = 10,
    this.spacing = 4,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: categories
          .map((c) => Padding(
                padding: EdgeInsets.only(right: spacing),
                child: EbCategoryDot(category: c, size: dotSize),
              ))
          .toList(),
    );
  }
}

// ── 3-dot category selector (used in Add Event form header) ──────────────────

class EbCategorySelector extends StatelessWidget {
  final EventBoardCategory selected;
  final ValueChanged<EventBoardCategory> onChanged;
  final double dotSize;

  const EbCategorySelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.dotSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: EventBoardCategory.values.map((cat) {
        return GestureDetector(
          onTap: () => onChanged(cat),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Tooltip(
              message: cat.label,
              child: EbCategoryDot(
                category: cat,
                size: dotSize,
                isSelected: cat == selected,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}