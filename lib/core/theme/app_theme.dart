import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Light
  static const Color primaryColor = Color(0xFF16A34A);
  static const Color secondaryColor = Color(0xFF15803D);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color surfaceColor = Colors.white;
  static const Color errorColor = Color(0xFFEF4444);
  static const Color successColor = Color(0xFF22C55E);

  // Dark
  static const Color primaryDark = Color(0xFF4ADE80);
  static const Color scaffoldDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color surfaceDark2 = Color(0xFF334155);

  static ThemeData get lightTheme => _build(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.light,
          primary: primaryColor,
          secondary: secondaryColor,
          surface: surfaceColor,
          error: errorColor,
        ),
        scaffoldBg: backgroundColor,
        cardBg: Colors.white,
        cardBorder: const Color(0xFFF1F5F9),
        inputFill: const Color(0xFFF1F5F9),
        inputBorder: const Color(0xFFE2E8F0),
        primary: primaryColor,
        appBarBg: Colors.white,
        appBarFg: const Color(0xFF1E293B),
        navBg: Colors.white,
        navIndicator: const Color(0x1A16A34A),
        navIconSelected: primaryColor,
        navIconUnselected: const Color(0xFF94A3B8),
        navLabelSelected: primaryColor,
        navLabelUnselected: const Color(0xFF94A3B8),
        snackBg: const Color(0xFF1E293B),
        dialogBg: Colors.white,
        sheetBg: Colors.white,
        dividerColor: const Color(0xFFF1F5F9),
        buttonFg: Colors.white,
        chipBorder: const Color(0xFFE2E8F0),
        chipBg: Colors.transparent,
        listTileBg: Colors.transparent,
      );

  static ThemeData get darkTheme => _build(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryDark,
          brightness: Brightness.dark,
          primary: primaryDark,
          secondary: primaryColor,
          surface: surfaceDark,
          error: errorColor,
        ),
        scaffoldBg: scaffoldDark,
        cardBg: surfaceDark,
        cardBorder: const Color(0xFF334155),
        inputFill: surfaceDark2,
        inputBorder: const Color(0xFF475569),
        primary: primaryDark,
        appBarBg: surfaceDark,
        appBarFg: const Color(0xFFF8FAFC),
        navBg: surfaceDark,
        navIndicator: const Color(0x264ADE80),
        navIconSelected: primaryDark,
        navIconUnselected: const Color(0xFF64748B),
        navLabelSelected: primaryDark,
        navLabelUnselected: const Color(0xFF64748B),
        snackBg: surfaceDark2,
        dialogBg: surfaceDark,
        sheetBg: surfaceDark,
        dividerColor: const Color(0xFF1E293B),
        buttonFg: scaffoldDark,
        chipBorder: const Color(0xFF475569),
        chipBg: surfaceDark2,
        listTileBg: surfaceDark,
      );

  static ThemeData _build({
    required ColorScheme colorScheme,
    required Color scaffoldBg,
    required Color cardBg,
    required Color cardBorder,
    required Color inputFill,
    required Color inputBorder,
    required Color primary,
    required Color appBarBg,
    required Color appBarFg,
    required Color navBg,
    required Color navIndicator,
    required Color navIconSelected,
    required Color navIconUnselected,
    required Color navLabelSelected,
    required Color navLabelUnselected,
    required Color snackBg,
    required Color dialogBg,
    required Color sheetBg,
    required Color dividerColor,
    required Color buttonFg,
    required Color chipBorder,
    required Color chipBg,
    required Color listTileBg,
  }) {
    final base = ThemeData(useMaterial3: true, colorScheme: colorScheme);
    final onSurface = colorScheme.onSurface;
    final onSurfaceMuted = colorScheme.onSurfaceVariant;

    return base.copyWith(
      scaffoldBackgroundColor: scaffoldBg,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(fontSize: 32, fontWeight: FontWeight.w800, color: onSurface),
        displayMedium: GoogleFonts.plusJakartaSans(fontSize: 26, fontWeight: FontWeight.w700, color: onSurface),
        headlineLarge: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w700, color: onSurface),
        headlineMedium: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: onSurface),
        headlineSmall: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: onSurface),
        titleLarge: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: onSurface),
        titleMedium: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: onSurface),
        titleSmall: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500, color: onSurface),
        bodyLarge: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w400, color: onSurface),
        bodyMedium: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w400, color: onSurface),
        bodySmall: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w400, color: onSurfaceMuted),
        labelLarge: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: onSurface),
        labelMedium: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: onSurfaceMuted),
        labelSmall: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5, color: onSurfaceMuted),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBg,
        foregroundColor: appBarFg,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0.5,
        shadowColor: Colors.black26,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700, color: appBarFg),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navBg,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        height: 72,
        indicatorColor: navIndicator,
        indicatorShape: const StadiumBorder(),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return IconThemeData(color: navIconSelected, size: 22);
          return IconThemeData(color: navIconUnselected, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: navLabelSelected);
          }
          return GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500, color: navLabelUnselected);
        }),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cardBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: inputBorder, width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: primary, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: errorColor, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: errorColor, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: TextStyle(color: onSurfaceMuted),
        hintStyle: TextStyle(color: onSurfaceMuted.withValues(alpha: 0.5)),
        floatingLabelStyle: TextStyle(color: primary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: buttonFg,
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: buttonFg,
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: BorderSide(color: primary, width: 1.5),
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500, color: onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(color: chipBorder),
        backgroundColor: chipBg,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      dividerTheme: DividerThemeData(color: dividerColor, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        tileColor: listTileBg == Colors.transparent ? null : listTileBg,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: buttonFg,
        elevation: 2,
        shape: const StadiumBorder(),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: snackBg,
        contentTextStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        backgroundColor: dialogBg,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: sheetBg,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        elevation: 0,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: ZoomPageTransitionsBuilder(allowEnterRouteSnapshotting: false),
        },
      ),
    );
  }
}
