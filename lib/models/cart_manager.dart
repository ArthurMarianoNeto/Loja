import 'package:loja/models/cart_product.dart';
import 'package:loja/models/product.dart';

class CartManager {

  List<CartProduct> items = [];

  void addToCart(Product product){
    items.add(CartProduct.fromProduct(product));
  }

}