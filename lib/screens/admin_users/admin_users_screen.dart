import 'package:alphabet_list_view/alphabet_list_view.dart';
import 'package:loja/common/custom_drawer/custom_drawer.dart';
import 'package:loja/models/admin_orders_manager.dart';
import 'package:loja/models/admin_users_manager.dart';
import 'package:loja/models/app_user.dart';
import 'package:flutter/material.dart';
import 'package:loja/models/page_manager.dart';
import 'package:provider/provider.dart';

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: CustomDrawer(),
      appBar: AppBar(
        title: const Text('Usuários'),
        centerTitle: true,
      ),
      body: Consumer<AdminUsersManager>(
        builder: (_, adminUsersManager, _){
          // agrupa os usuários (já ordenados por nome) pela inicial
          final groups = <String, List<AppUser>>{};
          for(final user in adminUsersManager.users){
            final name = (user.name ?? '').trim();
            final tag = name.isEmpty ? '#' : name[0].toUpperCase();
            groups.putIfAbsent(tag, () => []).add(user);
          }

          Widget userTile(AppUser user){
              return ListTile(
                title: Text(
                  user.name ?? '',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Colors.white
                  ),
                ),
                subtitle: Text(
                  user.email ?? '',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
                onTap: (){
                  context.read<AdminOrdersManager>().setUserFilter(user);
                  //----------------------------------------------------------
                  context.read<PageManager>().setPage(6);
                  //-----------------------------------------------------------
                },
              );
          }

          return AlphabetListView(
            items: groups.entries.map((entry) => AlphabetListViewItemGroup(
              tag: entry.key,
              children: entry.value.map(userTile),
            )).toList(),
            options: AlphabetListViewOptions(
              listOptions: ListOptions(
                listHeaderBuilder: (_, symbol) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(
                    symbol,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              scrollbarOptions: ScrollbarOptions(
                symbols: groups.keys.toList(),
                symbolBuilder: (_, symbol, state) => Text(
                  symbol,
                  style: TextStyle(
                    color: state == AlphabetScrollbarItemState.active
                        ? Colors.white
                        : Colors.white38,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}