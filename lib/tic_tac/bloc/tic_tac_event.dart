import 'package:meta/meta.dart';

@immutable
abstract class TicTacEvent {}

class UnTicTacEvent extends TicTacEvent {}

class StartTicTacEvent extends TicTacEvent {}

class ResetTicTacEvent extends TicTacEvent {}

class PlayerTicTacEvent extends TicTacEvent {
  PlayerTicTacEvent( this.turn, this.index);
  
  final bool turn;
  final int index;
}

class SecondPlayerTicTacEvent extends TicTacEvent {}