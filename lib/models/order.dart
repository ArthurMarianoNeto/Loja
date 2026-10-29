import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:loja/models/address.dart';
import 'package:loja/models/cart_manager.dart';
import 'package:loja/models/cart_product.dart';
import 'package:loja/services/cielo_payment.dart';


enum Status { canceled, preparing, transporting, delivered }

class Order {

  Order.fromCartManager(CartManager cartManager){
    items = List.from(cartManager.items);
    price = cartManager.totalPrice;
    userId = cartManager.user!.id!;
    address = cartManager.address!;
    status = Status.preparing;
  }

  Order.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc){
    orderId = doc.id;

    items = (doc.data()!['items'] as List<dynamic>).map((e){
      return CartProduct.fromMap(e as Map<String, dynamic>);
    }).toList();

    price = doc.data()!['price'] as num;
    userId = doc.data()!['user'] as String;
    address = Address.fromMap(doc.data()!['address'] as Map<String, dynamic>);
    date = doc.data()!['date'] as Timestamp?;

    status = Status.values[doc.data()!['status'] as int];

    payId = doc.data()!['payId'] as String?;
  }

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get firestoreRef =>
      firestore.collection('orders').doc(orderId);

  void updateFromDocument(DocumentSnapshot<Map<String, dynamic>> doc){
    status = Status.values[doc.data()!['status'] as int];
  }

  Future<void> save() async {
    firestore.collection('orders').doc(orderId).set(
        {
          'items': items.map((e) => e.toOrderItemMap()).toList(),
          'price': price,
          'user': userId,
          'address': address.toMap(),
          'status': status.index,
          'date': Timestamp.now(),
          'payId': payId,
        }
    );
  }

  VoidCallback? get back {
    return status.index >= Status.transporting.index ?
        (){
      status = Status.values[status.index - 1];
      firestoreRef.update({'status': status.index});
    } : null;
  }

  VoidCallback? get advance {
    return status.index <= Status.transporting.index ?
        (){
      status = Status.values[status.index + 1];
      firestoreRef.update({'status': status.index});
    } : null;
  }

  Future<void> cancel() async {
    try {
      await CieloPayment().cancel(payId!);

      status = Status.canceled;
      firestoreRef.update({'status': status.index});
    } catch (e){
      debugPrint('Erro ao cancelar');
      return Future.error('Falha ao cancelar');
    }
  }

  String? orderId;
  String? payId;

  late List<CartProduct> items;
  late num price;

  late String userId;

  late Address address;

  late Status status;

  Timestamp? date;

  String get formattedId => '#${(orderId ?? '').padLeft(6, '0')}';

  String get statusText => getStatusText(status);

  static String getStatusText(Status status) {
    switch(status){
      case Status.canceled:
        return 'Cancelado';
      case Status.preparing:
        return 'Em preparação';
      case Status.transporting:
        return 'Em transporte';
      case Status.delivered:
        return 'Entregue';
    }
  }

  @override
  String toString() {
    return 'Order{firestore: $firestore, orderId: $orderId, items: $items, price: $price, userId: $userId, address: $address, date: $date}';
  }
}
