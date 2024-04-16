import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_project/tic_tac/bloc/index.dart';
/// Страница игры "Крестики-нолики".
///
/// Этот виджет является главной страницей игры "Крестики-нолики". Он содержит
/// экземпляр [TicTacBloc], который управляет состоянием игры. Виджет также
/// содержит [TicTacScreen], который отображает игровое поле и обрабатывает
/// пользовательский ввод.
@RoutePage()
class TicTacPage extends StatelessWidget {
  final TicTacBloc _ticTacBloc = TicTacBloc(UnTicTacState());

  TicTacPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TicTacBloc>(
      create: (context) => _ticTacBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Крестики-нолики'),
        ),
        body: TicTacScreen(ticTacBloc: _ticTacBloc),
      ),
    );
  }
}
