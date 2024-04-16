import 'package:bloc/bloc.dart';

import 'package:test_project/tic_tac/bloc/index.dart';
/// Блок состояний и событий для игры "Крестики-нолики".
class TicTacBloc extends Bloc<TicTacEvent, TicTacState> {
  TicTacBloc(TicTacState initialState) : super(initialState) {
    bool turn = true; // Переменная, отвечающая за текущий ход игрока
    int indexCount = 0; // Счетчик заполненных ячеек
    List list = List.generate(9, (index) => "", growable: false); // Список ячеек игрового поля

    /// Обработчик события начала игры.
    on<StartTicTacEvent>((event, emit) async {
      emit(UnTicTacState()); // Изменение состояния на "Неактивное"
      await Future.delayed(const Duration(milliseconds: 350)); // Задержка для эффекта
      emit(InTicTacState(list, turn)); // Изменение состояния на "Активное" с передачей списка ячеек и текущего хода
    });

    /// Обработчик события хода игрока.
    on<PlayerTicTacEvent>(
      (event, emit) async {
        emit(UnTicTacState()); // Изменение состояния на "Неактивное"
        if (turn) {
          list[event.index] = "x"; // Установка символа "x" в выбранную ячейку
          indexCount++; // Увеличение счетчика заполненных ячеек
        } else {
          list[event.index] = "o"; // Установка символа "o" в выбранную ячейку
          indexCount++; // Увеличение счетчика заполненных ячеек
        }
        if (indexCount == 9) {
          emit(GameOverTicTacState("Ничья")); // Изменение состояния на "Игра окончена" с сообщением о ничьей
        } else if (checkWinner(list)) {
          if (turn) {
            emit(GameOverTicTacState("Выиграл 1 игрок")); // Изменение состояния на "Игра окончена" с сообщением о победе первого игрока
          } else {
            emit(GameOverTicTacState("Выиграл 2 игрок")); // Изменение состояния на "Игра окончена" с сообщением о победе второго игрока
          }
        } else {
          turn = changeTurn(turn); // Смена хода игрока
          emit(InTicTacState(list, turn)); // Изменение состояния на "Активное" с передачей списка ячеек и текущего хода
        }
      },
    );

    /// Обработчик события сброса игры.
    on<ResetTicTacEvent>((event, emit) {
      indexCount = 0; // Сброс счетчика заполненных ячеек
      list = List.generate(9, (index) => "", growable: false); // Сброс списка ячеек
      turn = true; // Установка хода первого игрока
      emit(InTicTacState(list, turn)); // Изменение состояния на "Активное" с передачей списка ячеек и текущего хода
    });
  }

  /// Проверяет, есть ли победитель в игре.
  ///
  /// Возвращает `true`, если есть победитель, и `false` в противном случае.
  bool checkWinner(List list) {
    // Проверка по горизонтали
    if (list[0] == list[1] && list[0] == list[2] && list[0] != "") {
      return true;
    }
    if (list[3] == list[4] && list[3] == list[5] && list[3] != "") {
      return true;
    }
    if (list[6] == list[7] && list[6] == list[8] && list[6] != "") {
      return true;
    }
    // Проверка по вертикали
    if (list[0] == list[3] && list[0] == list[6] && list[0] != "") {
      return true;
    }
    if (list[1] == list[4] && list[1] == list[7] && list[1] != "") {
      return true;
    }
    if (list[2] == list[5] && list[2] == list[8] && list[2] != "") {
      return true;
    }
    // Проверка по диагонали
    if (list[0] == list[4] && list[0] == list[8] && list[0] != "") {
      return true;
    }
    if (list[2] == list[4] && list[2] == list[6] && list[2] != "") {
      return true;
    }
    return false;
  }

  /// Меняет ход игрока.
  ///
  /// Принимает текущий ход игрока и возвращает новый ход.
  bool changeTurn(turn) {
    return !turn;
  }
}
