import 'package:flutter/material.dart';
import 'package:loja/common/custom_icon_button.dart';
import 'package:loja/common/safe_network_image.dart';
import 'package:loja/models/store.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:map_launcher/map_launcher.dart';

// só os mapas listados aqui entram no app (map_launcher 6)
const supportedMaps = <MapApp>[MapApp.google, MapApp.apple, MapApp.waze];

class StoreCard extends StatelessWidget {

  const StoreCard(this.store, {super.key});

  final Store store;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    Color colorForStatus(StoreStatus status){
      switch(status){
        case StoreStatus.closed:
          return Colors.red;
        case StoreStatus.open:
          return Colors.green;
        case StoreStatus.closing:
          return Colors.orange;
      }
    }

    void showError(){
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Esta função não está disponível neste dispositivo'),
            backgroundColor: Colors.red,
          )
      );
    }

    Future<void> openPhone() async {
      final uri = Uri(scheme: 'tel', path: store.cleanPhone);
      if(await canLaunchUrl(uri)){
        launchUrl(uri);
      } else if(context.mounted) {
        showError();
      }
    }

    Future<void > openMap() async {
      try {
        final marker = MapLauncher.marker(LocationCoords(
          store.address.lat ?? 0,
          store.address.long ?? 0,
          title: store.name,
        ));
        final availableMaps = await marker.getSupportedMaps(supportedMaps);
        if(!context.mounted) return;

        showModalBottomSheet(
            context: context,
            builder: (_) {
              return SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    for(final map in availableMaps)
                      ListTile(
                        onTap: (){
                          map.show();
                          Navigator.of(context).pop();
                        },
                        title: Text(map.name),
                        leading: Image.memory(
                          map.iconBytes,
                          width: 30,
                          height: 30,
                        ),
                      )
                  ],
                ),
              );
            }
        );
      } catch (e){
        showError();
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 160,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                SafeNetworkImage(
                  store.image,
                  fit: BoxFit.cover,
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(8)
                        )
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      store.statusText,
                      style: TextStyle(
                        color: colorForStatus(store.status),
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 140,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        store.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                      Text(
                        store.addressText,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                      Text(
                        store.openingText,
                        style: const TextStyle(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    CustomIconButton(
                      iconData: Icons.location_on,
                      color: primaryColor,
                      onTap: openMap,
                    ),
                    CustomIconButton(
                      iconData: Icons.phone,
                      color: primaryColor,
                      onTap: openPhone,
                    ),
                    CustomIconButton(
                      iconData: Icons.chat,
                      color: primaryColor,
                      onTap: (){
                        //TODO WHATSUP

                      },
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}