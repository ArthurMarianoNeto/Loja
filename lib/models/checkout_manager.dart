import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/foundation.dart';
import 'package:loja/models/cart_manager.dart';
import 'package:loja/models/credit_card.dart';
import 'package:loja/models/order.dart';
import 'package:loja/models/product.dart';
import 'package:loja/services/cielo_payment.dart';

class CheckoutManager extends ChangeNotifier {

  CheckoutManager({FirebaseFirestore? firestore, CieloPayment? cieloPayment})
      : firestore = firestore ?? FirebaseFirestore.instance,
        cieloPayment = cieloPayment ?? CieloPayment();

  late CartManager cartManager;
  bool _loading = false;
  bool get loading => _loading;
  set loading(bool value){
    _loading = value;
    notifyListeners();
  }

  final FirebaseFirestore firestore;
  final CieloPayment cieloPayment;


  // ignore: use_setters_to_change_properties
  void updateCart(CartManager cartManager){
    this.cartManager = cartManager;
  }

  // Verificando se temos estoque diponível
  Future<void> checkout({required CreditCard creditCard,
    required void Function(Object) onStockFail,
    required void Function(Order) onSuccess,
    required void Function(Object) onPayFail}) async {

    loading = true;

    final orderId = await _getOrderId(); // gerando número unico do pedido

    String payId;
    try {
       payId = await cieloPayment.authorize(
        creditCard: creditCard,
        price: cartManager.totalPrice,
        orderId: orderId.toString(),
        user: cartManager.user!,
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
  }

  Future<int> _getOrderId() async { // salvando o firebase
    final ref = firestore.doc('aux/ordercounter');

    try {
      return await firestore.runTransaction((tx) async {
        final doc = await tx.get(ref);
        final orderId = doc.data()!['current'] as int;
        tx.update(ref, {'current': orderId + 1});
        return orderId;
      });
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
              firestore.doc('products/${cartProduct.productId}')
          );
          product = Product.fromDocument(doc);
        }

        cartProduct.product = product;

        final size = product.findSize(cartProduct.size);
        if(size == null || (size.stock ?? 0) - cartProduct.quantity < 0){
          productsWithoutStock.add(product);
        } else {
          size.stock = size.stock! - cartProduct.quantity;
          productsToUpdate.add(product);
        }
      }

      if(productsWithoutStock.isNotEmpty){
        return Future.error(
            '${productsWithoutStock.length} produtos sem estoque');
      }

      for(final product in productsToUpdate){
        tx.update(firestore.doc('products/${product.id}'),
            {'sizes': product.exportSizeList()});
      }
    });
  }

}
