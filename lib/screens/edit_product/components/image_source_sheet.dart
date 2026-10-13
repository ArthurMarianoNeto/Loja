import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';


class ImageSourceSheet extends StatelessWidget {

  ImageSourceSheet({super.key, required this.onImageSelected});

  final Function(File) onImageSelected;

  final ImagePicker picker = ImagePicker();

  Future<void> editImage(String path, BuildContext context) async {
    final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: path,
        aspectRatio: const CropAspectRatio(ratioX: 1.0, ratioY: 1.0),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Editar Imagem',
            toolbarColor: Theme.of(context).primaryColor,
            toolbarWidgetColor: Colors.white,
          ),
          IOSUiSettings(
            title: 'Editar Imagem',
            cancelButtonTitle: 'Cancelar',
            doneButtonTitle: 'Concluir',
          ),
        ],
    );
    if(croppedFile != null){
      onImageSelected(File(croppedFile.path));
    }
  }

  Future<void> pickImage(ImageSource source, BuildContext context) async {
    final XFile? file = await picker.pickImage(source: source);
    if(file != null && context.mounted){
      await editImage(file.path, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if(Platform.isAndroid) {
      return BottomSheet(
        onClosing: (){},
        builder: (_) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextButton(
              onPressed: () => pickImage(ImageSource.camera, context),
              child: const Text('Câmera'),
            ),
            TextButton(
              onPressed: () => pickImage(ImageSource.gallery, context),
              child: const Text('Galeria'),
            ),
          ],
        ),
      );
    } else {
      return CupertinoActionSheet(
        title: const Text('Selecionar foto para o item'),
        message: const Text('Escolha a origem da foto'),
        cancelButton: CupertinoActionSheetAction(
          onPressed: Navigator.of(context).pop,
          child: const Text('Cancelar'),
        ),
        actions: <Widget>[
          CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () => pickImage(ImageSource.camera, context),
            child: const Text('Câmera'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => pickImage(ImageSource.gallery, context),
            child: const Text('Galeria'),
          )
        ],
      );
    }
  }
}