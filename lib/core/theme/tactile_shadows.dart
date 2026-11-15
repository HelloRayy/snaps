import 'package:flutter/material.dart';

/// Tactile Design System Shadows and Surfaces
/// Based on https://www.4hands.dev/tactile-design
/// 
/// Interfaces built with this system feel physical but quiet.
/// Hierarchy comes from contrast steps, fine 1px rings, and crisp drops,
/// rather than bold text, huge size jumps, or diffuse blurry shadows.
class TactileShadows {
  // Prevent instantiation
  const TactileShadows._();

  /// Raised surface (Secondary buttons, cards, pills) in Light Mode
  /// White surface + 1px subtle ring + crisp 1px drop
  static const List<BoxShadow> lightRaised = [
    // 1px subtle ring around the surface
    BoxShadow(
      color: Color(0x14111827), // ~8% ink
      blurRadius: 0.0,
      spreadRadius: 1.0,
      offset: Offset(0, 0),
    ),
    // Crisp 1px drop
    BoxShadow(
      color: Color(0x1F111827), // ~12% ink
      blurRadius: 2.0,
      spreadRadius: 0.0,
      offset: Offset(0, 1),
    ),
  ];

  /// Raised surface in Dark Mode
  /// 0.5px subtle outline + tight black drop
  static const List<BoxShadow> darkRaised = [
    BoxShadow(
      color: Color(0x24FFFFFF), // fine white outline
      blurRadius: 0.0,
      spreadRadius: 0.5,
      offset: Offset(0, 0),
    ),
    BoxShadow(
      color: Color(0x80000000), // 50% black drop
      blurRadius: 2.0,
      spreadRadius: 0.0,
      offset: Offset(0, 1),
    ),
  ];

  /// Overlay surface (Bottom sheets, dialogs, popovers, action bars) in Light Mode
  /// 1px ring + crisp tiered drop (no giant blurry diffuse clouds)
  static const List<BoxShadow> lightOverlay = [
    BoxShadow(
      color: Color(0x12111827), // ~7% ink ring
      blurRadius: 0.0,
      spreadRadius: 1.0,
      offset: Offset(0, 0),
    ),
    BoxShadow(
      color: Color(0x1A111827), // ~10% drop
      blurRadius: 8.0,
      spreadRadius: -2.0,
      offset: Offset(0, 4),
    ),
  ];

  /// Overlay surface in Dark Mode
  static const List<BoxShadow> darkOverlay = [
    BoxShadow(
      color: Color(0x26FFFFFF), // 15% white ring
      blurRadius: 0.0,
      spreadRadius: 0.5,
      offset: Offset(0, 0),
    ),
    BoxShadow(
      color: Color(0x99000000), // 60% black shadow
      blurRadius: 12.0,
      spreadRadius: -2.0,
      offset: Offset(0, 4),
    ),
  ];

  /// Primary button shadow (Light Mode)
  /// Crisp 1px drop that gives physical weight to the black or indigo primary
  static const List<BoxShadow> primaryButton = [
    BoxShadow(
      color: Color(0x26000000),
      blurRadius: 2.0,
      spreadRadius: 0.0,
      offset: Offset(0, 1),
    ),
  ];

  /// Adaptive raised shadow based on current theme brightness
  static List<BoxShadow> adaptiveRaised(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkRaised : lightRaised;
  }

  /// Adaptive overlay shadow based on current theme brightness
  static List<BoxShadow> adaptiveOverlay(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkOverlay : lightOverlay;
  }
}
