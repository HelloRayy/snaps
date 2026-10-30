import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapan_market/features/auth/models/auth_constants.dart';

void main() {
  group('SNAPS-95 & SNAPS-94: Auth Input Sanitization & Validation Tests', () {
    test('Solusi 1: Reserved Usernames Engine blocks system names', () {
      final reserved = [
        'admin',
        'ADMIN',
        '@admin',
        'administrator',
        'root',
        'snaps',
        'snapan',
        'official',
        'support',
        'system',
        'moderator',
        'help',
        'superuser',
        'operator',
      ];

      for (final name in reserved) {
        expect(
          AuthConstants.isReservedUsername(name),
          isTrue,
          reason: '$name should be identified as reserved',
        );
      }

      // Normal non-reserved usernames
      expect(AuthConstants.isReservedUsername('rayhan'), isFalse);
      expect(AuthConstants.isReservedUsername('student123'), isFalse);
      expect(AuthConstants.isReservedUsername('aliffarhan'), isFalse);
    });

    test('Solusi 2 & 3: Input Formatters deny spaces, symbols, and force lowercase', () {
      final formatters = [
        LengthLimitingTextInputFormatter(20),
        FilteringTextInputFormatter.deny(RegExp(r'\s')),
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
        TextInputFormatter.withFunction((oldValue, newValue) {
          return newValue.copyWith(text: newValue.text.toLowerCase());
        }),
      ];

      TextEditingValue formatInput(String text) {
        var value = TextEditingValue(text: text);
        for (final formatter in formatters) {
          value = formatter.formatEditUpdate(TextEditingValue.empty, value);
        }
        return value;
      }

      // 1. Whitespace removed
      expect(formatInput('ray han').text, 'rayhan');
      expect(formatInput('  ali  ').text, 'ali');

      // 2. Symbols removed (including dot, underscore, punctuation)
      expect(formatInput('user.name_123!').text, 'username123');
      expect(formatInput('@student#2026').text, 'student2026');

      // 3. Invisible characters / zero-width space removed
      expect(formatInput('user\u200Bname\u00A0test').text, 'usernametest');

      // 4. Uppercase forced to lowercase
      expect(formatInput('RayHanYogi').text, 'rayhanyogi');

      // 5. Max length limited to 20
      expect(formatInput('abcdefghijklmnopqrstuvwxyz').text.length, 20);
      expect(formatInput('abcdefghijklmnopqrstuvwxyz').text, 'abcdefghijklmnopqrst');
    });

    test('Solusi 5: Profanity Filter blocks vulgarities and insults', () {
      final vulgarWords = [
        'anjing',
        'ANJING',
        'babi',
        'bangsat',
        'kontol',
        'memek',
        'ngentot',
        'asu',
        'fuck',
        'bitch',
      ];

      for (final word in vulgarWords) {
        expect(
          AuthConstants.isProfane(word),
          isTrue,
          reason: '$word should be blocked by profanity filter',
        );
      }

      // Clean words
      expect(AuthConstants.isProfane('rayhan'), isFalse);
      expect(AuthConstants.isProfane('budi'), isFalse);
      expect(AuthConstants.isProfane('eko'), isFalse);
      expect(AuthConstants.isProfane('ali'), isFalse);
    });

    test('SNAPS-94: Display Name allows 3-20 chars and optional empty', () {
      bool isValidDisplayName(String input) {
        final clean = input.trim();
        return clean.isEmpty ||
            (clean.length >= 3 &&
                clean.length <= 20 &&
                !AuthConstants.isProfane(clean));
      }

      // Allowed
      expect(isValidDisplayName(''), isTrue, reason: 'Empty is optional');
      expect(isValidDisplayName('Ali'), isTrue, reason: 'Short 3-letter name');
      expect(isValidDisplayName('Eko'), isTrue, reason: 'Short 3-letter name');
      expect(isValidDisplayName('Dina'), isTrue, reason: 'Short 4-letter name');
      expect(isValidDisplayName('Rayhan123'), isTrue);

      // Blocked (<3 or >20 or profane)
      expect(isValidDisplayName('a'), isFalse, reason: 'Too short (1 char)');
      expect(isValidDisplayName('ab'), isFalse, reason: 'Too short (2 chars)');
      expect(isValidDisplayName('123456789012345678901'), isFalse, reason: 'Too long (>20 chars)');
      expect(isValidDisplayName('anjing'), isFalse, reason: 'Profane display name');
    });
  });
}
