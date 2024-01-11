import 'dart:io';
import 'dart:math';

import 'package:dart_result_type/dart_result_type.dart';
import 'package:dart_tic_tac_toe/dart_tic_tac_toe.dart';

void printHelp() {
  print(['Coordinates can be entered in the format of x, y', '\n'].join());
}

void main(List<String> arguments) {
  const size = 3;

  print(['Welcome to Dart Tic-Tac-Toe!', '\n'].join());
  printHelp();

  final startingPlayer = Random().nextBool() ? Player.one : Player.two;
  final canvas = Canvas.empty(size, startingPlayer: startingPlayer);
  canvas.render();

  while (true) {
    final currentPlayer = canvas.gameState.currentPlayer;
    print('$currentPlayer, enter your coordinates: ');
    final input = stdin.readLineSync();
    print('');
    final result = Coordinate.parse(input, size: size, placedBy: currentPlayer);

    switch (result) {
      case Ok(value: final coords):
        final state = canvas.gameState;
        final error = state.updateCoordinates(coords);
        if (error != null) {
          print(result);
          continue;
        }

        canvas
          ..updateState(state)
          ..render();

        final wonBy = state.checkWin();
        if (wonBy != null) {
          print('Game is won by: $wonBy');
          return;
        }
      case Err(value: final error):
        print(error);
    }
  }
}
