import '../data/card_class.dart';
import 'package:test_project/welcome/widgets/card_widget.dart';

import 'package:flutter/material.dart';


class FavoriteWidget extends StatelessWidget {
  const FavoriteWidget({
    super.key,
    required this.listCards,
  });


final List<CardClass> listCards;
  

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: listCards.length,
      itemBuilder: (context, index) {
        return CardWidget(
          name: listCards[index].name,
          description: listCards[index].description,
          onPressed: () {
            listCards[index].onPressed();
          },
          color: listCards[index].color,
          colorText: listCards[index].colorText,
          child: listCards[index].child,
        );
      },
    );
  }
}
