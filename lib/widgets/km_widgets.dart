import 'package:flutter/material.dart';
import '../theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// KMSearchBar — consistent search input used across all listing pages
// ─────────────────────────────────────────────────────────────────────────────

class KMSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  const KMSearchBar({
    super.key,
    this.controller,
    this.hintText = 'Search...',
    this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(
          Icons.search,
          color: Theme.of(context).colorScheme.primary,
        ),
        suffixIcon: onClear != null
            ? IconButton(
                icon: Icon(
                  Icons.clear,
                  color: Theme.of(context).colorScheme.outline,
                ),
                onPressed: () {
                  controller?.clear();
                  onClear!();
                },
              )
            : null,
      ),
      onChanged: onChanged,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KMNetworkImage — network image with loading/error states
// ─────────────────────────────────────────────────────────────────────────────

class KMNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? height;
  final double? width;
  final BoxFit fit;
  final Widget? placeholder;
  final double borderRadius;

  const KMNetworkImage({
    super.key,
    this.imageUrl,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.borderRadius = 0,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = placeholder ??
        Container(
          height: height,
          width: width,
          color: Theme.of(context).cardColor,
          child: Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.5),
              size: 32,
            ),
          ),
        );

    if (imageUrl == null || imageUrl!.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: fallback,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        imageUrl!,
        height: height,
        width: width,
        fit: fit,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            height: height,
            width: width,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stack) => fallback,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KMCard — themed card with consistent shadow, radius, and optional tap
// ─────────────────────────────────────────────────────────────────────────────

class KMCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final double elevation;

  const KMCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.elevation = 2,
  });

  @override
  Widget build(BuildContext context) {
    final inner = Padding(
      padding: padding ?? const EdgeInsets.all(KMSpacing.md),
      child: child,
    );

    return Card(
      elevation: elevation,
      color: color ?? Theme.of(context).cardColor,
      child: onTap != null
          ? InkWell(
              borderRadius: BorderRadius.circular(KMRadius.card),
              onTap: onTap,
              child: inner,
            )
          : inner,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KMCategoryChip — single themed choice chip
// ─────────────────────────────────────────────────────────────────────────────

class KMCategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;

  const KMCategoryChip({
    super.key,
    required this.label,
    required this.selected,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KMCategoryFilterBar — horizontal scrollable category chip row
// ─────────────────────────────────────────────────────────────────────────────

class KMCategoryFilterBar extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  const KMCategoryFilterBar({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: KMSpacing.lg),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: KMSpacing.sm),
        itemBuilder: (_, i) => KMCategoryChip(
          label: categories[i],
          selected: categories[i] == selected,
          onSelected: (_) => onSelected(categories[i]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KMSectionHeader — section title with optional trailing action
// ─────────────────────────────────────────────────────────────────────────────

class KMSectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;

  const KMSectionHeader({super.key, required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KMSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KMEmptyState — empty list placeholder
// ─────────────────────────────────────────────────────────────────────────────

class KMEmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  const KMEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KMSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.4),
            ),
            const SizedBox(height: KMSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: KMSpacing.lg),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KMStatusBadge — available / unavailable badge
// ─────────────────────────────────────────────────────────────────────────────

class KMStatusBadge extends StatelessWidget {
  final bool available;
  final String? trueLabel;
  final String? falseLabel;

  const KMStatusBadge({
    super.key,
    required this.available,
    this.trueLabel,
    this.falseLabel,
  });

  @override
  Widget build(BuildContext context) {
    final label =
        available ? (trueLabel ?? 'Available') : (falseLabel ?? 'Busy');
    final color =
        available ? KMColors.available : KMColors.unavailable;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(KMRadius.chip),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
