import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:loja/models/credit_card.dart';
import 'package:loja/screens/checkout/components/card_back.dart';
import 'package:loja/screens/checkout/components/card_front.dart';


class CreditCardWidget extends StatefulWidget {

  const CreditCardWidget(this.creditCard, {super.key});

  final CreditCard creditCard;

  @override
  State<CreditCardWidget> createState() => _CreditCardWidgetState();
}
class _CreditCardWidgetState extends State<CreditCardWidget> {
  final GlobalKey<FlipCardState> cardKey = GlobalKey<FlipCardState>();
  final FocusNode numberFocus = FocusNode();
  final FocusNode dateFocus = FocusNode();
  final FocusNode nameFocus = FocusNode();
  final FocusNode cvvFocus = FocusNode();

//  final CreditCard creditCard;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          FlipCard(
            key: cardKey,
            direction: FlipDirection.HORIZONTAL,
            speed: 700,
            flipOnTouch: false, // Função para virar o cartão
            front: CardFront(
              creditCard: widget.creditCard,
              numberFocus: numberFocus,
              dateFocus: dateFocus,
              nameFocus: nameFocus,
              finished: (){
                cardKey.currentState!.toggleCard();
                cvvFocus.requestFocus();
              },
            ),
            back: CardBack(
              creditCard: widget.creditCard,
              cvvFocus: cvvFocus,
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.white, padding: EdgeInsets.zero),
            onPressed: (){
              cardKey.currentState!.toggleCard();
            },
            child: const Text('Virar cartão'),
          )
        ],
      ),
    );
  }
}