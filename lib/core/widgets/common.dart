import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A white rounded card with the house shadow.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.colour,
    this.border,
    this.radius = AppRadii.lg,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? colour;
  final BoxBorder? border;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    final Widget content = Padding(padding: padding, child: child);

    // The card colour lives on a Material rather than on the outer decoration
    // so that ink splashes — and any ListTile placed inside — paint on top of
    // it instead of behind it. The border goes in foregroundDecoration so the
    // Material cannot cover it.
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: AppShadows.subtle,
      ),
      foregroundDecoration: border == null
          ? null
          : BoxDecoration(borderRadius: radius, border: border),
      child: Material(
        color: colour ?? AppColours.surface,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? content
            : InkWell(onTap: onTap, borderRadius: radius, child: content),
      ),
    );
  }
}

/// A heading with an optional trailing action, used above list sections.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: text.titleLarge?.copyWith(
                    color: AppColours.ink,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: text.bodySmall),
                ],
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

/// Small rounded label, e.g. "JAMB", "40 questions".
class Pill extends StatelessWidget {
  const Pill(
    this.label, {
    super.key,
    this.colour = AppColours.primary,
    this.icon,
    this.filled = false,
  });

  final String label;
  final Color colour;
  final IconData? icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? colour : colour.withValues(alpha: 0.10),
        borderRadius: AppRadii.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 13, color: filled ? Colors.white : colour),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: filled ? Colors.white : colour,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

/// Empty-state block for screens with nothing to show yet.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              height: 72,
              width: 72,
              decoration: const BoxDecoration(
                color: AppColours.primaryTint,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: AppColours.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: text.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(message, style: text.bodySmall, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(200, 48),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Horizontal progress bar with a label and a percentage.
class MeterRow extends StatelessWidget {
  const MeterRow({
    super.key,
    required this.label,
    required this.value,
    required this.colour,
    this.trailing,
  });

  final String label;
  final double value;
  final Color colour;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  style: text.labelMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                trailing ?? '${value.round()}%',
                style: text.labelMedium?.copyWith(color: colour),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: AppRadii.pill,
            child: LinearProgressIndicator(
              value: (value / 100).clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: AppColours.surfaceMuted,
              valueColor: AlwaysStoppedAnimation<Color>(colour),
            ),
          ),
        ],
      ),
    );
  }
}

/// The brand mark: a rounded square with the Eduvora "E" and a book glyph.
class PrepLogo extends StatelessWidget {
  const PrepLogo({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        gradient: AppColours.brandGradient,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: AppShadows.subtle,
      ),
      child: Icon(
        Icons.menu_book_rounded,
        color: Colors.white,
        size: size * 0.52,
      ),
    );
  }
}

/// Formats seconds as mm:ss (or h:mm:ss beyond an hour).
String formatDuration(int totalSeconds) {
  final int seconds = totalSeconds.clamp(0, 359999);
  final int hours = seconds ~/ 3600;
  final int minutes = (seconds % 3600) ~/ 60;
  final int secs = seconds % 60;
  final String mm = minutes.toString().padLeft(2, '0');
  final String ss = secs.toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$mm:$ss' : '$mm:$ss';
}
