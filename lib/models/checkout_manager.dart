import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:loja/models/cart_manager.dart';


class CheckoutManager extends ChangeNotifier {

  CartManager cartManager;
  final Firestore firestore = Firestore.instance;

  // ignore: use_setters_to_change_properties
  void updateCart(CartManager cartManager){
    this.cartManager = cartManager;
  }

  void checkout() {
    _decrementStock();
    _getOrderId().then((value) => print(value));
  }

  void _decrementStock(){
    // 1. Ler todos os estoques 3xM
    // 2. Decremento localmente os estoques 2xM
    // 3. Salvar os estoques no firebase 2xM
    _getOrderId().then((value) => print(value));
  }

  Future<int> _getOrderId() async {
    final ref = firestore.document('aux/ordercounter');

    try {
      final result = await firestore.runTransaction((tx) async { // tx = transaction
        final doc = await tx.get(ref);
        final orderId = doc.data['current'] as int;
        await tx.update(ref, {'current': orderId + 1});
        return {'orderId': orderId};
      });
      return result['orderId'] as int;
    } catch (e){
      debugPrint(e.toString());
      return Future.error('Falha ao gerar número do pedido');
      // tentará gerar 5 vezes o numero de pedido, depois disto "erro";
    }
  }

}
