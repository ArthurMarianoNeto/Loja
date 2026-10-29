import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:loja/models/item_size.dart';
import 'package:loja/models/product.dart';


class CartProduct extends ChangeNotifier {

  CartProduct.fromProduct(Product product) : _product = product {
    productId = product.id!;
    quantity = 1;
    size = product.selectedSize!.name;
  }

  CartProduct.fromDocument(DocumentSnapshot<Map<String, dynamic>> document){
    id = document.id;
    productId = document.data()!['pid'] as String;
    quantity = document.data()!['quantity'] as int;
    size = document.data()!['size'] as String?;

    firestore.doc('products/$productId').get().then(
            (doc) {
          product = Product.fromDocument(doc);
        }
    );
  }

  CartProduct.fromMap(Map<String, dynamic> map){
    productId = map['pid'] as String;
    quantity = map['quantity'] as int;
    size = map['size'] as String?;
    fixedPrice = map['fixedPrice'] as num?;

    firestore.doc('products/$productId').get().then(
            (doc) {
          product = Product.fromDocument(doc);
        }
    );
  }

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  String? id;

  late String productId;
  late int quantity;
  String? size;

  num? fixedPrice;

  Product? _product;
  Product? get product => _product;
  set product(Product? value){
    _product = value;
    notifyListeners();
  }

  ItemSize? get itemSize => product?.findSize(size);

  num get unitPrice {
    if(product == null) return 0;
    return itemSize?.price ?? 0;
  }

  num get totalPrice => unitPrice * quantity;

  Map<String, dynamic> toCartItemMap(){
    return {
      'pid': productId,
      'quantity': quantity,
      'size': size,

    };
  }

  Map<String, dynamic> toOrderItemMap(){
    return {
      'pid': productId,
      'quantity': quantity,
      'size': size,
      'fixedPrice': fixedPrice ?? unitPrice,
    };
  }

  bool stackable(Product product){
    return product.id == productId && product.selectedSize?.name == size;
  }

  void increment(){
    quantity++;
    notifyListeners();
  }

  void decrement(){
    quantity--;
    notifyListeners();
  }

  bool get hasStock {
    if(product != null && product!.deleted) return false;
    final size = itemSize;
    if(size == null) return false;
    return (size.stock ?? 0) >= quantity;
  }

}
