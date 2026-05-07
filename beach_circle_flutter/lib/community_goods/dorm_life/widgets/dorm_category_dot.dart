import 'package:flutter/material.dart';
import 'package:beach_circle_flutter/community_goods/dorm_life/models/dorm_event.dart';

// ── Single dot ───────────────────────────────────────────────────────────────

class DormCategoryDot extends StatelessWidget {
  final DormCategory category;
  final double size;
  final bool isSelected;

  const DormCategoryDot({
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

class DormCategoryDotRow extends StatelessWidget {
  final List<DormCategory> categories;
  final double dotSize;
  final double spacing;

  const DormCategoryDotRow({
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
                child: DormCategoryDot(category: c, size: dotSize),
              ))
          .toList(),
    );
  }
}

// ── 3-dot category selector (used in Add Dorm form header) ───────────────────

class DormCategorySelector extends StatefulWidget {
  final DormCategory selected;
  final ValueChanged<DormCategory> onChanged;
  final double dotSize;

  const DormCategorySelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.dotSize = 14,
  });

  @override
  State<DormCategorySelector> createState() => _DormCategorySelectorState();
}

class _DormCategorySelectorState extends State<DormCategorySelector> {
  late DormCategory _current;

  @override
  void initState() {
    super.initState();
    _current = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: DormCategory.values.map((cat) {
            return GestureDetector(
              onTap: () {
                setState(() => _current = cat);
                widget.onChanged(cat);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: DormCategoryDot(
                  category: cat,
                  size: widget.dotSize,
                  isSelected: cat == _current,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 4),
        Text(
          _current.label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _current.color,
          ),
        ),
      ],
    );
  }
}