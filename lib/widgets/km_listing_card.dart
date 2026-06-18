import 'package:flutter/material.dart';
import '../theme.dart';
import 'km_widgets.dart';

/// Unified listing card used across Rent, Labour, Plant Vendor, Export Hub,
/// and all nearby-listing pages. Every card shares the same border radius,
/// padding, shadow, image widget, and typography hierarchy.
///
/// Layout (vertical, image-first):
///   ┌──────────────────────────────┐
///   │  [statusBadge]  [menuButton] │  ← overlaid on image
///   │        image area            │
///   ├──────────────────────────────┤
///   │  title  (titleSmall bold)    │
///   │  subtitle (bodyMedium)       │
///   │  caption  (bodySmall muted)  │
///   │  infoRow  (arbitrary)        │
///   │  actionRow (arbitrary)       │
///   └──────────────────────────────┘
class KMListingCard extends StatelessWidget {
  final String? imageUrl;
  final IconData fallbackIcon;
  final double imageHeight;

  final String title;
  final String? subtitle;
  final String? caption;

  /// Widget overlaid at top-left of the image (e.g. KMStatusChip).
  final Widget? statusBadge;

  /// Widget overlaid at top-right of the image (e.g. PopupMenuButton).
  final Widget? menuButton;

  /// Row of tags / chips shown below caption.
  final Widget? infoRow;

  /// Row of action buttons (call, edit, etc.) at the bottom of the card.
  final Widget? actionRow;

  final VoidCallback? onTap;

  /// When true the Column expands to fill its parent (use inside GridView).
  /// When false the Column wraps its content (use inside ListView).
  final bool fillHeight;

  const KMListingCard({
    super.key,
    this.imageUrl,
    this.fallbackIcon = Icons.image_outlined,
    this.imageHeight = 160,
    required this.title,
    this.subtitle,
    this.caption,
    this.statusBadge,
    this.menuButton,
    this.infoRow,
    this.actionRow,
    this.onTap,
    this.fillHeight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: fillHeight ? MainAxisSize.max : MainAxisSize.min,
      children: [
        // ── Image ─────────────────────────────────────────────────────────────
        Stack(
          children: [
            KMNetworkImage(
              imageUrl: imageUrl,
              height: imageHeight,
              width: double.infinity,
              borderRadius: 0,
              placeholder: SizedBox(
                height: imageHeight,
                child: ColoredBox(
                  color: theme.cardColor,
                  child: Center(
                    child: Icon(
                      fallbackIcon,
                      size: 40,
                      color: theme.colorScheme.primary.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              ),
            ),
            if (statusBadge != null)
              Positioned(
                top: KMSpacing.sm,
                left: KMSpacing.sm,
                child: statusBadge!,
              ),
            if (menuButton != null)
              Positioned(
                top: 0,
                right: 0,
                child: menuButton!,
              ),
          ],
        ),

        // ── Text content ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(KMSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: KMSpacing.xs),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              if (caption != null) ...[
                const SizedBox(height: KMSpacing.xs),
                Text(
                  caption!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
              if (infoRow != null) ...[
                const SizedBox(height: KMSpacing.sm),
                infoRow!,
              ],
              if (actionRow != null) ...[
                const SizedBox(height: KMSpacing.sm),
                actionRow!,
              ],
            ],
          ),
        ),
      ],
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: content,
      ),
    );
  }
}
