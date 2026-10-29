import 'package:flutter/material.dart';

// substitui o Carousel do carousel_pro (descontinuado): páginas com
// indicadores de posição sobrepostos na parte de baixo
class ImageCarousel extends StatefulWidget {

  const ImageCarousel({super.key, required this.children, this.dotColor});

  final List<Widget> children;
  final Color? dotColor;

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {

  final PageController controller = PageController();
  int page = 0;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = widget.dotColor ?? Theme.of(context).primaryColor;
    final count = widget.children.length;

    return Stack(
      children: <Widget>[
        PageView(
          controller: controller,
          onPageChanged: (value) => setState(() => page = value),
          children: widget.children,
        ),
        if(count > 1)
          Positioned(
            left: 0,
            right: 0,
            bottom: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                for(int i = 0; i < count; i++)
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == page ? dotColor : dotColor.withAlpha(90),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
