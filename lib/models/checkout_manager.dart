import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:loja/models/cart_manager.dart';
import 'package:loja/models/credit_card.dart';
import 'package:loja/models/order.dart';
import 'package:loja/models/product.dart';
import 'package:loja/services/cielo_payment.dart';

class CheckoutManager extends ChangeNotifier {

  CartManager cartManager;
  bool _loading = false;
  bool get loading => _loading;
  set loading(bool value){
    _loading = value;
    notifyListeners();
  }

  final Firestore firestore = Firestore.instance;
  final CieloPayment cieloPayment = CieloPayment();


  // ignore: use_setters_to_change_properties
  void updateCart(CartManager cartManager){
    this.cartManager = cartManager;
  }

  // Verificando se temos estoque diponível
  Future<void> checkout({CreditCard creditCard,
    Function onStockFail,
    Function onSuccess,
    Function onPayFail}) async {

    loading = true;

//    print(creditCard.toJson());

    final orderId = await _getOrderId(); // gerando número unico do pedido

    String payId;
    try {
       payId = await cieloPayment.authorize(
        creditCard: creditCard,
        price: cartManager.totalPrice,
        orderId: orderId.toString(),
        user: cartManager.user,
      );

      debugPrint('success $payId');

    } catch (e) {
      onPayFail(e);
      loading = false;
      return;
    }

    try {
      await _decrementStock(); // decrementando estoque
    } catch (e){
      cieloPayment.cancel(payId);
      onStockFail(e);
      loading = false;
 //     debugPrint(e.toString());
      return;
    }

    try {
      await cieloPayment.capture(payId);
    } catch (e) {
      onPayFail(e);
      loading = false;
      return;
    }


    final order = Order.fromCartManager(cartManager); // gerando objeto do pedido
    order.orderId = orderId.toString(); // salvando ID do pedido no objeto do pedido
    order.payId = payId; // salvando pedido para caso queira cancelar
    await order.save(); // pedido está se salvando

    cartManager.clear();

    onSuccess(order);

    loading = false;

 //   _getOrderId().then((value) => print(value));
  }

  Future<int> _getOrderId() async { // salvando o firebase
    final ref = firestore.document('aux/ordercounter');

    try {
      final result = await firestore.runTransaction((tx) async {
        final doc = await tx.get(ref);
        final orderId = doc.data['current'] as int;
        await tx.update(ref, {'current': orderId + 1});
        return {'orderId': orderId};
      });
      return result['orderId'] as int;
    } catch (e){
      debugPrint(e.toString());
      return Future.error('Falha ao gerar número do pedido');
    }
  }

  Future<void> _decrementStock(){
    // 1. Ler todos os estoques 3xM
    // 2. Decremento localmente os estoques 2xM
    // 3. Salvar os estoques no firebase 2xM

    return firestore.runTransaction((tx) async {
      final List<Product> productsToUpdate = [];
      final List<Product> productsWithoutStock = [];

      for(final cartProduct in cartManager.items){
        Product product;

        if(productsToUpdate.any((p) => p.id == cartProduct.productId)){
          product = productsToUpdate.firstWhere(
                  (p) => p.id == cartProduct.productId);
        } else {
          final doc = await tx.get(
              firestore.document('products/${cartProduct.productId}')
          );
          product = Product.fromDocument(doc);
        }

        cartProduct.product = product;

        final size = product.findSize(cartProduct.size);
        if(size.stock - cartProduct.quantity < 0){
          productsWithoutStock.add(product);
        } else {
          size.stock -= cartProduct.quantity;
          productsToUpdate.add(product);
        }
      }

      if(productsWithoutStock.isNotEmpty){
        return Future.error(
            '${productsWithoutStock.length} produtos sem estoque');
      }

      for(final product in productsToUpdate){
        tx.update(firestore.document('products/${product.id}'),
            {'sizes': product.exportSizeList()});
      }
    });
  }

}