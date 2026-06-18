import 'package:flutter/material.dart';
import '../theme.dart';

/// Compact icon + label button for card action rows.
/// [outlined] = true  → OutlinedButton style.
/// [outlined] = false → ElevatedButton style (default).
class KMActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final bool outlined;

  const KMActionButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.color,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    const compact = EdgeInsets.symmetric(
      horizontal: KMSpacing.md,
      vertical: KMSpacing.xs,
    );
    const ts = TextStyle(fontSize: 13, fontWeight: FontWeight.w600);

    if (outlined) {
      return OutlinedButton.icon(
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: c,
          side: BorderSide(color: c),
          padding: compact,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: ts,
        ),
        onPressed: onPressed,
      );
    }

    return ElevatedButton.icon(
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: c,
        foregroundColor: Colors.white,
        padding: compact,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: ts,
      ),
      onPressed: onPressed,
    );
  }
}

/// Small tinted icon button used as the "call" action inside listing cards.
class KMCallIconButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const KMCallIconButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: primary.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(KMRadius.sm),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(KMRadius.sm),
        child: Padding(
          padding: const EdgeInsets.all(KMSpacing.sm),
          child: Icon(Icons.phone, color: primary, size: 20),
        ),
      ),
    );
  }
}
