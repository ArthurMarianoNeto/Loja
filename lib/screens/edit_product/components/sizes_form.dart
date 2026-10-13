import 'package:flutter/material.dart';
import 'package:loja/common/custom_icon_button.dart';
import 'package:loja/models/item_size.dart';
import 'package:loja/models/product.dart';
import 'package:loja/screens/edit_product/components/edit_item_size.dart';

class SizesForm extends StatelessWidget {

  const SizesForm(this.product, {super.key});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return FormField<List<ItemSize>>(
      initialValue: product.sizes,
      validator: (sizes){
        if(sizes == null || sizes.isEmpty) {
          return 'Insira uma opção de tamanho';
        }
        return null;
      },
      builder: (state){
        final sizes = state.value!;
        return Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Tamanhos',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500
                    ),
                  ),
                ),
                CustomIconButton(
                  iconData: Icons.add,
                  color: Colors.black,
                  onTap: (){
                    sizes.add(ItemSize());
                    state.didChange(sizes);
                  },
                )
              ],
            ),
            Column(
              children: sizes.map((size){
                return EditItemSize(
                  key: ObjectKey(size),
                  size: size,
                  onRemove: (){
                    sizes.remove(size);
                    state.didChange(sizes);
                  },
                  onMoveUp: size != sizes.first ? (){
                    final index = sizes.indexOf(size);
                    sizes.remove(size);
                    sizes.insert(index-1, size);
                    state.didChange(sizes);
                  } : null,
                  onMoveDown: size != sizes.last ? (){
                    final index = sizes.indexOf(size);
                    sizes.remove(size);
                    sizes.insert(index+1, size);
                    state.didChange(sizes);
                  } : null,
                );
              }).toList(),
            ),
            if(state.hasError)
              Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  state.errorText!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              )
          ],
        );
      },
    );
  }
}