import 'package:flutter/material.dart';
import 'package:loja/common/safe_network_image.dart';
import 'package:loja/models/product_manager.dart';
import 'package:provider/provider.dart';

class SelectProductScreen extends StatelessWidget {
  const SelectProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vincular Produto'),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: Consumer<ProductManager>(
        builder: (_, productManager, _){
          return ListView.builder(
            itemCount: productManager.allProducts.length,
            itemBuilder: (_, index){
              final product = productManager.allProducts[index];
              return ListTile(
                leading: SafeNetworkImage(product.images.firstOrNull),
                title: Text(product.name),
                subtitle: Text('R\$ ${product.basePrice.toStringAsFixed(2)}'),
                onTap: (){
                  Navigator.of(context).pop(product);
                },
              );
            },
          );
        },
      ),
    );
  }
}