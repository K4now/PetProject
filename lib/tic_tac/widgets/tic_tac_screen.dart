import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_project/tic_tac/bloc/index.dart';
import 'package:test_project/tic_tac/widgets/game_place_tic_tac.dart';
import 'package:test_project/tic_tac/widgets/gamers_list.dart';

/// Экран игры "Крестики-нолики".
class TicTacScreen extends StatefulWidget {
  /// Конструктор экрана игры "Крестики-нолики".
  ///
  /// [ticTacBloc] - экземпляр класса TicTacBloc, отвечающий за логику игры.
  /// [key] - ключ виджета.
  const TicTacScreen({
    required TicTacBloc ticTacBloc,
    Key? key,
  })  : _ticTacBloc = ticTacBloc,
        super(key: key);

  final TicTacBloc _ticTacBloc;

  @override
  TicTacScreenState createState() {
    return TicTacScreenState();
  }
}

/// Состояние экрана игры "Крестики-нолики".
class TicTacScreenState extends State<TicTacScreen> {
  TicTacScreenState();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener(
      bloc: widget._ticTacBloc,
      listener: (BuildContext context, state) {
        if (state is GameOverTicTacState) {
          showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  content: Text(state.text),
                  actions: [
                    TextButton(
                      onPressed: () {
                        context.router.back();
                      },
                      child: Text("Выход"),
                    ),
                    TextButton(
                      onPressed: () {
                         context.maybePop();
                        widget._ticTacBloc.add(ResetTicTacEvent());
                        
                      },
                      child: Text("Начать заново"),
                    )
                  ],
                );
              });
        }
      },
      child: BlocBuilder<TicTacBloc, TicTacState>(
          bloc: widget._ticTacBloc,
          builder: (
            BuildContext context,
            TicTacState currentState,
          ) {
            if (currentState is UnTicTacState) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            if (currentState is ErrorTicTacState) {
              return Center(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(currentState.errorMessage),
                ],
              ));
            }
            if (currentState is InTicTacState) {
              return Column(children: [
                Expanded(
                  flex: 1,
                  child: GamersList(bloc: widget._ticTacBloc),
                ),
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0),
                    child: GamePlaceTicTac(
                      gamePlaceList: currentState.gamePlaceList,
                    ),
                  ),
                )
              ]);
            }

            return const Center(
              child: CircularProgressIndicator(),
            );
          }),
    );
  }

  /// Загрузка начального состояния игры.
  void _load() {
    widget._ticTacBloc.add(StartTicTacEvent());
  }
}
