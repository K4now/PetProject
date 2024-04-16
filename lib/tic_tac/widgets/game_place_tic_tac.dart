import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_project/tic_tac/bloc/tic_tac_bloc.dart';
import 'package:test_project/tic_tac/widgets/game_item_tic_tac.dart';

import 'package:flutter/material.dart';
/// Виджет, отображающий игровое поле для игры в крестики-нолики.
class GamePlaceTicTac extends StatefulWidget {
  final List gamePlaceList;

  /// Конструктор класса [GamePlaceTicTac].
  ///
  /// Принимает обязательный параметр [gamePlaceList], который представляет собой список элементов игрового поля.
  const GamePlaceTicTac({
    super.key,
    required this.gamePlaceList,
  });

  @override
  State<GamePlaceTicTac> createState() => _GamePlaceTicTacState();
}

class _GamePlaceTicTacState extends State<GamePlaceTicTac> {
  late TicTacBloc bloc;

  @override
  void initState() {
    /// Инициализирует [bloc] с помощью [BlocProvider] и получает экземпляр [TicTacBloc].
    bloc = BlocProvider.of<TicTacBloc>(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    /// Возвращает виджет [GridView], который отображает игровое поле.
    return GridView.builder(
      itemCount: widget.gamePlaceList.length,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
      itemBuilder: (context, index) {
        /// Возвращает виджет [GameItemTicTac], который представляет собой элемент игрового поля.
        return GameItemTicTac(
          bloc: bloc, index: index,
        );
      },
    );
  }
}
