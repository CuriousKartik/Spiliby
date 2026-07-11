import 'package:flutter/material.dart';


class AppColors {
  final bool isDark;
  const AppColors(this.isDark);

  // Page background. 
  Color get pageBg => isDark ? const Color(0xFF0A0F1A) : const Color(0xFFF0EBD8);

  // Card surface. 
  Color get cardBg => isDark ? const Color(0xFF172436) : Colors.white;

  // Card border. 
  Color get cardBorder => isDark ? const Color(0xFF111B29) : const Color(0x99F3F5F8);

  // Primary text
  Color get textPrimary => isDark ? const Color(0xFFF2EEDF) : const Color(0xFF0D1321);

  // Secondary text (labels, meta).
  Color get textSecondary => isDark ? const Color(0xFF8FA2BC) : const Color(0xFF3E5C76);

  // Tertiary / muted text. text-dusty-denim-500 (same both modes)
  Color get textMuted => const Color(0xFF748CAB);
  Color get textMutedLight => isDark ? const Color(0xFF8FA2BC) : const Color(0xFF748CAB);

  // Primary accent 
  Color get accent => const Color(0xFF3E5C76);
  Color get accentHover => const Color(0xFF547DA0);

  // Text/icon color 
  Color get onAccent => const Color(0xFFF0EBD8);

  // Disabled button bg.
  Color get disabledBg => isDark ? const Color(0xFF0C121B) : const Color(0xFFE7EBF1);

  // Icon / pill background chips. 
  Color get chipBg => isDark ? const Color(0xFF111B29) : const Color(0xFFF3F5F8);

  // Input surface. 
  Color get inputBg => isDark ? const Color(0xFF111B29) : Colors.white;

  // Input border. border-dusty-denim-200 dark:border-deep-space-blue-200
  Color get inputBorder => isDark ? const Color(0xFF0C121B) : const Color(0xFFE7EBF1);

  // Bottom nav bg. bg-white/90 dark:bg-deep-space-blue-400/90
  Color get navBg => isDark ? const Color(0xE6172436) : const Color(0xE6FFFFFF);
  Color get navBorder => isDark ? const Color(0xFF111B29) : const Color(0xFFF3F5F8);

  Color get inactiveNav => isDark ? const Color(0xFF3E5C76) : const Color(0xFF748CAB);

  // Semantic colours (Tailwind defaults used directly in the app)
  Color get success => const Color(0xFF059669); // emerald-600
  Color get successBg => const Color(0x26059669);
  Color get danger => const Color(0xFFEF4444); // red-500
  Color get dangerBg => const Color(0x1AEF4444);

  Color get modalScrim => const Color(0x800D1321);
  Color get modalBg => isDark ? const Color(0xFF172436) : const Color(0xFFF0EBD8);
}