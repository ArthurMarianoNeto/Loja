import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';


class ImageSourceSheet extends StatelessWidget {

  ImageSourceSheet({this.onImageSelected});

  final Function(File) onImageSelected;
  final ImagePicker picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return BottomSheet(
      onClosing: (){},
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          FlatButton(
            onPressed: () async {
             final PickedFile file =
                await picker.getImage(source: ImageSource.camera);
             onImageSelected(File(file.path));
 //           Navigator.of(context).pop();
            },
            child: const Text('Câmera'),
          ),
          FlatButton(
            onPressed: () async {
              final PickedFile file =
                  await picker.getImage(source: ImageSource.gallery);
              onImageSelected(File(file.path));
            },
            child: const Text('Galeria'),
          ),
        ],
      ),
    );
  }
}