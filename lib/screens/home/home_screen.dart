import 'package:flutter/material.dart';
import 'package:loja/common/custom_drawer/custom_drawer.dart';
import 'package:loja/models/home_manager.dart';
import 'package:loja/screens/home/components/section_list.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: CustomDrawer(),
      body: Stack(
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: const [
                      Color.fromARGB(255, 211, 118, 130),
                      Color.fromARGB(255, 253, 181, 168)
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter
                )
            ),
          ),
          CustomScrollView(
            slivers: <Widget>[
              SliverAppBar(
                snap: true,
                floating: true,
                elevation: 0,
                backgroundColor: Colors.transparent,
                flexibleSpace: const FlexibleSpaceBar(
                  title: Text('Loja Mega Moda'),
                  centerTitle: true,
                ),
                actions: <Widget>[
                  IconButton(
                    icon: Icon(Icons.shopping_cart),
                    color: Colors.white,
                    onPressed: () => Navigator.of(context).pushNamed('/cart'),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Container(
                  height: 2000,
                  width: 200,
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}