import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/foundation.dart';
import 'package:loja/models/order.dart';
import 'package:loja/models/app_user.dart';
import 'dart:async';

class OrdersManager extends ChangeNotifier {
  AppUser? user;

  List<Order> orders = [];

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  StreamSubscription? _subscription; // import 'dart:async';

  void updateUser(AppUser? user) {
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
        .where('user', isEqualTo: user!.id)
        .snapshots()
        .listen((event) {
      orders.clear();
      for (final doc in event.docs) {
        orders.add(Order.fromDocument(doc));
      }
    notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
