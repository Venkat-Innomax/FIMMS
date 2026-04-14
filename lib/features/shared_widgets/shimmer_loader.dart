import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/ui_constants.dart';

/// A reusable shimmer/skeleton loading widget that shows animated grey
/// placeholder boxes with a pulsing opacity effect.
///
/// Uses [FimmsColors.surface] and [FimmsColors.outline] for the shimmer tones,
/// so it blends naturally with the FIMMS design system.
///
/// Variants:
/// - [ShimmerLoader.card] — a single card-sized placeholder.
/// - [ShimmerLoader.list] — a vertical list of row placeholders.
/// - [ShimmerLoader.stat] — a compact stat-card placeholder.
class ShimmerLoader extends StatefulWidget {
  const ShimmerLoader({
    super.key,
    required this.child,
  });

  /// A single card-shaped shimmer placeholder.
  factory ShimmerLoader.card({Key? key}) {
    return ShimmerLoader(
      key: key,
      child: const _ShimmerCard(),
    );
  }

  /// A vertical list of row shimmer placeholders.
  factory ShimmerLoader.list({Key? key, int items = 3}) {
    return ShimmerLoader(
      key: key,
      child: _ShimmerList(items: items),
    );
  }

  /// A compact stat-box shimmer placeholder.
  factory ShimmerLoader.stat({Key? key}) {
    return ShimmerLoader(
      key: key,
      child: const _ShimmerStat(),
    );
  }

  final Widget child;

  @override
  State<ShimmerLoader> createState() => _ShimmerLoaderState();
}

class _ShimmerLoaderState extends State<ShimmerLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: widget.child,
    );
  }
}

// ---------------------------------------------------------------------------
// Internal placeholder shapes
// ---------------------------------------------------------------------------

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: FimmsColors.outline.withAlpha(100),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Card variant — mimics a content card with a title line, two body lines,
/// and a short trailing line.
class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: FimmsColors.surface,
        borderRadius: BorderRadius.circular(Spacing.md),
        border: Border.all(color: FimmsColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const _ShimmerBox(width: 180, height: 16),
          SizedBox(height: Spacing.md),
          const _ShimmerBox(width: double.infinity, height: 12),
          SizedBox(height: Spacing.sm),
          const _ShimmerBox(width: double.infinity, height: 12),
          SizedBox(height: Spacing.sm),
          const _ShimmerBox(width: 120, height: 12),
        ],
      ),
    );
  }
}

/// List variant — repeats a row placeholder [items] times.
class _ShimmerList extends StatelessWidget {
  const _ShimmerList({required this.items});

  final int items;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(items, (index) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: index < items - 1 ? Spacing.sm : 0,
          ),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: Spacing.lg,
              vertical: Spacing.md,
            ),
            decoration: BoxDecoration(
              color: FimmsColors.surface,
              borderRadius: BorderRadius.circular(Spacing.sm),
              border: Border.all(color: FimmsColors.outline),
            ),
            child: Row(
              children: [
                const _ShimmerBox(width: 40, height: 40, borderRadius: 20),
                SizedBox(width: Spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _ShimmerBox(width: 140, height: 14),
                      SizedBox(height: Spacing.xs),
                      const _ShimmerBox(width: 200, height: 10),
                    ],
                  ),
                ),
                const _ShimmerBox(width: 48, height: 14),
              ],
            ),
          ),
        );
      }),
    );
  }
}

/// Stat variant — mimics a small KPI / stat card with a label and a value.
class _ShimmerStat extends StatelessWidget {
  const _ShimmerStat();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: FimmsColors.surface,
        borderRadius: BorderRadius.circular(Spacing.md),
        border: Border.all(color: FimmsColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const _ShimmerBox(width: 80, height: 10),
          SizedBox(height: Spacing.sm),
          const _ShimmerBox(width: 60, height: 24),
        ],
      ),
    );
  }
}
