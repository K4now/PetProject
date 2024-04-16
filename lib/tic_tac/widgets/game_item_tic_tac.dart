import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_project/tic_tac/bloc/tic_tac_bloc.dart';
import 'package:test_project/tic_tac/bloc/tic_tac_event.dart';
import 'package:test_project/tic_tac/bloc/tic_tac_state.dart';

/// Виджет, представляющий отдельный элемент игры в крестики-нолики.
class GameItemTicTac extends StatefulWidget {
  /// Конструктор класса GameItemTicTac.
  ///
  /// [bloc] - экземпляр класса TicTacBloc, отвечающий за логику игры.
  /// [index] - индекс элемента игры.
  const GameItemTicTac({
    super.key,
    required this.bloc,
    required this.index,
  });

  /// Экземпляр класса TicTacBloc, отвечающий за логику игры.
  final TicTacBloc bloc;

  /// Индекс элемента игры.
  final int index;

  @override
  State<GameItemTicTac> createState() => _GameItemTicTacState();
}

class _GameItemTicTacState extends State<GameItemTicTac> {
  late IconData? icon;
  late TicTacBloc _bloc;

  @override
  void initState() {
    icon = null;
    _bloc = widget.bloc;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TicTacBloc, TicTacState>(
      bloc: _bloc,
      builder: (context, state) {
        return InkWell(
          child: Card(
            child: icon == null ? const SizedBox() : Icon(icon),
          ),
          onTap: () {
            onTap(state);
          },
        );
      },
    );
  }

  /// Обработчик нажатия на игровой элемент в игре "Крестики-нолики".
  ///
  /// При нажатии на элемент игры, если текущее состояние игры [state] является [InTicTacState]
  /// и иконка [icon] равна `null`, то добавляется событие [PlayerTicTacEvent] в блок [TicTacBloc].
  /// Иконка [icon] устанавливается в зависимости от текущего хода [state.turn]:
  /// - Если ходит игрок 1, то иконка устанавливается в [Icons.close].
  /// - Если ходит игрок 2, то иконка устанавливается в [Icons.circle_outlined].
  ///
  /// Параметры:
  /// - [state]: Текущее состояние игры.
  /// - [icon]: Текущая иконка элемента игры.
  /// - [widget.index]: Индекс элемента игры.
  ///

  onTap(state) {
    if (state is InTicTacState && icon == null) {
      _bloc.add(PlayerTicTacEvent(state.turn, widget.index));
      icon = state.turn ? Icons.close : Icons.circle_outlined;
    }
  }
}
