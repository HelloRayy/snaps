import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:snapan_market/core/components/avatar/default_profile_avatar.dart';
import 'package:snapan_market/core/services/supabase_service.dart';
import 'package:snapan_market/core/theme/app_colors.dart';

/// Floating suggestion card list for autocompleting @mentions
class MentionSuggestionList extends StatefulWidget {
  final String query;
  final ValueChanged<String> onSelectUser;

  const MentionSuggestionList({
    super.key,
    required this.query,
    required this.onSelectUser,
  });

  @override
  State<MentionSuggestionList> createState() => _MentionSuggestionListState();
}

class _MentionSuggestionListState extends State<MentionSuggestionList> {
  static final Map<String, List<Map<String, dynamic>>> _memoryCache = {};
  Timer? _debounceTimer;
  List<Map<String, dynamic>> _profiles = [];
  bool _isLoading = false;
  int _currentRequestId = 0;

  @override
  void initState() {
    super.initState();
    _fetchUsers(widget.query);
  }

  @override
  void didUpdateWidget(covariant MentionSuggestionList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _debounceTimer?.cancel();
      final clean = widget.query.trim().toLowerCase();
      // Instant cache hit bypasses debounce delay completely
      if (_memoryCache.containsKey(clean)) {
        setState(() {
          _profiles = _memoryCache[clean]!;
          _isLoading = false;
        });
        return;
      }

      _debounceTimer = Timer(const Duration(milliseconds: 150), () {
        if (mounted) {
          _fetchUsers(widget.query);
        }
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchUsers(String query) async {
    if (!mounted) return;
    final clean = query.trim().toLowerCase();

    // Check memory cache first
    if (_memoryCache.containsKey(clean)) {
      setState(() {
        _profiles = _memoryCache[clean]!;
        _isLoading = false;
      });
      return;
    }

    final requestId = ++_currentRequestId;
    setState(() => _isLoading = true);

    try {
      List<Map<String, dynamic>> results;
      if (clean.isEmpty) {
        results = await SupabaseService.instance.fetchSuggestedProfiles(limit: 6);
      } else {
        results = await SupabaseService.instance.searchProfiles(clean);
      }

      // Discard stale out-of-order network responses
      if (!mounted || requestId != _currentRequestId) return;

      // Populate memory cache (cap size to 50 entries to avoid RAM bloat)
      if (_memoryCache.length >= 50) {
        _memoryCache.remove(_memoryCache.keys.first);
      }
      _memoryCache[clean] = results;

      setState(() {
        _profiles = results;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted && requestId == _currentRequestId) {
        setState(() {
          _profiles = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_profiles.isEmpty && !_isLoading) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: const BoxConstraints(maxHeight: 180.0),
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 16.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.0),
        child: _isLoading && _profiles.isEmpty
            ? const SizedBox(
                height: 52.0,
                child: Center(
                  child: SizedBox(
                    width: 18.0,
                    height: 18.0,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: _profiles.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1.0,
                  thickness: 0.6,
                  color: isDark ? AppColors.darkBorder : const Color(0xFFF1F5F9),
                ),
                itemBuilder: (context, index) {
                  final profile = _profiles[index];
                  final username = (profile['username'] ?? '').toString().replaceAll('@', '');
                  final fullName = (profile['full_name'] ?? username).toString();
                  final avatarUrl = (profile['avatar_url'] ?? '').toString();
                  final isVerified = profile['is_verified'] == true;
                  final classGroup = (profile['class_group'] ?? '').toString();

                  return InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      widget.onSelectUser(username);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                      child: Row(
                        children: [
                          AppAvatar(
                            avatarUrl: avatarUrl,
                            size: 30.0,
                          ),
                          const SizedBox(width: 10.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        fullName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13.0,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.adaptiveText(context),
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ),
                                    if (isVerified) ...[
                                      const SizedBox(width: 4.0),
                                      const Icon(
                                        CupertinoIcons.checkmark_seal_fill,
                                        size: 13.0,
                                        color: AppColors.verifiedBlue,
                                      ),
                                    ],
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      '@$username',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w500,
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                    if (classGroup.isNotEmpty) ...[
                                      Text(
                                        ' · $classGroup',
                                        style: TextStyle(
                                          fontSize: 11.0,
                                          color: isDark
                                              ? AppColors.darkTextSecondary.withValues(alpha: 0.8)
                                              : const Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
