import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:snapan_market/core/theme/tactile_shadows.dart';
import 'package:snapan_market/core/utils/formatters.dart';

/// Floating bottom dock bar for Marketplace Product Posts
///
/// Features:
/// - Left action: Secondary circular button to toggle comment/chat input bar
/// - Right action: Electric Indigo primary button displaying 'Beli Sekarang' + Formatted Price
class StickyBuyBar extends StatelessWidget {
  final int price;
  final int? originalPrice;
  final int? stockCount;
  final VoidCallback? onBuyClick;
  final VoidCallback? onChatClick;

  const StickyBuyBar({
    super.key,
    required this.price,
    this.originalPrice,
    this.stockCount,
    this.onBuyClick,
    this.onChatClick,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        bottom: bottomPadding > 0 ? bottomPadding + 8.0 : 16.0,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32.0),
          boxShadow: TactileShadows.lightOverlay,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
            child: Container(
              padding: const EdgeInsets.all(6.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32.0),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.75),
                    Colors.white.withValues(alpha: 0.48),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.90),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  // Left Secondary Button: "Tanya Penjual" (Chat icon)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        onChatClick?.call();
                      },
                      borderRadius: BorderRadius.circular(22.0),
                      child: Container(
                        width: 44.0,
                        height: 44.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0.85),
                              Colors.white.withValues(alpha: 0.60),
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.90),
                            width: 1.0,
                          ),
                        ),
                        child: const Icon(
                          LucideIcons.messageCircle,
                          size: 20.0,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ),

            const SizedBox(width: 8.0),

            // Right Primary Button: "Beli Sekarang" / "Produk Habis" + Price
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: (stockCount != null && stockCount! <= 0)
                      ? null
                      : () {
                          HapticFeedback.mediumImpact();
                          onBuyClick?.call();
                        },
                  borderRadius: BorderRadius.circular(24.0),
                  child: Container(
                    height: 44.0,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24.0),
                      gradient: (stockCount != null && stockCount! <= 0)
                          ? const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFF64748B),
                                Color(0xFF475569),
                              ],
                            )
                          : const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFF3B82F6), // Kumo Blue 500
                                Color(0xFF1D64EC), // Kumo Primary Blue
                              ],
                            ),
                      border: Border.all(
                        color: (stockCount != null && stockCount! <= 0)
                            ? const Color(0xFF475569)
                            : const Color(0xFF154EC1),
                        width: 1.0,
                      ),
                      boxShadow: (stockCount != null && stockCount! <= 0)
                          ? null
                          : const [
                              BoxShadow(
                                color: Color(0x2E1D64EC),
                                blurRadius: 3.0,
                                offset: Offset(0, 1),
                              ),
                            ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Inset Top Shine Highlight for Signature Kumo Glass Rim
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 1.0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.35),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(24.0),
                              ),
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Left Label with Credit Card icon
                              Row(
                                children: [
                                  Icon(
                                    (stockCount != null && stockCount! <= 0)
                                        ? Icons.remove_circle_outline_rounded
                                        : Icons.credit_card_rounded,
                                    size: 18.0,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8.0),
                                  Text(
                                    (stockCount != null && stockCount! <= 0)
                                        ? 'Produk Habis'
                                        : 'Beli Sekarang',
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      letterSpacing: -0.1,
                                    ),
                                  ),
                                ],
                              ),

                              // Right Formatted Price
                              Text(
                                price > 0 ? formatRupiah(price) : 'Tanya Harga',
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
