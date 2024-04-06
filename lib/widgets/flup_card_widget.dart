// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:math';

import 'package:flip_card/flip_card.dart';
import 'package:flip_card/flip_card_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_randomcolor/flutter_randomcolor.dart';

class FlipCardScreen extends StatefulWidget {
  const FlipCardScreen({super.key});

  @override
  State<FlipCardScreen> createState() => _FlipCardScreenState();
}

class _FlipCardScreenState extends State<FlipCardScreen> {
  List<FlipCardClass> listCards = [];
  List<FlipCardClass> listSelected = [];

  List<ControllerModel> controllerList = [];
  @override
  void initState() {
    super.initState();

    controllerList = generateListController();
    listCards = generateCard(controllerList);
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemBuilder: ((context, index) {
        return FlipCardWidget(
          model: listCards[index],
          onFlip: (index1) {
            if (listSelected.length < 2) {
              listSelected.add(listCards[index1]);
              if (listSelected.length == 2) {
                if (listSelected[0].index == listSelected[1].index) {
                  print("совпали");
                  listSelected = [];
                } else {
                  print('Не совпали');
                  listCards[index].controller.toggleCard();
                 
                  listSelected = [];
                }
              }
              print(listSelected);
            }
          },
        );
      }),
      itemCount: listCards.length,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4),
    );
  }
}

class FlipCardWidget extends StatelessWidget {
  final Function(int index) onFlip;
  final FlipCardClass model;
  const FlipCardWidget({super.key, required this.model, required this.onFlip});
  flipCard(){
    model.controller.toggleCard();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FlipCard(
        controller: model.controller,
        fill: Fill
            .fillBack, // Fill the back side of the card to make in the same size as the front.
        direction: FlipDirection.HORIZONTAL,
        side: CardSide.FRONT,
        autoFlipDuration: const Duration(seconds: 1),
        front: InkWell(
          onTap: () {
            onFlip(model.index);
          
            model.controller.toggleCard();
          },
          child: SizedBox(
            height: 600,
            width: 200,
            child: DecoratedBox(
              decoration: BoxDecoration(color: model.color),
            ),
          ),
        ),
        back: InkWell(
          onTap: () {
            onFlip(model.index);
            model.controller.toggleCard();
          },
          child: const SizedBox(
            height: 600,
            width: 200,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
            ),
          ),
        ),
        speed: 500,
      ),
    );
  }
}

List<FlipCardClass> generateCard(List<ControllerModel> controllerList) {
  List<FlipCardClass> list = [];
  for (int i = 0; i < 4; i++) {
    var color =
        Color((Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);

    list.addAll([
      FlipCardClass(
          index: i,
          // color: Color.fromRGBO(r, g, b, opacity)
          color: color,
          controller: FlipCardController()),
      FlipCardClass(
          index: i,
          // color: Color.fromRGBO(r, g, b, opacity)
          color: color,
          controller: FlipCardController()),
    ]);
  }
  return list;
}

List<ControllerModel> generateListController() {
  List<ControllerModel> list = [];
  for (int i = 0; i < 8; i++) {
    list.add(ControllerModel(index: i, controller: FlipCardController()));
  }
  return list;
}

class ControllerModel {
  int index;
  FlipCardController controller;
  ControllerModel({
    required this.index,
    required this.controller,
  });
}

class FlipCardClass {
  int index;
  Color color;
  FlipCardController controller;
  FlipCardClass({
    required this.index,
    required this.color,
    required this.controller,
  });
}
