import 'dart:async';
import 'package:another_flushbar/flushbar.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loja/common/custom_drawer/custom_drawer.dart';
import 'package:loja/models/page_manager.dart';
import 'package:loja/screens/admin_orders/admin_orders_screen.dart';
import 'package:loja/screens/admin_users/admin_users_screen.dart';
import 'package:loja/screens/home/home_screen.dart';
import 'package:loja/screens/orders/orders_screen.dart';
import 'package:loja/screens/products/products_screen.dart';
import 'package:loja/screens/stores/stores_screen.dart';
import 'package:provider/provider.dart';
import 'package:loja/models/user_manager.dart';


class BaseScreen extends StatefulWidget {
  const BaseScreen({super.key});


  @override
  _BaseScreenState createState() => _BaseScreenState();
}

class _BaseScreenState extends State<BaseScreen> {

  final PageController pageController = PageController();

  StreamSubscription<RemoteMessage>? _onMessageSubscription;
  StreamSubscription<RemoteMessage>? _onMessageOpenedSubscription;

// App funciona apenas em visualização vertical
  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp
    ]);

    configFCM();
  }

  void configFCM(){
    // iOS e Android 13+ pedem permissão para exibir notificações
    FirebaseMessaging.instance.requestPermission(provisional: true);

    _onMessageOpenedSubscription =
        FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('onMessageOpenedApp ${message.data}');
    });

    // mensagens recebidas com o app aberto
    _onMessageSubscription = FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if(notification != null){
        showNotification(
          notification.title ?? '',
          notification.body ?? '',
        );
      }
    });
  }

  @override
  void dispose() {
    _onMessageSubscription?.cancel();
    _onMessageOpenedSubscription?.cancel();
    pageController.dispose();
    super.dispose();
  }

  void showNotification(String title, String message){
    Flushbar(
      title: title,
      message: message,
      flushbarPosition: FlushbarPosition.TOP,
      flushbarStyle: FlushbarStyle.GROUNDED,
      isDismissible: true,
      backgroundColor: Theme.of(context).primaryColor,
      duration: const Duration(seconds: 5),
      icon: Icon(Icons.shopping_cart, color: Colors.white,),
    ).show(context);

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
              StoresScreen(),
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