// ==========================================
// ARCHIVO: lib/core/app_themes.dart
// ==========================================

import 'package:flutter/material.dart';

enum AppPalette {
  blackGold,
  royalSapphire,
  theNest,
  financialStability,
}

/// Extensión personalizada para colores específicos del diseño (Hero Cards, Savings Pill, Borders, FAB)
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final Color heroCardBg;
  final Color heroCardBorder;
  final Color heroCardText;
  final Color heroCardAccent;
  final Color cardBaseBg;
  final Color cardBaseBorder;
  final Color cardBaseText;
  final Color cardAccentText;
  final Color btnBg;
  final Color btnBorder;
  final Color btnColor;
  final Color summaryBg;
  final Color summaryBorder;
  final Color summaryBoxBg;
  final Color savingsBg;
  final Color savingsText;
  final Color pillBg;
  final Color pillBorder;
  final Color pillText;
  final Color fabBg;
  final Color fabText;
  final Color navBg;
  final Color navBorder;
  final Color navActivePill;
  final Color navActiveColor;
  final Color navInactiveColor;
  final Color navIndicator;

  const AppThemeColors({
    required this.heroCardBg,
    required this.heroCardBorder,
    required this.heroCardText,
    required this.heroCardAccent,
    required this.cardBaseBg,
    required this.cardBaseBorder,
    required this.cardBaseText,
    required this.cardAccentText,
    required this.btnBg,
    required this.btnBorder,
    required this.btnColor,
    required this.summaryBg,
    required this.summaryBorder,
    required this.summaryBoxBg,
    required this.savingsBg,
    required this.savingsText,
    required this.pillBg,
    required this.pillBorder,
    required this.pillText,
    required this.fabBg,
    required this.fabText,
    required this.navBg,
    required this.navBorder,
    required this.navActivePill,
    required this.navActiveColor,
    required this.navInactiveColor,
    required this.navIndicator,
  });

  @override
  AppThemeColors copyWith({
    Color? heroCardBg,
    Color? heroCardBorder,
    Color? heroCardText,
    Color? heroCardAccent,
    Color? cardBaseBg,
    Color? cardBaseBorder,
    Color? cardBaseText,
    Color? cardAccentText,
    Color? btnBg,
    Color? btnBorder,
    Color? btnColor,
    Color? summaryBg,
    Color? summaryBorder,
    Color? summaryBoxBg,
    Color? savingsBg,
    Color? savingsText,
    Color? pillBg,
    Color? pillBorder,
    Color? pillText,
    Color? fabBg,
    Color? fabText,
    Color? navBg,
    Color? navBorder,
    Color? navActivePill,
    Color? navActiveColor,
    Color? navInactiveColor,
    Color? navIndicator,
  }) {
    return AppThemeColors(
      heroCardBg: heroCardBg ?? this.heroCardBg,
      heroCardBorder: heroCardBorder ?? this.heroCardBorder,
      heroCardText: heroCardText ?? this.heroCardText,
      heroCardAccent: heroCardAccent ?? this.heroCardAccent,
      cardBaseBg: cardBaseBg ?? this.cardBaseBg,
      cardBaseBorder: cardBaseBorder ?? this.cardBaseBorder,
      cardBaseText: cardBaseText ?? this.cardBaseText,
      cardAccentText: cardAccentText ?? this.cardAccentText,
      btnBg: btnBg ?? this.btnBg,
      btnBorder: btnBorder ?? this.btnBorder,
      btnColor: btnColor ?? this.btnColor,
      summaryBg: summaryBg ?? this.summaryBg,
      summaryBorder: summaryBorder ?? this.summaryBorder,
      summaryBoxBg: summaryBoxBg ?? this.summaryBoxBg,
      savingsBg: savingsBg ?? this.savingsBg,
      savingsText: savingsText ?? this.savingsText,
      pillBg: pillBg ?? this.pillBg,
      pillBorder: pillBorder ?? this.pillBorder,
      pillText: pillText ?? this.pillText,
      fabBg: fabBg ?? this.fabBg,
      fabText: fabText ?? this.fabText,
      navBg: navBg ?? this.navBg,
      navBorder: navBorder ?? this.navBorder,
      navActivePill: navActivePill ?? this.navActivePill,
      navActiveColor: navActiveColor ?? this.navActiveColor,
      navInactiveColor: navInactiveColor ?? this.navInactiveColor,
      navIndicator: navIndicator ?? this.navIndicator,
    );
  }

  @override
  ThemeExtension<AppThemeColors> lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) return this;
    return AppThemeColors(
      heroCardBg: Color.lerp(heroCardBg, other.heroCardBg, t)!,
      heroCardBorder: Color.lerp(heroCardBorder, other.heroCardBorder, t)!,
      heroCardText: Color.lerp(heroCardText, other.heroCardText, t)!,
      heroCardAccent: Color.lerp(heroCardAccent, other.heroCardAccent, t)!,
      cardBaseBg: Color.lerp(cardBaseBg, other.cardBaseBg, t)!,
      cardBaseBorder: Color.lerp(cardBaseBorder, other.cardBaseBorder, t)!,
      cardBaseText: Color.lerp(cardBaseText, other.cardBaseText, t)!,
      cardAccentText: Color.lerp(cardAccentText, other.cardAccentText, t)!,
      btnBg: Color.lerp(btnBg, other.btnBg, t)!,
      btnBorder: Color.lerp(btnBorder, other.btnBorder, t)!,
      btnColor: Color.lerp(btnColor, other.btnColor, t)!,
      summaryBg: Color.lerp(summaryBg, other.summaryBg, t)!,
      summaryBorder: Color.lerp(summaryBorder, other.summaryBorder, t)!,
      summaryBoxBg: Color.lerp(summaryBoxBg, other.summaryBoxBg, t)!,
      savingsBg: Color.lerp(savingsBg, other.savingsBg, t)!,
      savingsText: Color.lerp(savingsText, other.savingsText, t)!,
      pillBg: Color.lerp(pillBg, other.pillBg, t)!,
      pillBorder: Color.lerp(pillBorder, other.pillBorder, t)!,
      pillText: Color.lerp(pillText, other.pillText, t)!,
      fabBg: Color.lerp(fabBg, other.fabBg, t)!,
      fabText: Color.lerp(fabText, other.fabText, t)!,
      navBg: Color.lerp(navBg, other.navBg, t)!,
      navBorder: Color.lerp(navBorder, other.navBorder, t)!,
      navActivePill: Color.lerp(navActivePill, other.navActivePill, t)!,
      navActiveColor: Color.lerp(navActiveColor, other.navActiveColor, t)!,
      navInactiveColor: Color.lerp(navInactiveColor, other.navInactiveColor, t)!,
      navIndicator: Color.lerp(navIndicator, other.navIndicator, t)!,
    );
  }
}

class AppThemes {
  // ===========================================================================
  // 1. BLACK & GOLD (#141414, #2B2B2B, #C9A227, #F6F1E4)
  // ===========================================================================
  static final AppThemeColors blackGoldDarkColors = AppThemeColors(
    heroCardBg: const Color(0xFF2B2B2B),
    heroCardBorder: const Color(0x44C9A227),
    heroCardText: const Color(0xFFF6F1E4),
    heroCardAccent: const Color(0xFFC9A227),
    cardBaseBg: const Color(0xFF2B2B2B),
    cardBaseBorder: const Color(0xFF3D3D3D),
    cardBaseText: const Color(0xFFF6F1E4),
    cardAccentText: const Color(0xFFC9A227),
    btnBg: const Color(0xFF2B2B2B),
    btnBorder: const Color(0x55C9A227),
    btnColor: const Color(0xFFC9A227),
    summaryBg: const Color(0xFF141414),
    summaryBorder: const Color(0xFF2B2B2B),
    summaryBoxBg: const Color(0xFF2B2B2B),
    savingsBg: const Color(0xFFC9A227),
    savingsText: const Color(0xFF141414),
    pillBg: const Color(0xFF222222),
    pillBorder: const Color(0xFF3A3A3A),
    pillText: const Color(0xFFF6F1E4),
    fabBg: const Color(0xFFC9A227),
    fabText: const Color(0xFF141414),
    navBg: const Color(0xFF141414),
    navBorder: const Color(0xFF2B2B2B),
    navActivePill: const Color(0xFF2B2B2B),
    navActiveColor: const Color(0xFFC9A227),
    navInactiveColor: const Color(0xFF6E6B64),
    navIndicator: const Color(0xFFC9A227),
  );

  static final AppThemeColors blackGoldLightColors = AppThemeColors(
    heroCardBg: const Color(0xFF141414),
    heroCardBorder: Colors.transparent,
    heroCardText: const Color(0xFFF6F1E4),
    heroCardAccent: const Color(0xFFC9A227),
    cardBaseBg: const Color(0xFFFFFFFF),
    cardBaseBorder: const Color(0xFFE6DFCF),
    cardBaseText: const Color(0xFF141414),
    cardAccentText: const Color(0xFFC9A227),
    btnBg: const Color(0xFFFFFFFF),
    btnBorder: const Color(0x77C9A227),
    btnColor: const Color(0xFF141414),
    summaryBg: const Color(0xFFFFFFFF),
    summaryBorder: const Color(0xFFE6DFCF),
    summaryBoxBg: const Color(0xFFF6F1E4),
    savingsBg: const Color(0xFF141414),
    savingsText: const Color(0xFFC9A227),
    pillBg: const Color(0xFFECE6D8),
    pillBorder: const Color(0xFFDCD4C3),
    pillText: const Color(0xFF141414),
    fabBg: const Color(0xFF141414),
    fabText: const Color(0xFFC9A227),
    navBg: const Color(0xFFFFFFFF),
    navBorder: const Color(0xFFE6DFCF),
    navActivePill: const Color(0xFFF6F1E4),
    navActiveColor: const Color(0xFFC9A227),
    navInactiveColor: const Color(0xFF9E9A90),
    navIndicator: const Color(0xFF141414),
  );

  // ===========================================================================
  // 2. ROYAL SAPPHIRE (#0E2A47, #1E4C7C, #C9A227, #F2EFE8)
  // ===========================================================================
  static final AppThemeColors royalSapphireDarkColors = AppThemeColors(
    heroCardBg: const Color(0xFF1E4C7C),
    heroCardBorder: const Color(0x44C9A227),
    heroCardText: const Color(0xFFF2EFE8),
    heroCardAccent: const Color(0xFFC9A227),
    cardBaseBg: const Color(0xFF091D31),
    cardBaseBorder: const Color(0xFF1E4C7C),
    cardBaseText: const Color(0xFFF2EFE8),
    cardAccentText: const Color(0xFFC9A227),
    btnBg: const Color(0xFF091D31),
    btnBorder: const Color(0xFF1E4C7C),
    btnColor: const Color(0xFFC9A227),
    summaryBg: const Color(0xFF091D31),
    summaryBorder: const Color(0xFF1E4C7C),
    summaryBoxBg: const Color(0xFF133355),
    savingsBg: const Color(0xFFC9A227),
    savingsText: const Color(0xFF0E2A47),
    pillBg: const Color(0xFF0A233D),
    pillBorder: const Color(0xFF1A426D),
    pillText: const Color(0xFFF2EFE8),
    fabBg: const Color(0xFFC9A227),
    fabText: const Color(0xFF0E2A47),
    navBg: const Color(0xFF071728),
    navBorder: const Color(0xFF133355),
    navActivePill: const Color(0xFF133355),
    navActiveColor: const Color(0xFFC9A227),
    navInactiveColor: const Color(0xFF6281A1),
    navIndicator: const Color(0xFFC9A227),
  );

  static final AppThemeColors royalSapphireLightColors = AppThemeColors(
    heroCardBg: const Color(0xFF0E2A47),
    heroCardBorder: Colors.transparent,
    heroCardText: const Color(0xFFF2EFE8),
    heroCardAccent: const Color(0xFFC9A227),
    cardBaseBg: const Color(0xFFFFFFFF),
    cardBaseBorder: const Color(0xFFDED8CB),
    cardBaseText: const Color(0xFF0E2A47),
    cardAccentText: const Color(0xFF1E4C7C),
    btnBg: const Color(0xFFFFFFFF),
    btnBorder: const Color(0x441E4C7C),
    btnColor: const Color(0xFF0E2A47),
    summaryBg: const Color(0xFFFFFFFF),
    summaryBorder: const Color(0xFFDED8CB),
    summaryBoxBg: const Color(0xFFE8E3D8),
    savingsBg: const Color(0xFF0E2A47),
    savingsText: const Color(0xFFC9A227),
    pillBg: const Color(0xFFE4DFD3),
    pillBorder: const Color(0xFFCFC7B8),
    pillText: const Color(0xFF0E2A47),
    fabBg: const Color(0xFF0E2A47),
    fabText: const Color(0xFFC9A227),
    navBg: const Color(0xFFFFFFFF),
    navBorder: const Color(0xFFDED8CB),
    navActivePill: const Color(0xFFF2EFE8),
    navActiveColor: const Color(0xFF0E2A47),
    navInactiveColor: const Color(0xFF92A4B8),
    navIndicator: const Color(0xFF0E2A47),
  );

  // ===========================================================================
  // 3. THE NEST (PEACOCK & GOLD) (#0F6B6D, #F8F8F5, #D4AF37)
  // ===========================================================================
  static final AppThemeColors theNestDarkColors = AppThemeColors(
    heroCardBg: const Color(0xFF0F6B6D),
    heroCardBorder: const Color(0x44D4AF37),
    heroCardText: const Color(0xFFF8F8F5),
    heroCardAccent: const Color(0xFFD4AF37),
    cardBaseBg: const Color(0xFF0E3436),
    cardBaseBorder: const Color(0xFF164F52),
    cardBaseText: const Color(0xFFF8F8F5),
    cardAccentText: const Color(0xFFD4AF37),
    btnBg: const Color(0xFF0E3436),
    btnBorder: const Color(0x55D4AF37),
    btnColor: const Color(0xFFD4AF37),
    summaryBg: const Color(0xFF071F20),
    summaryBorder: const Color(0xFF164F52),
    summaryBoxBg: const Color(0xFF0E3436),
    savingsBg: const Color(0xFFD4AF37),
    savingsText: const Color(0xFF0A2527),
    pillBg: const Color(0xFF0D2F31),
    pillBorder: const Color(0xFF175457),
    pillText: const Color(0xFFF8F8F5),
    fabBg: const Color(0xFFD4AF37),
    fabText: const Color(0xFF0A2527),
    navBg: const Color(0xFF071F20),
    navBorder: const Color(0xFF164F52),
    navActivePill: const Color(0xFF0E3436),
    navActiveColor: const Color(0xFFD4AF37),
    navInactiveColor: const Color(0xFF618B8D),
    navIndicator: const Color(0xFFD4AF37),
  );

  static final AppThemeColors theNestLightColors = AppThemeColors(
    heroCardBg: const Color(0xFF0F6B6D),
    heroCardBorder: Colors.transparent,
    heroCardText: const Color(0xFFF8F8F5),
    heroCardAccent: const Color(0xFFD4AF37),
    cardBaseBg: const Color(0xFFFFFFFF),
    cardBaseBorder: const Color(0xFFE2E2DA),
    cardBaseText: const Color(0xFF0F6B6D),
    cardAccentText: const Color(0xFFD4AF37),
    btnBg: const Color(0xFFFFFFFF),
    btnBorder: const Color(0x66D4AF37),
    btnColor: const Color(0xFF0F6B6D),
    summaryBg: const Color(0xFFFFFFFF),
    summaryBorder: const Color(0xFFE2E2DA),
    summaryBoxBg: const Color(0xFFEEF3F1),
    savingsBg: const Color(0xFF0F6B6D),
    savingsText: const Color(0xFFD4AF37),
    pillBg: const Color(0xFFE8ECE7),
    pillBorder: const Color(0xFFD4DAD3),
    pillText: const Color(0xFF0F6B6D),
    fabBg: const Color(0xFF0F6B6D),
    fabText: const Color(0xFFF8F8F5),
    navBg: const Color(0xFFFFFFFF),
    navBorder: const Color(0xFFE2E2DA),
    navActivePill: const Color(0xFFF8F8F5),
    navActiveColor: const Color(0xFFD4AF37),
    navInactiveColor: const Color(0xFF8FAAAA),
    navIndicator: const Color(0xFF0F6B6D),
  );

  // ===========================================================================
  // 4. FINANCIAL STABILITY (#0A3C6E, #FFFFFF, #1783C1, #333333)
  // ===========================================================================
  static final AppThemeColors financialStabilityDarkColors = AppThemeColors(
    heroCardBg: const Color(0xFF0A3C6E),
    heroCardBorder: const Color(0x551783C1),
    heroCardText: const Color(0xFFFFFFFF),
    heroCardAccent: const Color(0xFFFFFFFF),
    cardBaseBg: const Color(0xFF333333),
    cardBaseBorder: const Color(0xFF444444),
    cardBaseText: const Color(0xFFFFFFFF),
    cardAccentText: const Color(0xFF1783C1),
    btnBg: const Color(0xFF333333),
    btnBorder: const Color(0x551783C1),
    btnColor: const Color(0xFF1783C1),
    summaryBg: const Color(0xFF272727),
    summaryBorder: const Color(0xFF3D3D3D),
    summaryBoxBg: const Color(0xFF333333),
    savingsBg: const Color(0xFF1783C1),
    savingsText: const Color(0xFFFFFFFF),
    pillBg: const Color(0xFF2A2A2A),
    pillBorder: const Color(0xFF444444),
    pillText: const Color(0xFFFFFFFF),
    fabBg: const Color(0xFF1783C1),
    fabText: const Color(0xFFFFFFFF),
    navBg: const Color(0xFF222222),
    navBorder: const Color(0xFF333333),
    navActivePill: const Color(0xFF333333),
    navActiveColor: const Color(0xFF1783C1),
    navInactiveColor: const Color(0xFF777777),
    navIndicator: const Color(0xFF1783C1),
  );

  static final AppThemeColors financialStabilityLightColors = AppThemeColors(
    heroCardBg: const Color(0xFF0A3C6E),
    heroCardBorder: Colors.transparent,
    heroCardText: const Color(0xFFFFFFFF),
    heroCardAccent: const Color(0xFFFFFFFF),
    cardBaseBg: const Color(0xFFFFFFFF),
    cardBaseBorder: const Color(0xFFDBE4EC),
    cardBaseText: const Color(0xFF333333),
    cardAccentText: const Color(0xFF1783C1),
    btnBg: const Color(0xFFFFFFFF),
    btnBorder: const Color(0x441783C1),
    btnColor: const Color(0xFF0A3C6E),
    summaryBg: const Color(0xFFFFFFFF),
    summaryBorder: const Color(0xFFDBE4EC),
    summaryBoxBg: const Color(0xFFEAF1F7),
    savingsBg: const Color(0xFF0A3C6E),
    savingsText: const Color(0xFFFFFFFF),
    pillBg: const Color(0xFFE4ECF3),
    pillBorder: const Color(0xFFCDD9E5),
    pillText: const Color(0xFF333333),
    fabBg: const Color(0xFF0A3C6E),
    fabText: const Color(0xFFFFFFFF),
    navBg: const Color(0xFFFFFFFF),
    navBorder: const Color(0xFFDBE4EC),
    navActivePill: const Color(0xFFEAF1F7),
    navActiveColor: const Color(0xFF1783C1),
    navInactiveColor: const Color(0xFF8C9DAE),
    navIndicator: const Color(0xFF0A3C6E),
  );

  // ===========================================================================
  // CONSTRUCTOR DE THEMEDATA
  // ===========================================================================
  static ThemeData getTheme(AppPalette palette, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    AppThemeColors customColors;
    Color bgScreen;
    Color primaryColor;
    Color surfaceColor;
    Color textColor;
    Color textMutedColor;

    switch (palette) {
      case AppPalette.blackGold:
        customColors = isDark ? blackGoldDarkColors : blackGoldLightColors;
        bgScreen = isDark ? const Color(0xFF141414) : const Color(0xFFF6F1E4);
        primaryColor = const Color(0xFFC9A227);
        surfaceColor = isDark ? const Color(0xFF2B2B2B) : const Color(0xFFFFFFFF);
        textColor = isDark ? const Color(0xFFF6F1E4) : const Color(0xFF141414);
        textMutedColor = isDark ? const Color(0xFF9E9A90) : const Color(0xFF6B675E);
        break;

      case AppPalette.royalSapphire:
        customColors = isDark ? royalSapphireDarkColors : royalSapphireLightColors;
        bgScreen = isDark ? const Color(0xFF0E2A47) : const Color(0xFFF2EFE8);
        primaryColor = isDark ? const Color(0xFFC9A227) : const Color(0xFF0E2A47);
        surfaceColor = isDark ? const Color(0xFF091D31) : const Color(0xFFFFFFFF);
        textColor = isDark ? const Color(0xFFF2EFE8) : const Color(0xFF0E2A47);
        textMutedColor = isDark ? const Color(0xFF95AFC8) : const Color(0xFF566F8A);
        break;

      case AppPalette.theNest:
        customColors = isDark ? theNestDarkColors : theNestLightColors;
        bgScreen = isDark ? const Color(0xFF0A2527) : const Color(0xFFF8F8F5);
        primaryColor = isDark ? const Color(0xFFD4AF37) : const Color(0xFF0F6B6D);
        surfaceColor = isDark ? const Color(0xFF0E3436) : const Color(0xFFFFFFFF);
        textColor = isDark ? const Color(0xFFF8F8F5) : const Color(0xFF0F6B6D);
        textMutedColor = isDark ? const Color(0xFF85ACAE) : const Color(0xFF648A8B);
        break;

      case AppPalette.financialStability:
        customColors = isDark ? financialStabilityDarkColors : financialStabilityLightColors;
        bgScreen = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF4F7FA);
        primaryColor = const Color(0xFF1783C1);
        surfaceColor = isDark ? const Color(0xFF333333) : const Color(0xFFFFFFFF);
        textColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF333333);
        textMutedColor = isDark ? const Color(0xFF9BA7B4) : const Color(0xFF647586);
        break;
    }

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primaryColor,
      onPrimary: isDark ? const Color(0xFF141414) : Colors.white,
      primaryContainer: customColors.heroCardBg,
      onPrimaryContainer: customColors.heroCardText,
      secondary: customColors.cardAccentText,
      onSecondary: Colors.white,
      surface: surfaceColor,
      onSurface: textColor,
      onSurfaceVariant: textMutedColor,
      outline: customColors.cardBaseBorder,
      outlineVariant: customColors.cardBaseBorder.withAlpha(isDark ? 90 : 160),
      surfaceContainerHighest: customColors.pillBg,
      error: isDark ? const Color(0xFFFF6B6B) : const Color(0xFFDC2626),
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bgScreen,
      fontFamily: 'Plus Jakarta Sans',
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: customColors.cardBaseBorder),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgScreen,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: isDark ? customColors.cardAccentText : textColor,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(
          color: isDark ? customColors.cardAccentText : textColor,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: customColors.navBg,
        elevation: 0,
        indicatorColor: customColors.navActivePill,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: customColors.navActiveColor,
            );
          }
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: customColors.navInactiveColor,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: customColors.navActiveColor, size: 22);
          }
          return IconThemeData(color: customColors.navInactiveColor, size: 22);
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: customColors.fabBg,
        foregroundColor: customColors.fabText,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      extensions: [customColors],
    );
  }
}