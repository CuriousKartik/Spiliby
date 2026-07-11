import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class EmptyState extends StatelessWidget {
  final IconData? icon;
  final String? imageAsset;
  final String title;
  final String? message;
  final Widget? action;

  const EmptyState({
    super.key,
    this.icon,
    this.imageAsset,
    required this.title,
    this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors(Theme.of(context).brightness == Brightness.dark);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 56),
      child: Column(
        children: [
          if (imageAsset != null)
            Image.asset(imageAsset!, width: 80, height: 80, fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => _iconBox(c))
          else
            _iconBox(c),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppFonts.display(size: 18, weight: FontWeight.w600, color: c.textPrimary),
          ),
          if (message != null) ...[
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 240),
              child: Text(
                message!,
                textAlign: TextAlign.center,
                style: AppFonts.body(size: 13, color: c.textSecondary),
              ),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: 20),
            action!,
          ],
        ],
      ),
    );
  }

  Widget _iconBox(AppColors c) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(color: c.chipBg, borderRadius: BorderRadius.circular(24)),
      child: icon != null ? Icon(icon, size: 34, color: c.textSecondary) : null,
    );
  }
}