import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loja/common/custom_drawer/custom_drawer.dart';
import 'package:loja/models/page_manager.dart';
import 'package:loja/screens/admin_orders/admin_orders_screen.dart';
import 'package:loja/screens/admin_users/admin_users_screen.dart';
import 'package:loja/screens/home/home_screen.dart';
import 'package:loja/screens/login/login_screen.dart';
import 'package:loja/screens/orders/orders_screen.dart';
import 'package:loja/screens/products/products_screen.dart';
import 'package:provider/provider.dart';
import 'package:loja/models/user_manager.dart';

class BaseScreen extends StatefulWidget {

  @override
  _BaseScreenState createState() => _BaseScreenState();
}

class _BaseScreenState extends State<BaseScreen> {

  final PageController pageController = PageController();

// App funciona apenas em visualização vertical
  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp
    ]);
  }

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
              OrdersScreen(),
              Scaffold(
                drawer: CustomDrawer(),
                appBar: AppBar(
                  title: const Text('Nossas Lojas'),
                ),
              ),
              Scaffold(
                drawer: CustomDrawer(),
                appBar: AppBar(
                  title: const Text('Fale Conosco'),
                ),
              ),
              if(userManager.adminEnabled)
                ...[
                  AdminUsersScreen(),
                  AdminOrdersScreen(),
                ]
            ],
          );
        },
      ),
    );
  }
}