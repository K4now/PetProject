import 'package:flip_card/flip_card.dart';
import 'package:flip_card/flip_card_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_analog_clock/flutter_analog_clock.dart';

import 'package:test_project/data/class/card_class.dart';
import 'package:test_project/pages/flip_card_page.dart';
import 'package:test_project/pages/question_page.dart';
import 'package:test_project/widgets/welcome_screen.dart';

import '../logic/navigation/navigation/index.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final _navigationBloc =
      NavigationBloc(const FavoriteNavigationState("Программы"));
  List<CardClass> listCard = [];
 late  FlipCardController _controller;
  @override
  void initState() {
    _controller = _controller = FlipCardController();
    listCard = [
      CardClass(
        colorText: Colors.white,
        color: Colors.pink.withOpacity(0.8),
        name: "Часики",
        description: "Учишься определять время по аналоговым часам",
        child: const AnalogClock(),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (BuildContext context) => const QusetionPage(),
            ),
          );
        },
      ),
      CardClass(
        colorText: Colors.white,
        color: Colors.green.withOpacity(0.8),
        name: "Карточки",
        description: "Найди одинаковые карточки",
        child:  FlipCard(
          controller: _controller,
          fill: Fill
              .fillBack, // Fill the back side of the card to make in the same size as the front.
          direction: FlipDirection.HORIZONTAL, 
          side: CardSide.FRONT,
          autoFlipDuration: const Duration(seconds: 1),
          front: SizedBox(
            height: 200,
            width: 200,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.red,
                
              ),
            ),
          ),
          back: SizedBox(
            height: 200,
            width: 200,
            child: DecoratedBox(
             decoration: BoxDecoration(
              color: Colors.blue,
              
            ),
            ),
            
          ),
        
          speed: 500,
        ),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (BuildContext context) => const FLipCardPage(),
            ),
          );
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
