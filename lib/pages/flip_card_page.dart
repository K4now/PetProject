import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_project/data/provider/clock_provider.dart';
import 'package:test_project/widgets/flup_card_widget.dart';
import 'package:test_project/widgets/questin_stack.dart';

class FLipCardPage extends StatefulWidget {
  const FLipCardPage({super.key});

  @override
  State<FLipCardPage> createState() => _FLipCardPageState();
}

class _FLipCardPageState extends State<FLipCardPage> {
  int count = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text("Очки: ${context.watch<ClockProvider>().count}"),
      ),
      body: SafeArea(child: FlipCardScreen()),
    );
  }
}

