import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';

class SettingsWidget extends StatelessWidget {
  const SettingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: SettingsBox(text: "Установить темную тему", value: AdaptiveTheme.of(context).mode.isDark, onPressed: (value){
                  if (value) {
                    AdaptiveTheme.of(context).setDark();
                  } else {
                    AdaptiveTheme.of(context).setLight();
                  }
                })
        )
      ],
    );
  }
}

class SettingsBox extends StatelessWidget {
  final String text; final bool value; final Function(bool) onPressed;
  const SettingsBox({super.key, required this.text, required this.value, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.1,
      width: MediaQuery.of(context).size.width * 0.9,
      child: DecoratedBox(
        decoration: const BoxDecoration(
       
        ),

        child: Row(children: [
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: Text(text, style: const TextStyle(fontSize: 20),),
          ), 
          const Spacer(),
             Switch(
              value: value,
              onChanged: (value) {
               onPressed(value);
              },
            ),
        ],),
      ),
    );
  }
}
