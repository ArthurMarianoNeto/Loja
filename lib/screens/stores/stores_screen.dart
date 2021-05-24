import 'package:flutter/material.dart';
import 'package:loja/common/custom_drawer/custom_drawer.dart';
import 'package:loja/models/stores_maager.dart';
import 'package:provider/provider.dart';

class StoresScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: CustomDrawer(),
      appBar: AppBar(
        title: const Text('Nossas Lojas'),
        centerTitle: true,
      ),
      body: Consumer<StoresManager>(
        builder: (_, storesManager, __){
          return Container();
        },
      ),
    );
  }
}