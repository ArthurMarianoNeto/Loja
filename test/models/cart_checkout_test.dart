import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loja/models/address.dart';
import 'package:loja/models/app_user.dart';
import 'package:loja/models/cart_manager.dart';
import 'package:loja/models/checkout_manager.dart';
import 'package:loja/models/credit_card.dart';
import 'package:loja/models/order.dart';
import 'package:loja/models/product.dart';
import 'package:loja/models/user_manager.dart';
import 'package:loja/services/cielo_payment.dart';

// Cielo simulada: registra as chamadas e pode falhar em cada etapa
class FakeCielo extends CieloPayment {
  FakeCielo({this.falharAutorizacao = false});

  final bool falharAutorizacao;
  final List<String> chamadas = [];

  @override
  Future<String> authorize({required CreditCard creditCard,
    required num price, required String orderId, required AppUser user}) async {
    chamadas.add('authorize $orderId $price');
    if(falharAutorizacao) return Future.error('Cartão recusado');
    return 'pay-$orderId';
  }

  @override
  Future<void> capture(String payId) async => chamadas.add('capture $payId');

  @override
  Future<void> cancel(String payId) async => chamadas.add('cancel $payId');
}

// loja em São Paulo (Praça da Sé), entrega até 20 km: R$ 5 + R$ 1/km
Future<FakeFirebaseFirestore> criarLoja() async {
  final firestore = FakeFirebaseFirestore();
  await firestore.doc('users/u1').set({'name': 'Fulano', 'cpf': '123'});
  await firestore.doc('aux/delivery')
      .set({'lat': -23.5503, 'long': -46.6339, 'base': 5, 'km': 1, 'maxkm': 20});
  await firestore.doc('aux/ordercounter').set({'current': 100});
  await firestore.doc('products/p1').set({
    'name': 'Camiseta',
    'images': <String>[],
    'deleted': false,
    'sizes': [
      {'name': 'M', 'price': 30, 'stock': 3}
    ],
  });
  return firestore;
}

Future<CartManager> carrinhoLogado(FakeFirebaseFirestore firestore) async {
  final userManager = UserManager(
    auth: MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'u1')),
    firestore: firestore,
    getToken: () async => null,
  );
  await pumpEventQueue();
  final cartManager = CartManager(firestore: firestore)..updateUser(userManager);
  await pumpEventQueue();
  return cartManager;
}

Future<Product> camisetaM(FakeFirebaseFirestore firestore) async {
  final product = Product.fromDocument(await firestore.doc('products/p1').get());
  product.selectedSize = product.sizes.first;
  return product;
}

void main() {
  group('CartManager', () {
    test('sem usuário o carrinho fica vazio', () async {
      final firestore = await criarLoja();
      final userManager = UserManager(
        auth: MockFirebaseAuth(),
        firestore: firestore,
        getToken: () async => null,
      );
      final cartManager = CartManager(firestore: firestore)..updateUser(userManager);

      expect(cartManager.user, isNull);
      expect(cartManager.items, isEmpty);
      expect(cartManager.totalPrice, 0);
    });

    test('addToCart empilha o mesmo tamanho e grava no Firestore', () async {
      final firestore = await criarLoja();
      final cartManager = await carrinhoLogado(firestore);

      cartManager.addToCart(await camisetaM(firestore));
      await pumpEventQueue();
      cartManager.addToCart(await camisetaM(firestore));
      await pumpEventQueue();

      expect(cartManager.items, hasLength(1));
      expect(cartManager.items.single.quantity, 2);
      expect(cartManager.productsPrice, 60);
      final cart = await firestore.collection('users/u1/cart').get();
      expect(cart.docs.single.data(), {'pid': 'p1', 'quantity': 2, 'size': 'M'});
    });

    test('quantidade zero remove o item do carrinho', () async {
      final firestore = await criarLoja();
      final cartManager = await carrinhoLogado(firestore);
      cartManager.addToCart(await camisetaM(firestore));
      await pumpEventQueue();

      cartManager.items.single.decrement();
      await pumpEventQueue();

      expect(cartManager.items, isEmpty);
      expect((await firestore.collection('users/u1/cart').get()).docs, isEmpty);
    });

    test('recarrega os itens salvos ao logar', () async {
      final firestore = await criarLoja();
      await firestore.doc('users/u1/cart/c1')
          .set({'pid': 'p1', 'quantity': 2, 'size': 'M'});

      final cartManager = await carrinhoLogado(firestore);
      await pumpEventQueue();

      expect(cartManager.items.single.quantity, 2);
      expect(cartManager.productsPrice, 60);
      expect(cartManager.isCartValid, isTrue);
    });

    test('frete: dentro do raio calcula o preço, fora dá erro', () async {
      final firestore = await criarLoja();
      final cartManager = await carrinhoLogado(firestore);

      // Avenida Paulista, ~2,7 km da Praça da Sé
      await cartManager.setAddress(Address(lat: -23.5614, long: -46.6559));
      expect(cartManager.isAddressValid, isTrue);
      expect(cartManager.devliveryPrice!, closeTo(7.5, 0.5));
      final user = await firestore.doc('users/u1').get();
      expect(user.data()!['address']['lat'], -23.5614);

      cartManager.removeAddress();
      // Campinas, ~90 km
      await expectLater(
        cartManager.setAddress(Address(lat: -22.9056, long: -47.0608)),
        throwsA('Endereço fora do raio de entrega!'),
      );
      expect(cartManager.isAddressValid, isFalse);
      expect(cartManager.loading, isFalse);
    });

    test('endereço sem coordenadas não tem entrega', () async {
      final cartManager = await carrinhoLogado(await criarLoja());

      expect(await cartManager.calculateDelivery(null, null), isFalse);
    });
  });

  group('CheckoutManager', () {
    late FakeFirebaseFirestore firestore;
    late CartManager cartManager;

    setUp(() async {
      firestore = await criarLoja();
      cartManager = await carrinhoLogado(firestore);
      cartManager.addToCart(await camisetaM(firestore));
      cartManager.addToCart(await camisetaM(firestore));
      await cartManager.setAddress(Address(lat: -23.5614, long: -46.6559));
      await pumpEventQueue();
    });

    test('sucesso: autoriza, baixa o estoque, captura e salva o pedido', () async {
      final cielo = FakeCielo();
      final checkout = CheckoutManager(firestore: firestore, cieloPayment: cielo)
        ..updateCart(cartManager);
      Order? pedido;

      await checkout.checkout(
        creditCard: CreditCard(),
        onStockFail: (e) => fail('estoque: $e'),
        onPayFail: (e) => fail('pagamento: $e'),
        onSuccess: (order) => pedido = order,
      );
      await pumpEventQueue();

      expect(cielo.chamadas.first, startsWith('authorize 100 '));
      expect(cielo.chamadas.last, 'capture pay-100');
      expect(pedido!.orderId, '100');
      expect(pedido!.payId, 'pay-100');
      expect((await firestore.doc('aux/ordercounter').get()).data()!['current'], 101);
      final produto = await firestore.doc('products/p1').get();
      expect(produto.data()!['sizes'][0]['stock'], 1);
      final salvo = await firestore.doc('orders/100').get();
      expect(salvo.data()!['user'], 'u1');
      expect(salvo.data()!['status'], Status.preparing.index);
      expect(cartManager.items, isEmpty);
      expect(checkout.loading, isFalse);
    });

    test('sem estoque: cancela o pagamento e não salva pedido', () async {
      await firestore.doc('products/p1').update({
        'sizes': [
          {'name': 'M', 'price': 30, 'stock': 1}
        ],
      });
      final cielo = FakeCielo();
      final checkout = CheckoutManager(firestore: firestore, cieloPayment: cielo)
        ..updateCart(cartManager);
      Object? erro;

      await checkout.checkout(
        creditCard: CreditCard(),
        onStockFail: (e) => erro = e,
        onPayFail: (e) => fail('pagamento: $e'),
        onSuccess: (_) => fail('não deveria concluir'),
      );

      expect(erro, '1 produtos sem estoque');
      expect(cielo.chamadas.last, 'cancel pay-100');
      expect((await firestore.doc('orders/100').get()).exists, isFalse);
      expect(cartManager.items, isNotEmpty);
    });

    test('pagamento recusado: avisa e não mexe no estoque', () async {
      final checkout = CheckoutManager(
          firestore: firestore, cieloPayment: FakeCielo(falharAutorizacao: true))
        ..updateCart(cartManager);
      Object? erro;

      await checkout.checkout(
        creditCard: CreditCard(),
        onStockFail: (e) => fail('estoque: $e'),
        onPayFail: (e) => erro = e,
        onSuccess: (_) => fail('não deveria concluir'),
      );

      expect(erro, 'Cartão recusado');
      final produto = await firestore.doc('products/p1').get();
      expect(produto.data()!['sizes'][0]['stock'], 3);
      expect(checkout.loading, isFalse);
    });
  });
}
