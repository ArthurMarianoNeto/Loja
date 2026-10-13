import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:loja/models/section_item.dart';

class Section extends ChangeNotifier {
  Section({this.id, this.name, this.type, List<SectionItem>? items})
      : items = items ?? [] {
    originalItems = List.from(this.items);
  }

  Section.fromDocument(DocumentSnapshot<Map<String, dynamic>> document) {
    id = document.id;
    name = document.data()!['name'] as String?;
    type = document.data()!['type'] as String?;
    items = (document.data()!['items'] as List? ?? [])
        .map((i) => SectionItem.fromMap(i as Map<String, dynamic>))
        .toList();
    originalItems = List.from(items);
  }

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  DocumentReference<Map<String, dynamic>> get firestoreRef => firestore.doc('home/$id');
  Reference get storageRef => storage.ref().child('home/$id');

  String? id;
  String? name;
  String? type;
  List<SectionItem> items = [];
  List<SectionItem> originalItems = [];

  String? _error;
  String? get error => _error;
  set error(String? value) {
    _error = value;
    notifyListeners();
  }

  void addItem(SectionItem item) {
    items.add(item);
    notifyListeners();
  }

  void removeItem(SectionItem item) {
    items.remove(item);
    notifyListeners();
  }

  Future<void> save(int pos) async {
    final Map<String, dynamic> data = {
      'name': name,
      'type': type,
      'pos': pos,
    };

    if (id == null) {
      final doc = await firestore.collection('home').add(data);
      id = doc.id;
    } else {
      await firestoreRef.update(data);
    }
    // transormando imagens do celular em url
    for (final item in items) {
      if (item.image is File) {
        final TaskSnapshot snapshot =
            await storageRef.child(const Uuid().v1()).putFile(item.image as File);
        final String url = await snapshot.ref.getDownloadURL();
        item.image = url;
      }
    }
    for(final original in originalItems){
      if(!items.contains(original)
          && (original.image as String).contains('firebase')){
        try {
          final ref = storage.refFromURL(
              original.image as String
          );
          await ref.delete(); // deletando do Storage
          // ignore: empty_catches
        } catch (e){}
      }
    }

    final Map<String, dynamic> itemsData = {
      'items': items.map((e) => e.toMap()).toList()
    };

    await firestoreRef.update(itemsData);

  }

  Future<void> delete() async {
    await firestoreRef.delete();
    for(final item in items){
      if((item.image as String).contains('firebase')){
        try {
          final ref = storage.refFromURL(
              item.image as String
          );
          await ref.delete();
          // ignore: empty_catches
        } catch (e){}
      }
    }
  }

  bool valid() {
    if (name == null || name!.isEmpty) {
      error = 'Título inválido';
    } else if (items.isEmpty) {
      error = 'Insira ao menos uma imagem';
    } else {
      error = null;
    }
    return error == null;
  }

  Section clone() {
    return Section(
      id: id,
      name: name,
      type: type,
      items: items.map((e) => e.clone()).toList(),
    );
  }

  @override
  String toString() {
    return 'Section{name: $name, type: $type, items: $items}';
  }
}
