import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:snapan_market/core/services/supabase_service.dart';
import 'package:snapan_market/core/theme/app_colors.dart';

class SoldToResult {
  final String? userId;
  final String displayName;

  const SoldToResult({this.userId, required this.displayName});
}

class SoldToPickerSheet extends StatefulWidget {
  const SoldToPickerSheet({super.key});

  static Future<SoldToResult?> show(BuildContext context) {
    return showModalBottomSheet<SoldToResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SoldToPickerSheet(),
    );
  }

  @override
  State<SoldToPickerSheet> createState() => _SoldToPickerSheetState();
}

class _SoldToPickerSheetState extends State<SoldToPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _chatBuyers = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadPotentialBuyers();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPotentialBuyers() async {
    final buyers = await SupabaseService.instance.fetchPotentialBuyers();
    if (!mounted) return;
    setState(() {
      _chatBuyers = buyers;
      _isLoading = false;
    });
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final results = await SupabaseService.instance.searchProfilesForSoldPicker(trimmed);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    });
  }

  String _formatBuyerLabel(Map<String, dynamic> profile) {
    final username = profile['username']?.toString().trim();
    if (username != null && username.isNotEmpty) return '@$username';
    final display = profile['display_name']?.toString().trim();
    if (display != null && display.isNotEmpty) return display;
    return profile['full_name']?.toString().trim() ?? 'Siswa';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final hasQuery = _searchController.text.trim().isNotEmpty;
    final items = hasQuery ? _searchResults : _chatBuyers;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.78),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text(
                'Terjual ke siapa?',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.ink),
                decoration: InputDecoration(
                  hintText: 'Cari username atau nama siswa...',
                  hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.lightMuted),
                  prefixIcon: const Icon(LucideIcons.search, size: 18, color: AppColors.lightMuted),
                  filled: true,
                  fillColor: AppColors.inputBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryPastel,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(LucideIcons.store, size: 18, color: AppColors.primary),
              ),
              title: Text(
                'Terjual di luar Snaps',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              subtitle: Text(
                'Laku lewat COD langsung atau platform lain',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
              ),
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop(const SoldToResult(displayName: 'Di luar Snaps'));
              },
            ),
            const Divider(height: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
              child: Text(
                hasQuery ? 'Hasil Pencarian' : 'Pernah Chat dengan Kamu',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
            ),
            Flexible(
              child: (_isLoading || _isSearching)
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : items.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Text(
                              hasQuery
                                  ? 'Siswa tidak ditemukan'
                                  : 'Belum ada riwayat chat. Cari username di atas.',
                              style: GoogleFonts.inter(fontSize: 13, color: AppColors.lightMuted),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final profile = items[index];
                            final avatar = profile['avatar_url']?.toString() ?? '';
                            final name = profile['display_name']?.toString() ??
                                profile['full_name']?.toString() ??
                                'Siswa';
                            final username = profile['username']?.toString() ?? '';
                            final classGroup = profile['class_group']?.toString() ?? '';

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                              leading: CircleAvatar(
                                radius: 20,
                                backgroundColor: AppColors.divider,
                                backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                                child: avatar.isEmpty
                                    ? const Icon(LucideIcons.user, size: 18, color: AppColors.lightMuted)
                                    : null,
                              ),
                              title: Text(
                                name,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink,
                                ),
                              ),
                              subtitle: Text(
                                [
                                  if (username.isNotEmpty) '@$username',
                                  if (classGroup.isNotEmpty) classGroup,
                                ].join(' • '),
                                style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
                              ),
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.of(context).pop(
                                  SoldToResult(
                                    userId: profile['id']?.toString(),
                                    displayName: _formatBuyerLabel(profile),
                                  ),
                                );
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
