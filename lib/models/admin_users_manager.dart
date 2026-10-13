import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:loja/models/app_user.dart';
import 'package:loja/models/user_manager.dart';

class AdminUsersManager extends ChangeNotifier {

  AdminUsersManager({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  List<AppUser> users = [];

  final FirebaseFirestore firestore;

  StreamSubscription? _subscription;

  void updateUser(UserManager userManager){
    _subscription?.cancel();
    if(userManager.adminEnabled){
      _listenToUsers();
    } else {
      users.clear();
      notifyListeners();
    }
  }

  void _listenToUsers(){
    _subscription = firestore.collection('users').snapshots()
        .listen((snapshot){
      users = snapshot.docs.map((d) => AppUser.fromDocument(d)).toList();
      users.sort((a, b) =>
          (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()));
      notifyListeners();
    });
  }

  List<String> get names => users.map((e) => e.name ?? '').toList();

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
