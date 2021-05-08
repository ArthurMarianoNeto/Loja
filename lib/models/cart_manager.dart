import 'package:loja/models/address.dart';
import 'package:loja/models/cart_product.dart';
import 'package:loja/models/product.dart';
import 'package:loja/models/user.dart';
import 'package:loja/models/user_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:loja/services/cep_aberto_service.dart';
import 'package:loja/screens/address/address_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';

class CartManager extends ChangeNotifier {

  List<CartProduct> items = [];

  User user;
  Address address;

  num productsPrice = 0.0;

  void updateUser(UserManager userManager){
    user = userManager.user;
    items.clear();

    if(user != null){
      _loadCartItems();
    }
  }

  Future<void> _loadCartItems() async {
    final QuerySnapshot cartSnap = await user.cartReference.getDocuments();

    items = cartSnap.documents.map(
            (d) => CartProduct.fromDocument(d)..addListener(_onItemUpdated)
    ).toList();
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

  // ADDRESS

  Future<void> getAddress(String cep) async {
    final cepAbertoService = CepAbertoService(); // específico do ceb aberto

    try {
      // caso tenha outra API para busca de endereço basta trocar estas linhas abaxio
      final cepAbertoAddress =
        await cepAbertoService.getAddressFromCep(cep); // tratando do address do app geral

      if(cepAbertoAddress != null){
        address = Address(
            street: cepAbertoAddress.logradouro,
            district: cepAbertoAddress.bairro,
            zipCode: cepAbertoAddress.cep,
            city: cepAbertoAddress.cidade.nome,
            state: cepAbertoAddress.estado.sigla,
            lat: cepAbertoAddress.latitude,
            long: cepAbertoAddress.longitude
        );
        notifyListeners();
      }
    } catch (e){
      debugPrint(e.toString());
    }
  }

  void removeAddress(){
    address = null;
    notifyListeners();
  }

}