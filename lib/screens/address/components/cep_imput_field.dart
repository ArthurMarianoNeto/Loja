import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:brasil_fields/brasil_fields.dart';
import 'package:loja/models/cart_manager.dart';
import 'package:provider/provider.dart';

class CepImputField extends StatelessWidget {
  BuildContext get constext => null;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

 //   String cep;
    final TextEditingController cepController = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: cepController,
          decoration: const InputDecoration(
            isDense: true,
            labelText: 'CEP',
              hintText: '99.999-999'
          ),
          inputFormatters: [
            WhitelistingTextInputFormatter.digitsOnly,
            CepInputFormatter(),
          ],
          keyboardType: TextInputType.number,
          validator: (cep){
            if(cep.isEmpty)
              return 'Campo Obrigatório';
            else if(cep.length != 10)
              return('Quantidade de caracteres inválido');
            return null;
          },
//            onChanged: (text) => cep = text,
        ),
        RaisedButton(
          onPressed: (){
            if(Form.of(context).validate()){
              context.read<CartManager>().getAddress(cepController.text);
            }
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
