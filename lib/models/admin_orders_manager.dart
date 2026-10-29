import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/foundation.dart';
import 'package:loja/models/order.dart';
import 'package:loja/models/app_user.dart';

class AdminOrdersManager extends ChangeNotifier {

  AdminOrdersManager({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  final List<Order> _orders = [];

  AppUser? userFilter;
//  List<Status> statusFilter = [Status.preparing, Status.transporting, Status.delivered];
  List<Status> statusFilter = [Status.preparing, Status.transporting];

  final FirebaseFirestore firestore;

  StreamSubscription? _subscription;

  void updateAdmin({required bool adminEnabled}){
    _orders.clear();

    _subscription?.cancel();
    if(adminEnabled){
      _listenToOrders();
    }
  }

  List<Order> get filteredOrders {
    List<Order> output = _orders.reversed.toList();

    final filter = userFilter;
    if(filter != null){
      output = output.where((o) => o.userId == filter.id).toList();
    }

    return output.where((o) => statusFilter.contains(o.status)).toList();
  }

  void _listenToOrders(){
    _subscription = firestore.collection('orders').snapshots().listen(
            (event) {
          for(final change in event.docChanges){
            switch(change.type){
              case DocumentChangeType.added:
                _orders.add(
                    Order.fromDocument(change.doc)
                );
                break;
              case DocumentChangeType.modified:
                final modOrder = _orders.firstWhere(
                        (o) => o.orderId == change.doc.id);
                modOrder.updateFromDocument(change.doc);
                break;
              case DocumentChangeType.removed:
                debugPrint('Erro Crítico!'); // nunca um documento cancelado será excluído
                break;
            }
          }
          notifyListeners();
        });
  }

  void setUserFilter(AppUser? user){
    userFilter = user;
    notifyListeners();
  }

  void setStatusFilter({required Status status, required bool enabled}){
    if(enabled){
      statusFilter.add(status);
    } else {
      statusFilter.remove(status);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

}
