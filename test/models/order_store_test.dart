import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loja/models/order.dart';
import 'package:loja/models/store.dart';

Future<Order> criarPedido(FakeFirebaseFirestore firestore, Status status) async {
  await firestore.doc('orders/42').set({
    'items': [
      {'pid': 'p1', 'quantity': 2, 'size': 'M', 'fixedPrice': 29.9}
    ],
    'price': 59.8,
    'user': 'u1',
    'address': {'street': 'Rua A', 'number': '10', 'lat': -23.5, 'long': -46.6},
    'status': status.index,
    'date': Timestamp.now(),
    'payId': 'pay-1',
  });
  return Order.fromDocument(await firestore.doc('orders/42').get());
}

void main() {
  group('Order', () {
    test('fromDocument lê itens, endereço e status', () async {
      final order = await criarPedido(FakeFirebaseFirestore(), Status.preparing);

      expect(order.orderId, '42');
      expect(order.formattedId, '#000042');
      expect(order.items.single.quantity, 2);
      expect(order.items.single.fixedPrice, 29.9);
      expect(order.address.street, 'Rua A');
      expect(order.statusText, 'Em preparação');
      expect(order.payId, 'pay-1');
    });

    test('textos de todos os status', () {
      expect(Order.getStatusText(Status.canceled), 'Cancelado');
      expect(Order.getStatusText(Status.preparing), 'Em preparação');
      expect(Order.getStatusText(Status.transporting), 'Em transporte');
      expect(Order.getStatusText(Status.delivered), 'Entregue');
    });

    test('advance/back ficam nulos nos extremos', () async {
      final firestore = FakeFirebaseFirestore();

      final preparando = await criarPedido(firestore, Status.preparing);
      expect(preparando.back, isNull);
      expect(preparando.advance, isNotNull);

      final entregue = await criarPedido(firestore, Status.delivered);
      expect(entregue.advance, isNull);
      expect(entregue.back, isNotNull);
    });

    test('advance muda o status e grava no Firestore', () async {
      final firestore = FakeFirebaseFirestore();
      final order = await criarPedido(firestore, Status.preparing);

      order.advance!();
      await pumpEventQueue();

      expect(order.status, Status.transporting);
      final doc = await firestore.doc('orders/42').get();
      expect(doc.data()!['status'], Status.transporting.index);
    });
  });

  group('Store', () {
    Future<Store> criarLoja(Map<String, dynamic> opening,
        {String complement = ''}) async {
      final firestore = FakeFirebaseFirestore();
      await firestore.doc('stores/s1').set({
        'name': 'Loja Centro',
        'image': 'https://exemplo.com/loja.png',
        'phone': '(11) 98765-4321',
        'address': {
          'street': 'Rua A',
          'number': '10',
          'complement': complement,
          'district': 'Centro',
          'city': 'São Paulo',
          'state': 'SP',
          'lat': -23.5,
          'long': -46.6,
        },
        'opening': opening,
      });
      return Store.fromDocument(await firestore.doc('stores/s1').get());
    }

    test('openingText mostra horários e dias fechados', () async {
      final store = await criarLoja(
          {'monfri': '08:00-18:30', 'saturday': '09:00-13:00', 'sunday': ''});

      expect(store.openingText,
          'Seg-Sex: 8h00 - 18h30\nSab: 9h00 - 13h00\nDom: Fechada');
      expect(store.opening['sunday'], isNull);
      expect(store.opening['monfri']!['to'],
          const TimeOfDay(hour: 18, minute: 30));
    });

    test('loja sem horário nenhum fica fechada', () async {
      final store =
          await criarLoja({'monfri': '', 'saturday': '', 'sunday': ''});

      expect(store.status, StoreStatus.closed);
      expect(store.statusText, 'Fechada');
    });

    test('addressText inclui o complemento só quando existe', () async {
      expect((await criarLoja({})).addressText,
          'Rua A, 10 - Centro, São Paulo/SP');
      expect((await criarLoja({}, complement: 'sala 2')).addressText,
          'Rua A, 10 - sala 2 - Centro, São Paulo/SP');
    });

    test('cleanPhone deixa só os dígitos', () async {
      expect((await criarLoja({})).cleanPhone, '11987654321');
    });
  });
}
