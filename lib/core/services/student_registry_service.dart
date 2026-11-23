import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:snapan_market/core/services/supabase_service.dart';
import 'package:snapan_market/features/auth/models/auth_constants.dart';

class RegisteredStudent {
  final String nis;
  final String name;
  final String classGroup;
  final bool isClaimed;
  final String? claimedBy;

  const RegisteredStudent({
    required this.nis,
    required this.name,
    required this.classGroup,
    this.isClaimed = false,
    this.claimedBy,
  });

  factory RegisteredStudent.fromJson(Map<String, dynamic> json) {
    final rawClass = json['class_group']?.toString() ?? '';
    final rawName = (json['full_name'] ?? json['name'])?.toString() ?? '';
    return RegisteredStudent(
      nis: json['nis']?.toString() ?? '',
      name: rawName,
      classGroup: AuthConstants.normalizeClassGroup(rawClass),
      isClaimed: json['is_claimed'] == true,
      claimedBy: json['claimed_by']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'nis': nis,
        'name': name,
        'class_group': classGroup,
        'is_claimed': isClaimed,
        'claimed_by': claimedBy,
      };

  RegisteredStudent copyWith({
    String? nis,
    String? name,
    String? classGroup,
    bool? isClaimed,
    String? claimedBy,
  }) {
    return RegisteredStudent(
      nis: nis ?? this.nis,
      name: name ?? this.name,
      classGroup: classGroup ?? this.classGroup,
      isClaimed: isClaimed ?? this.isClaimed,
      claimedBy: claimedBy ?? this.claimedBy,
    );
  }
}

/// Service to handle local lookup and offline demo verification of student NIS records
class StudentRegistryService {
  StudentRegistryService._();
  static final StudentRegistryService instance = StudentRegistryService._();

  List<RegisteredStudent> _students = [];
  bool _isLoaded = false;

  /// Ensure students dataset is loaded into memory (prioritizes Supabase live data)
  Future<void> init({bool forceRefresh = false}) async {
    if (_isLoaded && !forceRefresh) return;
    _isLoaded = true;
  }

  /// Memaksa refresh dataset dari database Supabase
  Future<void> refresh() => init(forceRefresh: true);

  /// Instant lookup by NIS
  RegisteredStudent? findByNis(String rawNis) {
    final clean = rawNis.trim();
    if (clean.isEmpty) return null;
    try {
      return _students.firstWhere(
        (s) => s.nis == clean,
      );
    } catch (_) {
      return null;
    }
  }

  /// Lookup NIS with remote fallback if not found in memory
  Future<RegisteredStudent?> findByNisRemote(String rawNis) async {
    final local = findByNis(rawNis);
    if (local != null) return local;

    final clean = rawNis.trim();
    if (clean.isEmpty) return null;

    try {
      final res = await SupabaseService.instance.client.rpc(
        'lookup_student_by_nis',
        params: {'p_nis': clean},
      );

      Map<String, dynamic>? row;
      if (res is List && res.isNotEmpty && res.first is Map) {
        row = Map<String, dynamic>.from(res.first as Map);
      } else if (res is Map) {
        row = Map<String, dynamic>.from(res);
      }

      if (row != null && row.isNotEmpty) {
        final student = RegisteredStudent.fromJson(row);
        registerStudent(student);
        return student;
      }
    } catch (e) {
      debugPrint('StudentRegistryService: Remote lookup error for $clean: $e');
    }
    return null;
  }

  /// Generates clean username from [first name + middle name], e.g.
  /// "Raditya Rayhan Yogiswara" -> "radityarayhan"
  static String generateSuggestedUsername(String fullName, {String? suffix}) {
    final parts = fullName
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();

    String base;
    if (parts.isEmpty) {
      base = 'user';
    } else if (parts.length == 1) {
      base = parts.first.replaceAll(RegExp(r'[^a-z0-9]'), '');
    } else {
      // First name + Middle name
      final first = parts[0].replaceAll(RegExp(r'[^a-z0-9]'), '');
      final middle = parts[1].replaceAll(RegExp(r'[^a-z0-9]'), '');
      base = '$first$middle';
    }

    if (base.isEmpty) base = 'user';
    if (suffix != null && suffix.isNotEmpty) {
      base = '$base$suffix';
    }
    return base;
  }

  /// Search matching students by query (NIS or Name)
  List<RegisteredStudent> searchStudents(String query, {bool onlyUnclaimed = false}) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return [];
    return _students.where((s) {
      if (onlyUnclaimed && s.isClaimed) return false;
      return s.nis.contains(clean) || s.name.toLowerCase().contains(clean);
    }).toList();
  }

  /// Async search combining local memory + live Supabase lookup
  Future<List<RegisteredStudent>> searchStudentsAsync(
    String query, {
    bool onlyUnclaimed = false,
  }) async {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return [];

    final localMatches = searchStudents(clean, onlyUnclaimed: onlyUnclaimed);
    if (localMatches.isNotEmpty) return localMatches;

    // Jika belum ditemukan di memori lokal, coba cari langsung ke Supabase
    try {
      final res = await SupabaseService.instance.client
          .from('student_registry')
          .select('nis, full_name, class_group, is_claimed, claimed_by')
          .or('nis.ilike.%$clean%,full_name.ilike.%$clean%')
          .limit(8);

      if (res.isNotEmpty) {
        final fetched = res
            .map(RegisteredStudent.fromJson)
            .toList();

        for (final s in fetched) {
          registerStudent(s);
        }

        if (onlyUnclaimed) {
          return fetched.where((s) => !s.isClaimed).toList();
        }
        return fetched;
      }
    } catch (_) {}

    return localMatches;
  }

  /// Mark student as claimed in local cache
  void markNisClaimed(String nis, {required String userId}) {
    final clean = nis.trim();
    final idx = _students.indexWhere((s) => s.nis == clean);
    if (idx >= 0) {
      _students[idx] = _students[idx].copyWith(
        isClaimed: true,
        claimedBy: userId,
      );
    }
  }

  /// Find class group by NIS. Returns null if NIS is not found or empty.
  String? findClassByNis(String? rawNis) {
    if (rawNis == null) return null;
    final clean = rawNis.trim();
    if (clean.isEmpty) return null;
    final student = findByNis(clean);
    if (student != null && student.classGroup.trim().isNotEmpty) {
      return student.classGroup.trim();
    }
    return null;
  }

  /// Manually add or update a student in the in-memory cache
  void registerStudent(RegisteredStudent student) {
    final idx = _students.indexWhere((s) => s.nis == student.nis);
    if (idx >= 0) {
      _students[idx] = student;
    } else {
      _students.add(student);
    }
  }
}

