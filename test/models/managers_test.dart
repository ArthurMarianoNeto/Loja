import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loja/models/admin_orders_manager.dart';
import 'package:loja/models/admin_users_manager.dart';
import 'package:loja/models/app_user.dart';
import 'package:loja/models/home_manager.dart';
import 'package:loja/models/order.dart';
import 'package:loja/models/orders_manager.dart';
import 'package:loja/models/product.dart';
import 'package:loja/models/product_manager.dart';
import 'package:loja/models/section.dart';
import 'package:loja/models/user_manager.dart';

Future<UserManager> logar(FakeFirebaseFirestore firestore, String uid,
    {bool admin = false}) async {
  await firestore.doc('users/$uid').set({'name': 'Usuário $uid'});
  if(admin) await firestore.doc('admins/$uid').set({});
  final userManager = UserManager(
    auth: MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: uid)),
    firestore: firestore,
    getToken: () async => null,
  );
  await pumpEventQueue();
  return userManager;
}

Map<String, dynamic> pedido(String user, Status status) => {
      'items': <Map<String, dynamic>>[],
      'price': 10,
      'user': user,
      'address': {'street': 'Rua A'},
      'status': status.index,
    };

void main() {
  group('ProductManager', () {
    late FakeFirebaseFirestore firestore;

    setUp(() async {
      firestore = FakeFirebaseFirestore();
      await firestore.doc('products/p1').set({'name': 'Camiseta Azul', 'deleted': false});
      await firestore.doc('products/p2').set({'name': 'Bermuda', 'deleted': false});
      await firestore.doc('products/p3').set({'name': 'Camiseta velha', 'deleted': true});
    });

    test('carrega só os produtos não apagados', () async {
      final manager = ProductManager(firestore: firestore);
      await pumpEventQueue();

      expect(manager.allProducts.map((p) => p.id), unorderedEquals(['p1', 'p2']));
    });

    test('busca ignora maiúsculas/minúsculas', () async {
      final manager = ProductManager(firestore: firestore);
      await pumpEventQueue();

      manager.search = 'CAMISETA';
      expect(manager.filteredProducts.map((p) => p.id), ['p1']);
      manager.search = '';
      expect(manager.filteredProducts, hasLength(2));
    });

    test('findProductById devolve null quando não acha', () async {
      final manager = ProductManager(firestore: firestore);
      await pumpEventQueue();

      expect(manager.findProductById('p2')!.name, 'Bermuda');
      expect(manager.findProductById('x'), isNull);
      expect(manager.findProductById(null), isNull);
    });

    test('update troca o produto e delete marca como apagado', () async {
      final manager = ProductManager(firestore: firestore);
      await pumpEventQueue();

      manager.update(Product(id: 'p2', name: 'Bermuda Jeans'));
      expect(manager.findProductById('p2')!.name, 'Bermuda Jeans');

      manager.delete(manager.findProductById('p1')!);
      await pumpEventQueue();
      expect(manager.findProductById('p1'), isNull);
      final doc = await firestore.doc('products/p1').get();
      expect(doc.data()!['deleted'], isTrue);
    });
  });

  group('HomeManager', () {
    late FakeFirebaseFirestore firestore;

    setUp(() async {
      firestore = FakeFirebaseFirestore();
      await firestore.doc('home/b').set({
        'name': 'Novidades', 'type': 'Staggered', 'pos': 1,
        'items': [{'image': 'b.png', 'product': null}],
      });
      await firestore.doc('home/a').set({
        'name': 'Promoções', 'type': 'List', 'pos': 0,
        'items': [{'image': 'a.png', 'product': 'p1'}],
      });
    });

    test('carrega as seções ordenadas por pos', () async {
      final manager = HomeManager(firestore: firestore);
      await pumpEventQueue();

      expect(manager.sections.map((s) => s.name), ['Promoções', 'Novidades']);
      expect(manager.sections.first.items.single.product, 'p1');
    });

    test('edição trabalha numa cópia e pode ser descartada', () async {
      final manager = HomeManager(firestore: firestore);
      await pumpEventQueue();

      manager.enterEditing();
      manager.addSection(Section(type: 'List'));
      expect(manager.sections, hasLength(3));

      manager.discardEditing();
      expect(manager.editing, isFalse);
      expect(manager.sections, hasLength(2));
    });

    test('saveEditing não salva enquanto houver seção inválida', () async {
      final manager = HomeManager(firestore: firestore);
      await pumpEventQueue();

      manager.enterEditing();
      final nova = Section(type: 'List');
      manager.addSection(nova);
      await manager.saveEditing();

      expect(manager.editing, isTrue);
      expect(nova.error, 'Título inválido');
    });

    test('saveEditing grava posições e apaga seções removidas', () async {
      final manager = HomeManager(firestore: firestore);
      await pumpEventQueue();

      manager.enterEditing();
      manager.removeSection(manager.sections.first);
      await manager.saveEditing();
      await pumpEventQueue();

      expect(manager.editing, isFalse);
      expect((await firestore.doc('home/a').get()).exists, isFalse);
      expect((await firestore.doc('home/b').get()).data()!['pos'], 0);
      expect(manager.sections.map((s) => s.name), ['Novidades']);
    });
  });

  group('OrdersManager', () {
    test('escuta só os pedidos do usuário e limpa ao deslogar', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.doc('orders/1').set(pedido('u1', Status.preparing));
      await firestore.doc('orders/2').set(pedido('u2', Status.preparing));
      final manager = OrdersManager(firestore: firestore);

      manager.updateUser(AppUser(id: 'u1'));
      await pumpEventQueue();
      expect(manager.orders.map((o) => o.orderId), ['1']);

      await firestore.doc('orders/3').set(pedido('u1', Status.preparing));
      await pumpEventQueue();
      expect(manager.orders.map((o) => o.orderId), unorderedEquals(['1', '3']));

      manager.updateUser(null);
      expect(manager.orders, isEmpty);
    });
  });

  group('AdminUsersManager', () {
    test('admin vê os usuários ordenados por nome', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.doc('users/x').set({'name': 'beatriz'});
      await firestore.doc('users/y').set({'name': 'Carlos'});
      final userManager = await logar(firestore, 'a', admin: true);
      final manager = AdminUsersManager(firestore: firestore);

      manager.updateUser(userManager);
      await pumpEventQueue();

      expect(manager.names, ['beatriz', 'Carlos', 'Usuário a']);
      manager.dispose();
    });

    test('usuário comum não vê ninguém', () async {
      final firestore = FakeFirebaseFirestore();
      final userManager = await logar(firestore, 'a');
      final manager = AdminUsersManager(firestore: firestore);

      manager.updateUser(userManager);
      await pumpEventQueue();

      expect(manager.users, isEmpty);
    });
  });

  group('AdminOrdersManager', () {
    test('filtra por status e por usuário', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.doc('orders/1').set(pedido('u1', Status.preparing));
      await firestore.doc('orders/2').set(pedido('u2', Status.delivered));
      await firestore.doc('orders/3').set(pedido('u2', Status.transporting));
      final manager = AdminOrdersManager(firestore: firestore);

      manager.updateAdmin(adminEnabled: true);
      await pumpEventQueue();
      // padrão: em preparação e em transporte
      expect(manager.filteredOrders.map((o) => o.orderId),
          unorderedEquals(['1', '3']));

      manager.setStatusFilter(status: Status.delivered, enabled: true);
      manager.setUserFilter(AppUser(id: 'u2'));
      expect(manager.filteredOrders.map((o) => o.orderId),
          unorderedEquals(['2', '3']));

      await firestore.doc('orders/3').update({'status': Status.canceled.index});
      await pumpEventQueue();
      expect(manager.filteredOrders.map((o) => o.orderId), ['2']);
      manager.dispose();
    });
  });
}
