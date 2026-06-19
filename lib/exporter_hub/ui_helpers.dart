// lib/exporter_hub/ui_helpers.dart
// Shared UI components for Phase 18 polish:
// skeleton loaders, empty states, error states, cached network images.

import 'package:flutter/material.dart';

// ── Skeleton shimmer block ────────────────────────────────────────────────────

class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 4,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: base.withValues(alpha: _anim.value),
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}

// ── Card-level skeleton ───────────────────────────────────────────────────────

class SkeletonCard extends StatelessWidget {
  final double height;
  const SkeletonCard({super.key, this.height = 100});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const SkeletonBox(width: 40, height: 40, borderRadius: 20),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
              SkeletonBox(height: 14, width: double.infinity),
              SizedBox(height: 6),
              SkeletonBox(height: 12, width: 140),
            ])),
          ]),
          const SizedBox(height: 10),
          const SkeletonBox(height: 12),
          const SizedBox(height: 6),
          const SkeletonBox(height: 12, width: 200),
        ]),
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  final int count;
  const SkeletonList({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: count,
      itemBuilder: (_, __) => const SkeletonCard(),
    );
  }
}

// ── Empty state widget ────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 72,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle!, textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ]),
      ),
    );
  }
}

// ── Error state widget ────────────────────────────────────────────────────────

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ]),
      ),
    );
  }
}

// ── Cached network image with loading/error fallback ──────────────────────────

class CachedProductImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;

  const CachedProductImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return placeholder ?? _Placeholder(width: width, height: height);
    }
    return Image.network(
      url!,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return SizedBox(
          width: width,
          height: height,
          child: Center(child: CircularProgressIndicator(
            value: progress.expectedTotalBytes != null
                ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                : null,
            strokeWidth: 2,
          )),
        );
      },
      errorBuilder: (_, __, ___) =>
          placeholder ?? _Placeholder(width: width, height: height),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final double? width;
  final double? height;
  const _Placeholder({this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(child: Icon(Icons.image_outlined,
          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4))),
    );
  }
}

// ── Responsive layout helper ──────────────────────────────────────────────────

class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double breakpoint;  // switch to grid above this width
  final int gridColumns;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.breakpoint = 600,
    this.gridColumns = 2,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= breakpoint) {
      return GridView.count(
        crossAxisCount: gridColumns,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.5,
        children: children,
      );
    }
    return Column(children: children);
  }
}

// ── Animated fade-in list item ────────────────────────────────────────────────

class FadeInItem extends StatefulWidget {
  final Widget child;
  final int index;
  const FadeInItem({super.key, required this.child, required this.index});

  @override
  State<FadeInItem> createState() => _FadeInItemState();
}

class _FadeInItemState extends State<FadeInItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300 + widget.index * 50),
    );
    _opacity = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _slide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
