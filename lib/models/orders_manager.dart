import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:loja/models/order.dart';
import 'package:loja/models/user.dart';
import 'dart:async';

class OrdersManager extends ChangeNotifier {
  User user;

  List<Order> orders = [];

  final Firestore firestore = Firestore.instance;
  StreamSubscription _subscription; // import 'dart:async';

  void updateUser(User user) {
    this.user = user;
    orders.clear(); // sempre que atualizar usuário devemos limpar pedidos;

    _subscription?.cancel();

    if (user != null) {
      _listenToOrders();
    }
  }

  void _listenToOrders() {
    _subscription = firestore
        .collection('orders')
        .where('user', isEqualTo: user.id)
        .snapshots()
        .listen((event) {
      orders.clear();
      for (final doc in event.documents) {
        orders.add(Order.fromDocument(doc));
      }
    notifyListeners();
  //    print(orders);
    });
  }

  @override
  void dispose() {
    super.dispose();
    _subscription?.cancel();
  }
}
