import 'package:flutter/material.dart';
import 'package:loja/models/address.dart';
import 'package:gal/gal.dart';
import 'package:screenshot/screenshot.dart';

class ExportAddressDialog extends StatelessWidget {

  ExportAddressDialog(this.address, {super.key});

  final Address address;

  final ScreenshotController screenshotController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Endereço de Entrega'),
      content: Screenshot(
        controller: screenshotController,
        child: Container(
          padding: const EdgeInsets.all(8),
          color: Colors.white,
          child: Text(
            '${address.street}, ${address.number}\n'
                ' ${address.complement}\n'
                '${address.district}\n'
                '${address.city} / ${address.state}\n'
                '${address.zipCode}',
          ),
        ),
      ),
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      actions: <Widget>[
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Theme.of(context).primaryColor),
          onPressed: () async {
            Navigator.of(context).pop();
            final bytes = await screenshotController.capture();
            if(bytes != null){
              await Gal.putImageBytes(bytes, name: 'endereco_entrega');
            }
          },
          child: const Text('Exportar'),
        )
      ],
    );
  }
}