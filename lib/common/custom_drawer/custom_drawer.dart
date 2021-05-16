import 'package:flutter/material.dart';
import 'package:loja/common/custom_drawer/custom_drawer_header.dart';
import 'drawer_tile.dart';
import 'package:provider/provider.dart';
import 'package:loja/models/user_manager.dart';


class CustomDrawer extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Stack(
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color.fromARGB(255, 203, 236, 241),
                    Colors.white,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
            ),
          ),
          ListView(
            children: <Widget>[
              CustomDrawerHeader(),
              const Divider(),
              DrawerTile(
                iconData: Icons.home,
                title: 'Início',
                page: 0,
              ),
              DrawerTile(
                iconData: Icons.list,
                title: 'Produtos',
                page: 1,
              ),
              DrawerTile(
                iconData: Icons.playlist_add_check,
                title: 'Meus Pedidos',
                page: 2,
              ),
              DrawerTile(
                iconData: Icons.location_on,
                title: 'Lojas',
                page: 3,
              ),
              DrawerTile(
                iconData: Icons.chat,
                title: 'Fale Conosco',
                page: 4,
              ),
              Consumer<UserManager>(
                builder: (_, userManager, __){
                  if(userManager.adminEnabled){
                    return Column(
                      children: <Widget>[
                        const Divider(),
                        DrawerTile(
                          iconData: Icons.perm_contact_calendar_outlined,
                          title: 'Usuários',
                          page: 5,
                        ),
                        DrawerTile(
                          iconData: Icons.settings,
                          title: 'ADM Pedidos',
                          page: 6,
                        ),
                      ],
                    );
                  } else {
                    return Container();
                  }
                },
              )
            ],
          ),
        ],
      ),
    );
  }
}