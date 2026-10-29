import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:loja/models/address.dart';
import 'package:loja/models/cart_product.dart';
import 'package:loja/services/cep_aberto_service.dart';
import 'package:loja/models/product.dart';
import 'package:loja/models/app_user.dart';
import 'package:loja/models/user_manager.dart';


class CartManager extends ChangeNotifier {

  List<CartProduct> items = [];

  AppUser? user;
  Address? address;

  num productsPrice = 0.0;
  num? devliveryPrice;

  num get totalPrice => productsPrice + (devliveryPrice ?? 0);

  bool _loading = false;
  bool get loading => _loading;
  set loading(bool value){
    _loading = value;
    notifyListeners();
  }

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

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
    final QuerySnapshot<Map<String, dynamic>> cartSnap = await user!.cartReference.get();

    items = cartSnap.docs.map(
            (d) => CartProduct.fromDocument(d)..addListener(_onItemUpdated)
    ).toList();
  }

  Future<void> _loadUserAddress() async {
    final userAddress = user!.address;
    if(userAddress != null
        && await calculateDelivery(userAddress.lat, userAddress.long)){ //raio de entrega
      address = userAddress;
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
      user!.cartReference.add(cartProduct.toCartItemMap())
          .then((doc) => cartProduct.id = doc.id);
      _onItemUpdated();
    }
    notifyListeners();
  }

  void removeOfCart(CartProduct cartProduct){
    items.removeWhere((p) => p.id == cartProduct.id);
    user!.cartReference.doc(cartProduct.id).delete();
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
    if(cartProduct.id != null) {
      user!.cartReference.doc(cartProduct.id)
          .update(cartProduct.toCartItemMap());
    }
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

      address = Address(
//          complement: cepAbertoAddress.complemento,
          street: cepAbertoAddress.logradouro,
          district: cepAbertoAddress.bairro,
          zipCode: cepAbertoAddress.cep,
          city: cepAbertoAddress.cidade.nome,
          state: cepAbertoAddress.estado.sigla,
          lat: cepAbertoAddress.latitude,
          long: cepAbertoAddress.longitude
      );
      // retirar notifyListeners para não notificar duas vezes em virtude do loadingo false;
      loading = false;
    } catch (e){
      loading = false;
      return Future.error('CEP Inválido');
    }
  }

  Future<void> setAddress(Address address) async {
    loading = true;
    this.address = address;

    if( await calculateDelivery(address.lat, address.long)){
      user!.setAddress(address);
      loading = false;
    } else {
      loading = false;
      return Future.error('Endereço fora do raio de entrega!');
    }
  }

  void clear(){
    for(final cartProduct in items){
      user!.cartReference.doc(cartProduct.id).delete();
    }
    items.clear();
    notifyListeners();
  }

  void removeAddress(){
    address = null;
    devliveryPrice = null;
    notifyListeners();
  }

  Future<bool> calculateDelivery(double? lat, double? long) async {
    if(lat == null || long == null) return false;

    final DocumentSnapshot<Map<String, dynamic>> doc = await firestore.doc('aux/delivery').get();

    final latStore = doc.data()!['lat'] as double;
    final longStore = doc.data()!['long'] as double;

    final base = doc.data()!['base'] as num;
    final km = doc.data()!['km'] as num;

    final maxkm = doc.data()!['maxkm'] as num;

    double dis = Geolocator.distanceBetween(latStore, longStore, lat, long);

    dis /= 1000.0;

    if(dis > maxkm){
      return false;
    }
    devliveryPrice = base + dis * km; // preço mínimo de entrega, adaptar de acordo o necessidade
    return true;
  }
}
