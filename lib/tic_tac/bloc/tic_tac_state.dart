import 'package:equatable/equatable.dart';

abstract class TicTacState extends Equatable {
  TicTacState();

  @override
  List<Object> get props => [];
}

/// UnInitialized
class UnTicTacState extends TicTacState {
  UnTicTacState();

  @override
  String toString() => 'UnTicTacState';
}

/// Initialized
class InTicTacState extends TicTacState {
  InTicTacState(this.gamePlaceList, this.turn);

  final List gamePlaceList;
  final bool turn;

  @override
  String toString() => 'InTicTacState $gamePlaceList, $turn ';

  @override
  List<Object> get props => [gamePlaceList, turn];
}

class PlayerTicTacState extends TicTacState {}

class GameOverTicTacState extends TicTacState {
GameOverTicTacState(this.text);

  final String text;

  @override
  String toString() => 'ErrorTicTacState';

  @override
  List<Object> get props => [text];
}

class ErrorTicTacState extends TicTacState {
  ErrorTicTacState(this.errorMessage);

  final String errorMessage;

  @override
  String toString() => 'ErrorTicTacState';

  @override
  List<Object> get props => [errorMessage];
}
