import 'package:collection/collection.dart';
import 'package:dart_result_type/dart_result_type.dart';

enum Player {
  one,
  two;

  Player swap() {
    return switch (this) {
      one => two,
      two => one,
    };
  }

  @override
  String toString() {
    return switch (this) { one => 'Player One', two => 'Player Two' };
  }
}

enum GameError {
  outOfBounds,
  invalidCoordinate,
  occupied;

  @override
  String toString() {
    return switch (this) {
      outOfBounds => 'Coordinates are out of bounds!',
      invalidCoordinate => 'Coordinates are invalid!',
      occupied => 'Coordinates are occupied by another player!'
    };
  }
}

final class Coordinate {
  Coordinate._(
    this.x,
    this.y, {
    required this.size,
    required this.placedBy,
  });

  static Result<Coordinate, GameError> create(
    int x,
    int y, {
    required int size,
    required Player? placedBy,
  }) {
    final isOutOfBounds = _outOfBoundsPredicate(x, y, size);
    if (isOutOfBounds) return Err(GameError.outOfBounds);

    return Ok(Coordinate._(x, y, size: size, placedBy: placedBy));
  }

  static Result<Coordinate, GameError> parse(
    String? input, {
    required int size,
    required Player placedBy,
  }) {
    if (input == null) return Err(GameError.invalidCoordinate);

    final splitted = input.replaceAll(' ', '').split(',');
    if (splitted case [final String x, final String y]) {
      final parsedX = int.tryParse(x);
      final parsedY = int.tryParse(y);

      if (parsedX == null || parsedY == null) {
        return Err(GameError.invalidCoordinate);
      }

      return Coordinate.create(
        parsedX,
        parsedY,
        size: size,
        placedBy: placedBy,
      );
    } else {
      return Err(GameError.invalidCoordinate);
    }
  }

  final int x;
  final int y;
  final int size;
  final Player? placedBy;

  bool get isOccupied => placedBy != null;

  static bool _outOfBoundsPredicate(int x, int y, int size) {
    return (x > size - 1 || x < 0);
  }

  Result<Coordinate, GameError> copyWith({
    int? x,
    int? y,
    Player? placedBy,
  }) {
    final isOutOfBounds = _outOfBoundsPredicate(x ?? this.x, y ?? this.y, size);
    if (isOutOfBounds) return Err(GameError.outOfBounds);
    if (isOccupied) return Err(GameError.occupied);

    return Ok(
      Coordinate._(
        x ?? this.x,
        y ?? this.y,
        size: size,
        placedBy: placedBy ?? this.placedBy,
      ),
    );
  }
}

final class Canvas {
  Canvas(
    this.size, {
    required GameState gameState,
  }) : _gameState = gameState;

  Canvas.empty(
    this.size, {
    required Player startingPlayer,
  }) : _gameState = GameState(
          _buildEmptyCanvas(size),
          currentPlayer: startingPlayer,
        );

  final int size;

  GameState _gameState;
  GameState get gameState => _gameState;

  static List<List<Coordinate>> _buildEmptyCanvas(int size) {
    return List.generate(
      size,
      (y) => List.generate(
        size,
        (x) => Coordinate.create(x, y, size: size, placedBy: null).unwrap(),
      ),
    );
  }

  void updateState(GameState state) {
    _gameState = state;
  }

  void render() {
    final size = gameState.coordinates.length;
    final game = List.generate(size, (_) => List.generate(size, (_) => '-'));
    final occupiedCoords = gameState.coordinates
        .map((element) => element.where((element) => element.isOccupied))
        .flattened;

    for (final coord in occupiedCoords) {
      final placedBy = coord.placedBy;
      if (placedBy == null) continue;

      game[coord.y][coord.x] = switch (placedBy) {
        Player.one => 'X',
        Player.two => 'O',
      };
    }

    for (final row in game) {
      print(row.join('  '));
    }
  }
}

extension on Iterable<Coordinate> {
  bool didWin(Player player) {
    return every((element) => element.placedBy == player);
  }

  Player? getWinningPlayer() {
    if (didWin(Player.one)) return Player.one;
    if (didWin(Player.two)) return Player.two;
    return null;
  }
}

final class GameState {
  GameState(
    this.coordinates, {
    required Player currentPlayer,
  }) : _currentPlayer = currentPlayer;

  final List<List<Coordinate>> coordinates;
  Player _currentPlayer;
  Player get currentPlayer => _currentPlayer;

  GameError? updateCoordinates(Coordinate coords) {
    final current = coordinates[coords.y][coords.x];
    final result =
        current.copyWith(x: coords.x, y: coords.y, placedBy: currentPlayer);

    switch (result) {
      case Ok(value: final coords):
        coordinates[coords.y][coords.x] = coords;
        _currentPlayer = currentPlayer.swap();
        return null;
      case Err(value: final error):
        return error;
    }
  }

  Player? checkWin() {
    // Scan top to bottom
    for (final row in coordinates) {
      final winningPlayer = row.getWinningPlayer();
      if (winningPlayer != null) return winningPlayer;
    }

    final length = coordinates.length;

    // Scan left to right. Safe to use length here since the game should be
    // perfectly square (i.e. same number of rows and columns)
    for (var x = 0; x < length; x++) {
      final column = Iterable.generate(length, (y) => coordinates[y][x]);
      final winningPlayer = column.getWinningPlayer();
      if (winningPlayer != null) return winningPlayer;
    }

    // Scan diagonals
    var diag = Iterable.generate(length, (i) => coordinates[i][i]);
    var winningPlayer = diag.getWinningPlayer();
    if (winningPlayer != null) return winningPlayer;

    diag = Iterable.generate(length, (i) => coordinates[length - i - 1][i]);
    winningPlayer = diag.getWinningPlayer();
    if (winningPlayer != null) return winningPlayer;

    return null;
  }
}
