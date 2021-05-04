import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CepImputField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          decoration: const InputDecoration(
            isDense: true,
            labelText: 'CEP',
              hintText: '99.999-999'
          ),
          inputFormatters: [
            WhitelistingTextInputFormatter.digitsOnly,
          ],
          keyboardType: TextInputType.number,
        ),
        RaisedButton(
          onPressed: (){

          },
          color: primaryColor,
          disabledColor: primaryColor.withAlpha(100),
          child: const Text('Buscar CEP'),
          textColor: Colors.white,
        ),
      ],
    );
  }
}
