import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapan_market/features/messages/components/chat_product_card.dart';
import 'package:snapan_market/features/messages/components/conversation_list_item.dart';
import 'package:snapan_market/features/messages/models/conversation_model.dart';

void main() {
  group('ChatProductCard & ConversationListItem Product Context Tests', () {
    testWidgets('ChatProductCard renders product title, price, and location correctly', (tester) async {
      bool viewTapped = false;
      bool locationTapped = false;

      const product = ProductContext(
        title: 'Kamera Canon EOS 600D',
        price: 'Rp 2.500.000',
        location: 'Kantin Belakang SMKN 8 Semarang',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatProductCard(
              product: product,
              location: product.location ?? 'Lab Fisika Lt 2',
              onViewProduct: () {
                viewTapped = true;
              },
              onCheckLocation: () {
                locationTapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Kamera Canon EOS 600D'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains('Rp 2.500.000')),
        findsOneWidget,
      );
      expect(find.text('Kantin Belakang SMKN 8 Semarang'), findsOneWidget);

      await tester.tap(find.text('Kamera Canon EOS 600D'));
      await tester.pump();
      expect(viewTapped, isTrue);

      await tester.tap(find.text('Cek Lokasi di Peta'));
      await tester.pump();
      expect(locationTapped, isTrue);
    });

    testWidgets('ChatProductCard renders inquiry badge when isMe is true', (tester) async {
      const product = ProductContext(
        title: 'Buku Pemrograman Flutter',
        price: 'Rp 85.000',
        location: 'Perpustakaan Lt 1',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatProductCard(
              product: product,
              location: 'Perpustakaan Lt 1',
              isMe: true,
            ),
          ),
        ),
      );

      expect(find.text('Produk yang Ditanyakan'), findsOneWidget);
      expect(find.text('Buku Pemrograman Flutter'), findsOneWidget);
    });

    testWidgets('ConversationListItem renders product chip badge when productContext is present', (tester) async {
      final conv = ConversationModel(
        id: 'conv-test-1',
        productId: 'prod-123',
        user: const ConversationUser(
          id: 'user-2',
          name: 'Budi Pembeli',
          username: 'budi',
          avatar: '',
        ),
        lastMessage: 'Halo kak ready?',
        timestamp: '14:20',
        isRequest: true,
        productContext: const ProductContext(
          title: 'Jaket Hoodie SMKN 8',
          price: 'Rp 120.000',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConversationListItem(
              conversation: conv,
              onTap: () {},
            ),
          ),
        ),
      );

      // Verify bag icon
      expect(find.byIcon(CupertinoIcons.bag_fill), findsOneWidget);
      // Verify product title
      expect(find.text('Jaket Hoodie SMKN 8'), findsOneWidget);
      // Verify product price
      expect(find.text('Rp 120.000'), findsOneWidget);
    });

    testWidgets('ConversationListItem does not render product chip badge when productContext is null', (tester) async {
      final conv = ConversationModel(
        id: 'conv-test-2',
        user: const ConversationUser(
          id: 'user-3',
          name: 'Siti Rahma',
          username: 'siti',
          avatar: '',
        ),
        lastMessage: 'Besok ada PR?',
        timestamp: '09:10',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConversationListItem(
              conversation: conv,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(CupertinoIcons.bag_fill), findsNothing);
    });
  });
}
