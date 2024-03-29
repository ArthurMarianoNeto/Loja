import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:loja/models/address.dart';
import 'package:loja/models/cart_product.dart';
import 'package:loja/models/cep_aberto_address.dart';
import 'package:loja/services/cep_aberto_service.dart';
import 'package:loja/models/product.dart';
import 'package:loja/models/user.dart';
import 'package:loja/models/user_manager.dart';
import 'package:loja/screens/address/address_screen.dart';




class CartManager extends ChangeNotifier {

  List<CartProduct> items = [];

  User user;
  Address address;

  num productsPrice = 0.0;
  num devliveryPrice;

  num get totalPrice => productsPrice + (devliveryPrice ?? 0);

  bool _loading = false;
  bool get loading => _loading;
  set loading(bool value){
    _loading = value;
    notifyListeners();
  }

  final Firestore firestore = Firestore.instance;

  void updateUser(UserManager userManager){
    user = userManager.user;
    productsPrice = 0.0;
    items.clear();
    removeAddress();

    if(user != null){
      _loadCartItems();
      _loadUserAddress();
    }
  }

  Future<void> _loadCartItems() async {
    final QuerySnapshot cartSnap = await user.cartReference.getDocuments();

    items = cartSnap.documents.map(
            (d) => CartProduct.fromDocument(d)..addListener(_onItemUpdated)
    ).toList();
  }

  Future<void> _loadUserAddress() async {
    if(user.address != null
        && await calculateDelivery(user.address.lat, user.address.long)){ //raio de entrega
      address = user.address;
      notifyListeners();
    }
  }

  void addToCart(Product product){
    try {
      final e = items.firstWhere((p) => p.stackable(product));
      e.increment();
    } catch (e){
      final cartProduct = CartProduct.fromProduct(product);
      cartProduct.addListener(_onItemUpdated);
      items.add(cartProduct);
      user.cartReference.add(cartProduct.toCartItemMap())
          .then((doc) => cartProduct.id = doc.documentID);
      _onItemUpdated();
    }
    notifyListeners();
  }

  void removeOfCart(CartProduct cartProduct){
    items.removeWhere((p) => p.id == cartProduct.id);
    user.cartReference.document(cartProduct.id).delete();
    cartProduct.removeListener(_onItemUpdated);
    notifyListeners();
  }

  void _onItemUpdated(){
    productsPrice = 0.0;

    for(int i = 0; i<items.length; i++){
      final cartProduct = items[i];

      if(cartProduct.quantity == 0){
        removeOfCart(cartProduct);
        i--;
        continue;
      }

      productsPrice += cartProduct.totalPrice;

      _updateCartProduct(cartProduct);
    }

    notifyListeners();
  }

  void _updateCartProduct(CartProduct cartProduct){
    if(cartProduct.id != null)
      user.cartReference.document(cartProduct.id)
          .updateData(cartProduct.toCartItemMap());
  }

  bool get isCartValid {
    for(final cartProduct in items){
      if(!cartProduct.hasStock) return false;
    }
    return true;
  }

  bool get isAddressValid => address != null && devliveryPrice != null;

  // ADDRESS

  Future<void> getAddress(String cep) async {
    loading = true;
    final cepAbertoService = CepAbertoService();

    try {
      final cepAbertoAddress = await cepAbertoService.getAddressFromCep(cep);

      if(cepAbertoAddress != null){
        address = Address(
//            complement: cepAbertoAddress.complemento,
            street: cepAbertoAddress.logradouro,
            district: cepAbertoAddress.bairro,
            zipCode: cepAbertoAddress.cep,
            city: cepAbertoAddress.cidade.nome,
            state: cepAbertoAddress.estado.sigla,
            lat: cepAbertoAddress.latitude,
            long: cepAbertoAddress.longitude
        );
        // retirar notifyListeners para não notificar duas vezes em virtude do loadingo false;
 //       notifyListeners(); r
        loading = false;
      }
    } catch (e){
     // debugPrint(e.toString());
      loading = false;
      return Future.error('CEP Inválido');
    }
 //   loading = false;
  }

  Future<void> setAddress(Address address) async {
    loading = true;
    this.address = address;

    if( await calculateDelivery(address.lat, address.long)){
      user.setAddress(address);
//      print('price $devliveryPrice');
      loading = false;
      //      notifyListeners();
    } else {
      loading = false;
      return Future.error('Endereço fora do raio de entrega!');
    }
  }

  void clear(){
    for(final cartProduct in items){
      user.cartReference.document(cartProduct.id).delete();
    }
    items.clear();
    notifyListeners();
  }

  void removeAddress(){
    address = null;
    devliveryPrice = null;
    notifyListeners();
  }

  Future<bool> calculateDelivery(double lat, double long) async {
    final DocumentSnapshot doc = await firestore.document('aux/delivery').get();

    final latStore = doc.data['lat'] as double;
    final longStore = doc.data['long'] as double;

    final base = doc.data['base'] as num;
    final km = doc.data['km'] as num;

    final maxkm = doc.data['maxkm'] as num;

    double dis =
    await Geolocator.distanceBetween(latStore, longStore, lat, long);
 //      await Geolocator().distanceBetween(double 52.2165157, double 6.9437819, 52.3546274, 4.8285838);
//    await GeolocatorPlatform.instance.distanceBetween(latStore, longStore, lat, long);

    dis /= 1000.0;

//    debugPrint('Distance $dis');

    if(dis > maxkm){
      return false;
    }
    devliveryPrice = base + dis * km; // preço mínimo de entrega, adaptar de acordo o necessidade
    return true;
  }
}