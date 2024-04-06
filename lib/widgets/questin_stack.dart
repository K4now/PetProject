// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_analog_clock/flutter_analog_clock.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:test_project/data/provider/clock_provider.dart';

import 'package:test_project/pages/question_page.dart';
import 'package:vibration/vibration.dart';

class QusetionStack extends StatefulWidget {
  const QusetionStack({
    super.key,
  });

  @override
  State<QusetionStack> createState() => _QusetionStackState();
}

class _QusetionStackState extends State<QusetionStack>
    with TickerProviderStateMixin {
  @override
  void initState() {
    randomClock = Random().nextInt(4);
    listCount = _generateList();
    model = listCount[randomClock];
    controller = AnimationController(vsync: this);
    super.initState();
  }

  bool error = false;
  late AnimationController controller;

  late List listCount;
  late int randomClock;
  late ModelClock model;

  @override
  Widget build(BuildContext context) {
    ClockProvider clockProvider =
        Provider.of<ClockProvider>(context, listen: true);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: GridView.builder(
              primary: false,
              padding: const EdgeInsets.all(20),
              itemBuilder: (BuildContext context, int index) {
                return QuestionContainer(
                  model: listCount[index],
                  onTap: (int index) async {
                    if (index == randomClock) {
                      clockProvider.increment();

                      if (clockProvider.count > 10) {
                        showDialog(
                            context: context,
                            builder: (context) {
                              return DialogCount(
                                clockProvider: clockProvider,
                                onPressed: () {
                                  clockProvider.reset();
                                  Navigator.pop(context);
                                },
                                text: "Начать заново",
                                titileText: 'Вы умеете пользоваться часами!',
                              );
                            });
                      } else {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute<void>(
                              builder: (BuildContext context) =>
                                  const QusetionPage()),
                          ModalRoute.withName('/'),
                        );
                      }
                    } else {
                      if (clockProvider.count > -10) {
                        clockProvider.decrement();
                        setState(() {
                          error = true;
                        });
                      } else {
                        showDialog(
                            context: context,
                            builder: (context) {
                              return DialogCount(clockProvider: clockProvider, onPressed: () {  

                                clockProvider.reset();
                                Navigator.pop(context);
                              },text: "Начать заново", titileText: 'Превышен лимит',);
                            });
                      }
                      HapticFeedback.vibrate();
                    }
                  },
                );
              },
              itemCount: listCount.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2),
            )),
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            "Выберите часы на которых\n${model.hour} часов, ${model.minute} минут, ${model.second} секунд",
            style: const TextStyle(fontSize: 25),
            textAlign: TextAlign.center,
          )
              .animate(
                  controller: controller,
                  target: error ? 1 : 0,
                  onComplete: (val) {
                    setState(
                      () {
                        error = false;
                      },
                    );
                  })
              .shake(),
        )
      ],
    );
  }
}

class DialogCount extends StatelessWidget {
  final Function() onPressed;
  final String text;
  final String titileText;
  final ClockProvider clockProvider;
  const DialogCount({
    super.key, required this.clockProvider, required this.onPressed, required this.text, required this.titileText,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: SizedBox(
        height: MediaQuery.of(context).size.height * 0.3,
        child: Center(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Spacer(),
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    titileText,
                    style: TextStyle(fontSize: 25),
                  ),
                ),
                Spacer(),
                Row(
                  children: [
                    TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                          clockProvider.reset();
                          
                        },
                        child: Text("Выйти",style: TextStyle(fontSize: 20),), ),
                        Spacer(),
                         TextButton(
                      onPressed: () {
                       onPressed();
                      },
                      child: Text(text, style: TextStyle(fontSize: 20)),
                    )
                  ],
                )
              ]),
        ),
      ),
    );
  }
}

_generateList() {
  List list = [];

  for (int i = 0; i < 4; i++) {
    list.add(ModelClock(
        index: i,
        hour: Random().nextInt(12) + 1,
        minute: Random().nextInt(59) + 1,
        second: Random().nextInt(59) + 1));
  }

  // list.add(ModelClock(
  //     index: 0,
  //     hour: Random().nextInt(12) + 1,
  //     minute: Random().nextInt(60) + 1,
  //     second: Random().nextInt(60) + 1));

  // list.add(ModelClock(
  //     index: 1,
  //     hour: Random().nextInt(12) + 1,
  //     minute: Random().nextInt(60) + 1,
  //     second: Random().nextInt(60) + 1));
  // list.add(ModelClock(
  //     index: 2,
  //     hour: Random().nextInt(12) + 1,
  //     minute: Random().nextInt(60) + 1,
  //     second: Random().nextInt(60) + 1));
  // list.add(ModelClock(
  //     index: 3,
  //     hour: Random().nextInt(12) + 1,
  //     minute: Random().nextInt(60) + 1,
  //     second: Random().nextInt(60) + 1));

  return list;
}

class ModelClock {
  int index;
  int minute;
  int second;
  int hour;
  ModelClock({
    required this.index,
    required this.minute,
    required this.second,
    required this.hour,
  });

  ModelClock copyWith({
    int? index,
    int? minute,
    int? second,
    int? hour,
  }) {
    return ModelClock(
      index: index ?? this.index,
      minute: minute ?? this.minute,
      second: second ?? this.second,
      hour: hour ?? this.hour,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'index': index,
      'minute': minute,
      'second': second,
      'hour': hour,
    };
  }

  factory ModelClock.fromMap(Map<String, dynamic> map) {
    return ModelClock(
      index: map['index'] as int,
      minute: map['minute'] as int,
      second: map['second'] as int,
      hour: map['hour'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory ModelClock.fromJson(String source) =>
      ModelClock.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'ModelClock(index: $index, minute: $minute, second: $second, hour: $hour)';
  }

  @override
  bool operator ==(covariant ModelClock other) {
    if (identical(this, other)) return true;

    return other.index == index &&
        other.minute == minute &&
        other.second == second &&
        other.hour == hour;
  }

  @override
  int get hashCode {
    return index.hashCode ^ minute.hashCode ^ second.hashCode ^ hour.hashCode;
  }
}

class QuestionContainer extends StatelessWidget {
  final Function(int) onTap;
  final ModelClock model;
  const QuestionContainer(
      {super.key, required this.model, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: GestureDetector(
        onTap: () {
          onTap(model.index);
        },
        child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            width: MediaQuery.of(context).size.width * 0.3,
            child: AnalogClock(
              dateTime: DateTime(
                  2022, 10, 24, model.hour, model.minute, model.second),
              isKeepTime: false,
            )),
      ),
    );
  }
}
