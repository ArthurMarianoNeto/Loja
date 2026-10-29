import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loja/models/cart_manager.dart';
import 'package:loja/models/item_size.dart';
import 'package:loja/models/product.dart';
import 'package:loja/models/user_manager.dart';
import 'package:loja/screens/cart/cart_screen.dart';
import 'package:loja/screens/products/components/product_list_tile.dart';
import 'package:provider/provider.dart';

Future<CartManager> carrinho(FakeFirebaseFirestore firestore, {required bool logado}) async {
  final userManager = UserManager(
    auth: MockFirebaseAuth(signedIn: logado, mockUser: MockUser(uid: 'u1')),
    firestore: firestore,
    getToken: () async => null,
  );
  await pumpEventQueue();
  return CartManager(firestore: firestore)..updateUser(userManager);
}

Widget app(CartManager cartManager) => ChangeNotifierProvider.value(
      value: cartManager,
      child: const MaterialApp(home: CartScreen()),
    );

void main() {
  late FakeFirebaseFirestore firestore;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    await firestore.doc('users/u1').set({'name': 'Fulano'});
    await firestore.doc('products/p1').set({
      'name': 'Camiseta',
      'images': <String>[],
      'sizes': [
        {'name': 'M', 'price': 30, 'stock': 3}
      ],
    });
  });

  group('CartScreen', () {
    testWidgets('sem login pede para entrar', (tester) async {
      final cartManager = await tester.runAsync(
          () => carrinho(firestore, logado: false));
      await tester.pumpWidget(app(cartManager!));

      expect(find.text('Faça login para acessar'), findsOneWidget);
    });

    testWidgets('logado e sem itens mostra carrinho vazio', (tester) async {
      final cartManager = await tester.runAsync(
          () => carrinho(firestore, logado: true));
      await tester.pumpWidget(app(cartManager!));

      expect(find.text('Nenhum produto no carrinho!'), findsOneWidget);
    });

    testWidgets('lista os itens e o resumo do pedido', (tester) async {
      await firestore.doc('users/u1/cart/c1')
          .set({'pid': 'p1', 'quantity': 2, 'size': 'M'});
      final cartManager = await tester.runAsync(() async {
        final manager = await carrinho(firestore, logado: true);
        await pumpEventQueue();
        return manager;
      });
      await tester.pumpWidget(app(cartManager!));
      await tester.pump();

      expect(find.text('Camiseta'), findsOneWidget);
      expect(find.text('Tamanho: M'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('R\$ 60.00'), findsWidgets);
      expect(find.widgetWithText(ElevatedButton, 'Continuar para Entrega'),
          findsOneWidget);
    });
  });

  group('ProductListTile', () {
    Widget tile(Product product) =>
        MaterialApp(home: Scaffold(body: ProductListTile(product)));

    testWidgets('mostra o menor preço e funciona sem imagem', (tester) async {
      await tester.pumpWidget(tile(Product(
        id: 'p1',
        name: 'Camiseta',
        sizes: [
          ItemSize(name: 'M', price: 29.9, stock: 1),
          ItemSize(name: 'G', price: 39.9, stock: 1),
        ],
      )));

      expect(find.text('Camiseta'), findsOneWidget);
      expect(find.text('R\$ 29.90'), findsOneWidget);
      expect(find.text('Sem estoque.'), findsNothing);
      expect(find.byIcon(Icons.image_not_supported), findsOneWidget);
    });

    testWidgets('avisa quando não há estoque', (tester) async {
      await tester.pumpWidget(tile(Product(
        id: 'p1',
        name: 'Camiseta',
        sizes: [ItemSize(name: 'M', price: 29.9, stock: 0)],
      )));

      expect(find.text('Sem estoque.'), findsOneWidget);
    });
  });
}
