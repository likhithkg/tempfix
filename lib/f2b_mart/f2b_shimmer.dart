// lib/f2b_mart/f2b_shimmer.dart
// Phase 10 — reusable shimmer skeleton widgets (no external package)

import 'package:flutter/material.dart';

// ── Shared shimmer animation wrapper ────────────────────────────────────────

class _Shimmer extends StatefulWidget {
  final Widget child;
  const _Shimmer({required this.child});

  @override
  State<_Shimmer> createState() => _ShimmerState();

  static _ShimmerState? of(BuildContext context) =>
      context.findAncestorStateOfType<_ShimmerState>();
}

class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  Animation<double> get shimmerAnimation => _anim;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// ── Shimmer box (single animated placeholder) ────────────────────────────────

class _ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  const _ShimmerBox({this.width, required this.height, this.radius = 8});

  @override
  Widget build(BuildContext context) {
    final state = _Shimmer.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (state == null) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(radius),
        ),
      );
    }

    return AnimatedBuilder(
      animation: state.shimmerAnimation,
      builder: (_, __) {
        final t = state.shimmerAnimation.value;
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + t * 2, 0),
              end: Alignment(t * 2, 0),
              colors: isDark
                  ? [
                      const Color(0xFF2A2A2A),
                      const Color(0xFF3D3D3D),
                      const Color(0xFF2A2A2A),
                    ]
                  : [
                      const Color(0xFFE0E0E0),
                      const Color(0xFFF5F5F5),
                      const Color(0xFFE0E0E0),
                    ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

// ── Grid card shimmer ────────────────────────────────────────────────────────

class F2BShimmerGrid extends StatelessWidget {
  final int count;
  const F2BShimmerGrid({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _Shimmer(
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.57,
        ),
        itemCount: count,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ShimmerBox(height: 125, radius: 16),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShimmerBox(height: 14, radius: 6),
                    const SizedBox(height: 8),
                    _ShimmerBox(width: 70, height: 18, radius: 6),
                    const SizedBox(height: 6),
                    _ShimmerBox(width: 50, height: 11, radius: 6),
                    const SizedBox(height: 8),
                    _ShimmerBox(height: 11, radius: 6),
                    const SizedBox(height: 6),
                    _ShimmerBox(height: 11, radius: 6),
                    const SizedBox(height: 10),
                    _ShimmerBox(height: 32, radius: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── List card shimmer ────────────────────────────────────────────────────────

class F2BShimmerList extends StatelessWidget {
  final int count;
  const F2BShimmerList({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _Shimmer(
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => Container(
          height: 90,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              _ShimmerBox(width: 90, height: 90, radius: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _ShimmerBox(height: 14, radius: 6),
                      _ShimmerBox(width: 80, height: 14, radius: 6),
                      _ShimmerBox(height: 11, radius: 6),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
