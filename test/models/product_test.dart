import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loja/models/cart_product.dart';
import 'package:loja/models/item_size.dart';
import 'package:loja/models/product.dart';

Product camiseta() => Product(
      id: 'p1',
      name: 'Camiseta',
      description: 'Camiseta de algodão',
      images: ['https://exemplo.com/camiseta.png'],
      sizes: [
        ItemSize(name: 'P', price: 39.9, stock: 0),
        ItemSize(name: 'M', price: 29.9, stock: 3),
        ItemSize(name: 'G', price: 49.9, stock: 2),
      ],
    );

void main() {
  group('Product', () {
    test('basePrice é o menor preço entre os tamanhos', () {
      expect(camiseta().basePrice, 29.9);
    });

    test('totalStock soma os tamanhos e hasStock considera deleted', () {
      final product = camiseta();
      expect(product.totalStock, 5);
      expect(product.hasStock, isTrue);

      product.deleted = true;
      expect(product.hasStock, isFalse);
    });

    test('findSize devolve null para tamanho inexistente', () {
      expect(camiseta().findSize('M')!.price, 29.9);
      expect(camiseta().findSize('GG'), isNull);
      expect(camiseta().findSize(null), isNull);
    });

    test('clone não compartilha tamanhos nem imagens', () {
      final product = camiseta();
      final clone = product.clone();
      clone.sizes.first.stock = 10;
      clone.images.clear();

      expect(product.sizes.first.stock, 0);
      expect(product.images, hasLength(1));
      expect(clone.name, 'Camiseta');
    });

    test('fromDocument tolera campos ausentes', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.doc('products/p2').set({'name': 'Boné'});

      final product =
          Product.fromDocument(await firestore.doc('products/p2').get());

      expect(product.id, 'p2');
      expect(product.name, 'Boné');
      expect(product.description, '');
      expect(product.images, isEmpty);
      expect(product.sizes, isEmpty);
      expect(product.deleted, isFalse);
    });

    test('save de produto novo cria o documento no Firestore', () async {
      final firestore = FakeFirebaseFirestore();
      final product = Product(
        name: 'Bermuda',
        description: 'Bermuda jeans',
        sizes: [ItemSize(name: 'U', price: 59.9, stock: 4)],
        firestore: firestore,
      )..newImages = [];

      await product.save();

      expect(product.id, isNotNull);
      expect(product.loading, isFalse);
      final doc = await firestore.doc('products/${product.id}').get();
      expect(doc.data(), {
        'name': 'Bermuda',
        'description': 'Bermuda jeans',
        'sizes': [
          {'name': 'U', 'price': 59.9, 'stock': 4}
        ],
        'deleted': false,
        'images': <String>[],
      });
    });
  });

  group('CartProduct', () {
    test('fromProduct usa o tamanho selecionado', () {
      final product = camiseta()..selectedSize = camiseta().sizes[1];
      final cartProduct = CartProduct.fromProduct(product);

      expect(cartProduct.productId, 'p1');
      expect(cartProduct.size, 'M');
      expect(cartProduct.quantity, 1);
      expect(cartProduct.unitPrice, 29.9);
      expect(cartProduct.toCartItemMap(),
          {'pid': 'p1', 'quantity': 1, 'size': 'M'});
    });

    test('stackable só para o mesmo produto e tamanho', () {
      final product = camiseta()..selectedSize = camiseta().sizes[1];
      final cartProduct = CartProduct.fromProduct(product);

      expect(cartProduct.stackable(product), isTrue);
      product.selectedSize = product.sizes[2];
      expect(cartProduct.stackable(product), isFalse);
    });

    test('hasStock compara a quantidade com o estoque do tamanho', () {
      final product = camiseta()..selectedSize = camiseta().sizes[2];
      final cartProduct = CartProduct.fromProduct(product);

      expect(cartProduct.hasStock, isTrue);
      cartProduct
        ..increment()
        ..increment();
      expect(cartProduct.quantity, 3);
      expect(cartProduct.hasStock, isFalse);
      expect(cartProduct.totalPrice, closeTo(149.7, 0.001));
    });

    test('fromDocument carrega o produto e notifica', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.doc('products/p1').set({
        'name': 'Camiseta',
        'images': <String>[],
        'sizes': [
          {'name': 'M', 'price': 29.9, 'stock': 3}
        ],
      });
      await firestore
          .doc('users/u1/cart/c1')
          .set({'pid': 'p1', 'quantity': 2, 'size': 'M'});

      final cartProduct = CartProduct.fromDocument(
          await firestore.doc('users/u1/cart/c1').get());
      int notificacoes = 0;
      cartProduct.addListener(() => notificacoes++);
      expect(cartProduct.product, isNull);
      expect(cartProduct.hasStock, isFalse);

      await pumpEventQueue();

      expect(notificacoes, 1);
      expect(cartProduct.product!.name, 'Camiseta');
      expect(cartProduct.totalPrice, closeTo(59.8, 0.001));
      expect(cartProduct.hasStock, isTrue);
    });
  });
}
