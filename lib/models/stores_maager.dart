import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:loja/models/store.dart';
import 'dart:async';

class StoresManager extends ChangeNotifier {

  StoresManager({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance {
    _loadStoreList();
    _startTimer();
  }

  List<Store> stores = [];

  Timer? _timer;

  final FirebaseFirestore firestore;

  Future<void> _loadStoreList() async {
    final snapshot = await firestore.collection('stores').get();

    stores = snapshot.docs.map((e) => Store.fromDocument(e)).toList();

    notifyListeners();
  }

  void _startTimer(){
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkOpening();
    });
  }

  void _checkOpening(){
    for(final store in stores) {
      store.updateStatus();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}