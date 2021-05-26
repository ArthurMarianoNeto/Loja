import 'package:flutter/material.dart';
import 'package:loja/screens/checkout/components/card_text_field.dart';

class CardFront extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 16,
      child: Container(
        height: 200,
        color: const Color(0xFF1B4B52),
        padding: const EdgeInsets.all(24),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  CardTextField(
                    title: 'Número',
                    hint: '9999 9999 9999 9999',
                    textInputType: TextInputType.number,
                    bold: true,
                  ),
                  CardTextField(
                    title: 'Validade',
                    hint: '11/2028',
                    textInputType: TextInputType.number,
                  ),
                  CardTextField(
                    title: 'Título',
                    hint: 'Pedro Silva Ferreira',
                    textInputType: TextInputType.text,
                    bold: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}