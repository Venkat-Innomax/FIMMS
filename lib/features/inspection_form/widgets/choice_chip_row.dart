import 'package:flutter/material.dart';

import '../../../core/theme.dart';

class ChoiceOption {
  final String value;
  final String label;
  final Color? accent;
  const ChoiceOption({
    required this.value,
    required this.label,
    this.accent,
  });
}

/// Segmented chip row used by yes/no, good/avg/poor, avail/partial/na, etc.
class ChoiceChipRow extends StatelessWidget {
  final List<ChoiceOption> options;
  final String? value;
  final ValueChanged<String> onChanged;

  const ChoiceChipRow({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final opt in options)
          _Chip(
            opt: opt,
            selected: opt.value == value,
            onTap: () => onChanged(opt.value),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final ChoiceOption opt;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.opt,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = opt.accent ?? FimmsColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.1)
              : FimmsColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? accent : FimmsColors.outline,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(Icons.check_circle, size: 15, color: accent),
              ),
            Text(
              opt.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? accent : FimmsColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
