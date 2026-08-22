/// Design tokens taken from the Career Profile Figma frame.
///
/// Scoped to the profile feature rather than merged into `AppColors`, because
/// the rest of the app still runs on the older palette. If the whole app moves
/// to this design language, promote these into `core/constants` and delete this
/// file — the names are deliberately kept generic so that is a rename, not a
/// rewrite.
///
/// Type sizes are the Figma values scaled by 1.06 and rounded. The frame was
/// drawn on a 368pt-wide artboard standing in for a ~390pt phone, so the raw
/// values render about 6% small on a real device.
library;

import 'package:flutter/material.dart';

abstract final class ProfileDesign {
  /* ------------------------------------------------------------ colour --- */

  static const primary = Color(0xFF2563EB);
  static const heroFrom = Color(0xFF2F6BFF);
  static const heroTo = Color(0xFF1E4FD8);

  static const ink = Color(0xFF0F172A);
  static const body = Color(0xFF334155);
  static const muted = Color(0xFF64748B);
  static const faint = Color(0xFF94A3B8);

  static const border = Color(0xFFEEF0F4);
  static const surface = Color(0xFFFFFFFF);
  static const canvas = Color(0xFFF3F4F6);

  static const chipBg = Color(0xFFEEF3FF);
  static const chipMutedBg = Color(0xFFF1F5F9);
  static const chipMutedInk = Color(0xFF475569);
  static const tileBg = Color(0xFFF8FAFC);

  static const violet = Color(0xFF7C3AED);
  static const sky = Color(0xFF0EA5E9);
  static const online = Color(0xFF4ADE80);
  static const danger = Color(0xFFEF4444);

  static const avatarFrom = Color(0xFF93C5FD);
  static const avatarTo = Color(0xFF60A5FA);
  static const avatarInk = Color(0xFF0B2E8A);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [heroFrom, heroTo],
  );

  static const avatarGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [avatarFrom, avatarTo],
  );

  /* ------------------------------------------------------------ metric --- */

  static const pagePadding = 18.0;
  static const cardGap = 14.0;
  static const cardRadius = 20.0;
  static const cardPadding = 16.0;
  static const heroRadius = 26.0;
  static const iconBox = 36.0;
  static const iconBoxRadius = 12.0;

  /// Shadow under the hero card and the primary CTA.
  static List<BoxShadow> glow(Color color, {double y = 14, double blur = 28}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.28),
        offset: Offset(0, y),
        blurRadius: blur,
      ),
    ];
  }

  /* -------------------------------------------------------------- type --- */

  // The design specifies Inter. It is not bundled, so this stays null and the
  // platform default (Roboto / SF) is used. Drop Inter .ttf files into
  // assets/fonts, declare the family in pubspec.yaml, and set this to 'Inter'.
  static const String? fontFamily = null;

  static const appBarTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 19,
    fontWeight: FontWeight.w700,
    color: ink,
  );

  static const heroName = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    height: 1.21,
  );

  static const heroRole = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: Colors.white,
    height: 1.21,
  );

  static const heroPill = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  static const heroLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Colors.white,
  );

  static const heroPrompt = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    height: 1.21,
  );

  static const ringValue = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  static const avatarInitials = TextStyle(
    fontFamily: fontFamily,
    fontSize: 23,
    fontWeight: FontWeight.w700,
    color: avatarInk,
  );

  static const sectionTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: ink,
  );

  static const editLink = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: primary,
  );

  static const entryTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: ink,
    height: 1.21,
  );

  static const entryBody = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: muted,
    height: 1.21,
  );

  static const entryMeta = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: faint,
    height: 1.21,
  );

  static const chipLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: primary,
  );

  static const tileLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: muted,
  );

  static const tileValue = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: ink,
  );

  static const goalsBody = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: body,
    height: 1.66,
  );

  static const eyebrow = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: muted,
    letterSpacing: 0.25,
  );

  static const powerLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: ink,
    height: 1.3,
  );

  static const ctaLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  static const footnote = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: faint,
  );
}
