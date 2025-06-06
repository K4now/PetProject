import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_analog_clock/flutter_analog_clock.dart';
import 'package:test_project/router/app_router.dart';

import 'package:test_project/welcome/data/card_class.dart';
import 'package:test_project/welcome/widgets/welcome_screen.dart';

import '../bloc/index.dart';

@RoutePage()
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final _navigationBloc =
      NavigationBloc(const FavoriteNavigationState("Программы"));
  List<CardClass> listCard = [];

  @override
  void initState() {
    listCard = [
      CardClass(
        colorText: Colors.white,
        color: Colors.pink.withOpacity(0.8),
        name: "Часики",
        description: "Учишься определять время по аналоговым часам",
        child: const AnalogClock(),
        onPressed: () {
          context.router.push(const QusetionRoute());
        },
      ),
      CardClass(
        colorText: Colors.white,
        color: Colors.red.withOpacity(0.8),
        name: "Крестики нолики",
        description: "Игрулька на двоих",
        child: const Card(
          child: Icon(Icons.close),
        ),
        onPressed: () {
          context.router.push(TicTacRoute());
        },
      ),
      CardClass(
        colorText: Colors.white,
        color: Colors.blue.withOpacity(0.8),
        name: "Распознавание речи",
        description: "Преобразование речи в текст для веб",
        child: const Card(child: Icon(Icons.mic)),
        onPressed: () {
          context.router.push(const SpeechToTextRoute());
        },
      ),
    ];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_navigationBloc.state.props[0].toString()),
      ),
      body: WelcomeScreen(
        listCards: listCard,
        navigationBloc: _navigationBloc,
      ),
      bottomNavigationBar: BottomNavigationBar(
        onTap: (value) {
          _onItemTapped(value);
          switch (value) {
            case 0:
              _navigationBloc.add(FavoriteNavigationEvent());
              break;
            case 1:
              _navigationBloc.add(SettingsNavigationEvent());
              break;
          }
        },
        currentIndex: _selectedIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.gamepad),
            label: 'Программки',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Настройки',
          ),
        ],
      ),
    );
  }

  int _selectedIndex = 0;
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
