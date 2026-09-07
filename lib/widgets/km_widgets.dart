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
// KMShimmerBox — unified animated shimmer placeholder
// ─────────────────────────────────────────────────────────────────────────────

class KMShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const KMShimmerBox({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = KMRadius.sm,
  });

  @override
  State<KMShimmerBox> createState() => _KMShimmerBoxState();
}

class _KMShimmerBoxState extends State<KMShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.25, end: 0.65).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
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

// ─────────────────────────────────────────────────────────────────────────────
// KMShimmerCard — full card-shaped shimmer for list/grid loading
// ─────────────────────────────────────────────────────────────────────────────

class KMShimmerCard extends StatelessWidget {
  final double width;
  final double height;
  final double imageHeight;

  const KMShimmerCard({
    super.key,
    this.width = 142,
    this.height = double.infinity,
    this.imageHeight = 106,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(KMRadius.card),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          KMShimmerBox(width: width, height: imageHeight, borderRadius: 0),
          Padding(
            padding: const EdgeInsets.all(KMSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KMShimmerBox(width: width * 0.75, height: 12),
                const SizedBox(height: KMSpacing.xs),
                KMShimmerBox(width: width * 0.5, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KMProfileAvatar — circular avatar with network image + initials fallback
// ─────────────────────────────────────────────────────────────────────────────

class KMProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const KMProfileAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.radius = 24,
    this.backgroundColor,
    this.onTap,
  });

  String get _initial =>
      name.isNotEmpty ? name.trim()[0].toUpperCase() : '?';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = backgroundColor ?? cs.primaryContainer;
    Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      backgroundImage:
          (imageUrl != null && imageUrl!.isNotEmpty) ? NetworkImage(imageUrl!) : null,
      child: (imageUrl == null || imageUrl!.isEmpty)
          ? Text(
              _initial,
              style: TextStyle(
                color: cs.onPrimaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.7,
              ),
            )
          : null,
    );

    if (onTap != null) {
      avatar = GestureDetector(onTap: onTap, child: avatar);
    }
    return avatar;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KMModuleHeader — gradient header reused by Rent, Labour, Exporter, etc.
// ─────────────────────────────────────────────────────────────────────────────

class KMModuleHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final LinearGradient gradient;
  final List<Widget>? actions;
  final Widget? bottom;
  final bool showBack;

  const KMModuleHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.gradient,
    this.actions,
    this.bottom,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
              child: Row(
                children: [
                  if (showBack)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                      onPressed: () => Navigator.maybePop(context),
                    )
                  else
                    const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (actions != null) ...actions!,
                ],
              ),
            ),
            if (bottom != null) bottom!,
            const SizedBox(height: KMSpacing.md),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KMFullWidthButton — full-width primary/secondary button with loading state
// ─────────────────────────────────────────────────────────────────────────────

class KMFullWidthButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool outlined;
  final IconData? icon;
  final Color? color;

  const KMFullWidthButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.outlined = false,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    final child = loading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        : icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18),
                  const SizedBox(width: KMSpacing.sm),
                  Text(label),
                ],
              )
            : Text(label);

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(KMRadius.button),
    );

    if (outlined) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: loading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: c,
            side: BorderSide(color: c, width: 1.5),
            shape: shape,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: child,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: c,
          foregroundColor: Colors.white,
          shape: shape,
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 2,
        ),
        child: child,
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
