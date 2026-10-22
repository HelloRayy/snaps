import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapan_market/features/auth/components/auth_footer_switcher.dart';
import 'package:snapan_market/features/auth/components/auth_text_field.dart';
import 'package:snapan_market/features/auth/screens/auth_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('AuthScreen sticky CTA renders correctly in Login mode', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AuthScreen(
          onBack: () {},
          onSuccess: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Back button exists
    expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);

    // Verify Sticky CTA button exists with 'Masuk ke Akun'
    expect(find.byType(PrimaryAuthButton), findsOneWidget);
    expect(find.text('Masuk ke Akun'), findsOneWidget);

    // Initially disabled because fields are empty
    final initialButton = tester.widget<PrimaryAuthButton>(find.byType(PrimaryAuthButton));
    expect(initialButton.isEnabled, isFalse);

    // Footer switcher visible when keyboard is closed
    expect(find.byType(AuthFooterSwitcher), findsOneWidget);

    // Fill in username and password
    await tester.enterText(find.byType(TextField).at(0), 'user123');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.pump();

    // Now button should be enabled
    final updatedButton = tester.widget<PrimaryAuthButton>(find.byType(PrimaryAuthButton));
    expect(updatedButton.isEnabled, isTrue);
  });

  testWidgets('AuthScreen switches to Register mode and updates sticky CTA text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AuthScreen(
          onBack: () {},
          onSuccess: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap footer switcher to switch to Register mode
    await tester.tap(find.byType(AuthFooterSwitcher));
    await tester.pumpAndSettle();

    // Verify Title changed to 'Daftar Akun Baru'
    expect(find.text('Daftar Akun Baru'), findsOneWidget);

    // Verify CTA button inside Register form with 'Aktifkan Akun & Masuk'
    expect(find.text('Aktifkan Akun & Masuk'), findsOneWidget);

    // Incomplete form keeps button disabled
    final registerButton = tester.widget<PrimaryAuthButton>(find.byType(PrimaryAuthButton));
    expect(registerButton.isEnabled, isFalse);

    // Verify CTA button is inside SingleChildScrollView (fixed in form, scrollable)
    expect(
      find.descendant(
        of: find.byType(SingleChildScrollView),
        matching: find.text('Aktifkan Akun & Masuk'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('In Register mode, CTA button stays scrollable inside SingleChildScrollView', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AuthScreen(
          onBack: () {},
          onSuccess: () {},
          initialAccountDeletedNotice: true, // starts directly in register mode
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title is 'Daftar Akun Baru'
    expect(find.text('Daftar Akun Baru'), findsOneWidget);

    // CTA is inside SingleChildScrollView
    expect(
      find.descendant(
        of: find.byType(SingleChildScrollView),
        matching: find.text('Aktifkan Akun & Masuk'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('When keyboard is open, sticky CTA remains visible and footer switcher is hidden', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            viewInsets: EdgeInsets.only(bottom: 280.0), // Keyboard active (> 100)
          ),
          child: AuthScreen(
            onBack: () {},
            onSuccess: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // CTA Button is still visible and sticky
    expect(find.byType(PrimaryAuthButton), findsOneWidget);
    // Footer switcher is hidden to give maximum vertical space
    expect(find.byType(AuthFooterSwitcher), findsNothing);
  });
}
