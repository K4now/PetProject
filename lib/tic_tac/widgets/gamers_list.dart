import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_project/tic_tac/bloc/index.dart';
/// Виджет GamersList отображает список игроков в игре крестики-нолики.
/// 
/// Этот виджет является [StatelessWidget], что означает, что он не содержит
/// состояния и его внешний вид зависит только от переданных ему параметров.
class GamersList extends StatelessWidget {
  /// Конструктор GamersList принимает обязательный параметр [bloc], который
  /// является экземпляром класса TicTacBloc.
  const GamersList({
    super.key,
    required this.bloc,
  });

  /// Экземпляр класса TicTacBloc, который управляет состоянием игры крестики-нолики.
  final TicTacBloc bloc;

  @override
  Widget build(BuildContext context) {
    /// Возвращает виджет [BlocBuilder], который строит виджеты на основе состояния
    /// [TicTacState], полученного от [bloc].
    return BlocBuilder<TicTacBloc, TicTacState>(
        bloc: bloc,
        builder: (context, state) {
          if (state is InTicTacState) {
            /// Если текущее состояние является [InTicTacState], то отображается
            /// [Row] с двумя [Expanded] виджетами, содержащими текстовые виджеты
            /// с именами игроков.
            return Row(
              children: [
                Expanded(
                  child: Center(
                      child: Text("Игрок 1",
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(
                                color: state.turn
                                    ? Theme.of(context).colorScheme.error
                                    : Theme.of(context).colorScheme.secondary,
                              ))),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      "Игрок 2",
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: !state.turn
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context).colorScheme.secondary,
                          ),
                    ),
                  ),
                )
              ],
            );
          } else {
            /// Если текущее состояние не является [InTicTacState], то отображается
            /// [CircularProgressIndicator].
            return CircularProgressIndicator();
          }
        });
  }
}
