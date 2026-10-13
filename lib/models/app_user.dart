import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:loja/models/address.dart';
import 'dart:io';

class AppUser {

  AppUser({this.email, this.password, this.name, this.id});

  AppUser.fromDocument(DocumentSnapshot<Map<String, dynamic>> document){
    id = document.id;
    name = document.data()!['name'] as String?;
    email = document.data()!['email'] as String?;
    cpf = document.data()!['cpf'] as String?;
    if(document.data()!.containsKey('address')){
      address = Address.fromMap(
          document.data()!['address'] as Map<String, dynamic>);
    }
  }

  String? id;
  String? name;
  String? email;
  String? cpf;
  String? password;

  String? confirmPassword;

  bool admin = false;

  Address? address;

  DocumentReference<Map<String, dynamic>> get firestoreRef =>
      FirebaseFirestore.instance.doc('users/$id');

  CollectionReference<Map<String, dynamic>> get cartReference =>
      firestoreRef.collection('cart');

  CollectionReference<Map<String, dynamic>> get tokensReference =>
      firestoreRef.collection('tokens');

  Future<void> saveData() async {
    await firestoreRef.set(toMap());
  }

  Map<String, dynamic> toMap(){
    return {
      'name': name,
      'email': email,
      if(address != null)
        'address': address!.toMap(),
      if(cpf != null)
        'cpf': cpf
    };
  }

  void setAddress(Address address){
    this.address = address;
    saveData();
  }

  void setCpf(String? cpf){
    this.cpf = cpf;
    saveData();
  }

  Future<void> saveToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    if(token == null) return;
    await tokensReference.doc(token).set({
      'token': token,
      'updatedAt': FieldValue.serverTimestamp(),
      'platform': Platform.operatingSystem,
    });
  }
}
