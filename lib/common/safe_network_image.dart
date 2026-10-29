import 'package:flutter/material.dart';

// Image.network que não quebra a tela: produto sem imagem ou URL com erro
// (404, sem internet) mostram um ícone no lugar
class SafeNetworkImage extends StatelessWidget {

  const SafeNetworkImage(this.url, {super.key, this.fit});

  final String? url;
  final BoxFit? fit;

  @override
  Widget build(BuildContext context) {
    final url = this.url;
    if(url == null || url.isEmpty){
      return const Icon(Icons.image_not_supported, color: Colors.grey);
    }
    return Image.network(
      url,
      fit: fit,
      errorBuilder: (_, _, _) =>
          const Icon(Icons.broken_image, color: Colors.grey),
    );
  }
}
