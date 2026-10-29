import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:loja/models/item_size.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';

class Product extends ChangeNotifier {

  Product({this.id, this.name = '', this.description = '',
    List<String>? images, List<ItemSize>? sizes, this.deleted = false})
      : images = images ?? [],
        sizes = sizes ?? [];

  Product.fromDocument(DocumentSnapshot<Map<String, dynamic>> document){
    id = document.id;
    name = document['name'] as String? ?? '';
    description = document['description'] as String? ?? '';
    images = List<String>.from(document.data()!['images'] as List<dynamic>? ?? []);
    deleted = (document.data()!['deleted'] ?? false) as bool;
    sizes = (document.data()!['sizes'] as List<dynamic>? ?? []).map(
            (s) => ItemSize.fromMap(s as Map<String, dynamic>)).toList();
  }

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  DocumentReference<Map<String, dynamic>> get firestoreRef => firestore.doc('products/$id');
  Reference get storageRef => storage.ref().child('products').child(id!);

  String? id;
  String name = '';
  String description = '';
  List<String> images = [];
  List<ItemSize> sizes = [];

  List<dynamic>? newImages;

  bool deleted = false;

  bool _loading = false;
  bool get loading => _loading;
  set loading(bool value){
    _loading = value;
    notifyListeners();
  }

  ItemSize? _selectedSize;
  ItemSize? get selectedSize => _selectedSize;
  set selectedSize(ItemSize? value){
    _selectedSize = value;
    notifyListeners();
  }

  int get totalStock {
    int stock = 0;
    for(final size in sizes){
      stock += size.stock ?? 0;
    }
    return stock;
  }

  bool get hasStock {
    return totalStock > 0 && !deleted;
  }

  num get basePrice {
    num lowest = double.infinity;
    for(final size in sizes){
      final price = size.price;
      if(price != null && price < lowest) {
        lowest = price;
      }
    }
    return lowest;
  }

  ItemSize? findSize(String? name){
    try {
      return sizes.firstWhere((s) => s.name == name);
    } catch (e){
      return null;
    }
  }

  List<Map<String, dynamic>> exportSizeList(){
    return sizes.map((size) => size.toMap()).toList();
  }

  Future<void> save() async {
    loading = true;

    final Map<String, dynamic> data = {
      'name': name,
      'description': description,
      'sizes': exportSizeList(),
      'deleted': deleted
    };

    if(id == null){
      final doc = await firestore.collection('products').add(data);
      id = doc.id;
    } else {
      await firestoreRef.update(data);
    }

    final List<String> updateImages = [];
    final selectedImages = newImages ?? [];

    for(final newImage in selectedImages){
      if(images.contains(newImage)){
        updateImages.add(newImage as String);
      } else {
        final TaskSnapshot snapshot =
            await storageRef.child(const Uuid().v1()).putFile(newImage as File);
        final String url = await snapshot.ref.getDownloadURL();
        updateImages.add(url);
      }
    }

    for(final image in images){
      if(!selectedImages.contains(image) && image.contains('firebase')){
        try {
          final ref = storage.refFromURL(image);
          await ref.delete();
        } catch (e){
          debugPrint('Falha ao deletar $image');
        }
      }
    }

    await firestoreRef.update({'images': updateImages});

    images = updateImages;

    loading = false;
  }

  void delete(){
    firestoreRef.update({'deleted': true});
  }

  Product clone(){
    return Product(
      id: id,
      name: name,
      description: description,
      images: List.from(images),
      sizes: sizes.map((size) => size.clone()).toList(),
      deleted: deleted,
    );
  }

  @override
  String toString() {
    return 'Product{id: $id, name: $name, description: $description, images: $images, sizes: $sizes, newImages: $newImages}';
  }
}
