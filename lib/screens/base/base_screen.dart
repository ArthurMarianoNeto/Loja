import 'package:flutter/material.dart';
import 'package:loja/common/custom_drawer/custom_drawer.dart';
import 'package:loja/models/page_manager.dart';
import 'package:loja/screens/home/home_screen.dart';
import 'package:loja/screens/login/login_screen.dart';
import 'package:loja/screens/products/products_screen.dart';
import 'package:provider/provider.dart';
import 'package:loja/models/user_manager.dart';

class BaseScreen extends StatelessWidget {

  final PageController pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (_) => PageManager(pageController),
      child: Consumer<UserManager>(
        builder: (_, userManager, __){
          return PageView(
            controller: pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: <Widget>[
              HomeScreen(),
              ProductsScreen(),
              Scaffold(
                drawer: CustomDrawer(),
                appBar: AppBar(
                  title: const Text('Home3'),
                ),
              ),
              Scaffold(
                drawer: CustomDrawer(),
                appBar: AppBar(
                  title: const Text('Home4'),
                ),
              ),
              if(userManager.adminEnabled)
                ...[
                  Scaffold(
                    drawer: CustomDrawer(),
                    appBar: AppBar(
                      title: const Text('Usuários'),
                    ),
                  ),
                  Scaffold(
                    drawer: CustomDrawer(),
                    appBar: AppBar(
                      title: const Text('Pedidos'),
                    ),
                  ),
                ]
            ],
          );
        },
      ),
    );
  }
}