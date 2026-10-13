import 'package:flutter/material.dart';
import 'package:loja/common/custom_icon_button.dart';
import 'package:loja/models/cart_product.dart';
import 'package:provider/provider.dart';
//testando 
class CartTile extends StatelessWidget {

  const CartTile(this.cartProduct, {super.key});

  final CartProduct cartProduct;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: cartProduct,
      child: Consumer<CartProduct>(
        builder: (_, cartProduct, _){
          // o produto é carregado de forma assíncrona pelo CartProduct
          final product = cartProduct.product;
          if(product == null){
            return const Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SizedBox(height: 96),
            );
          }
          return GestureDetector(
          onTap: (){
            Navigator.of(context).pushNamed('/product',
            arguments: product);
          },
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    height: 80,
                    width: 80,
                    child: Image.network(product.images.first),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            product.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 17.0,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'Tamanho: ${cartProduct.size}',
                              style: TextStyle(fontWeight: FontWeight.w300),
                            ),
                          ),
                          Consumer<CartProduct>(
                            builder: (_, cartProduct, _){
                              if(cartProduct.hasStock) {
                                return Text(
                                  'R\$ ${cartProduct.unitPrice.toStringAsFixed(2)}',
                                  style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold
                                  ),
                                );
                              } else {
                                return Text(
                                  'Sem estoque suficiente',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                );
                              }
                            },
                          )
                        ],
                      ),
                    ),
                  ),
                  Consumer<CartProduct>(
                    builder: (_, cartProduct, _){
                      return Column(
                        children: <Widget>[
                          CustomIconButton(
                            iconData: Icons.add,
                            color: Theme.of(context).primaryColor,
                            onTap: cartProduct.increment,
                          ),
                          Text(
                            '${cartProduct.quantity}',
                            style: const TextStyle(fontSize: 20),
                          ),
                          CustomIconButton(
                            iconData: Icons.remove,
                            color: cartProduct.quantity > 1 ?
                            Theme.of(context).primaryColor : Colors.red,
                            onTap: cartProduct.decrement,
                          ),
                        ],
                      );
                    },
                  )
                ],
              ),
            ),
          ),
        );
        },
      ),
    );
  }
}