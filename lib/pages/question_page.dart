import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_project/data/provider/clock_provider.dart';
import 'package:test_project/widgets/questin_stack.dart';

class QusetionPage extends StatefulWidget {
  const QusetionPage({super.key});

  @override
  State<QusetionPage> createState() => _QusetionPageState();
}

class _QusetionPageState extends State<QusetionPage> {
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
      ), title: Text("Очки: ${context.watch<ClockProvider>().count}"),),
      body:  SafeArea(child: QusestionScreen()),
    );
  }
}

class QusestionScreen extends StatelessWidget {

  const QusestionScreen({super.key, });

  @override
  Widget build(BuildContext context) {
    return  QusetionStack( );
  }
}
