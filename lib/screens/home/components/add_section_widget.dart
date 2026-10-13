import 'package:flutter/material.dart';
import 'package:loja/models/home_manager.dart';
import 'package:loja/models/section.dart';

class AddSectionWidget extends StatelessWidget {

  const AddSectionWidget(this.homeManager, {super.key});

  final HomeManager homeManager;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            onPressed: (){
             homeManager.addSection(Section(type: 'List'));
            },
            child: const Text('Adicionar Lista'),
          ),
        ),
        Expanded(
          child: TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            onPressed: (){
             homeManager.addSection(Section(type: 'Staggered'));
            },
            child: const Text('Adicionar Grade'),
          ),
        ),
      ],
    );
  }
}