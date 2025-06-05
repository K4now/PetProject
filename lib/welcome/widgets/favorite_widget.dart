import 'package:telegram_web_app/telegram_web_app.dart';

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
    return Column(
      children: [
        // current telegram version
        Text(TelegramWebApp.instance.version),

        Text(TelegramWebApp.instance.themeParams.toString()),

// Object containing user details and user validation hash
        Text(TelegramWebApp.instance.initData.toString()),
        ListView.builder(
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
        ),
      ],
    );
  }
}
