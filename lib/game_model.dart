import 'dart:math';

import 'package:minesweeper_rendom/main.dart';

class GameModel {
  final Difficulty difficulty;
  // 게임의 모든 데이터를 이 클래스가 가집니다.
  final int inputNumber;
  late int gridWidth;
  late int gridHeight;
  late int totalCells;
  late List<int> numbers;
  late List<bool> revealedCells;
  late int bombsFoundCount;
  late int revealedCount;
  late double fontSize;

  // 생성자(Constructor)가 기존 _initializeGame의 역할을 합니다.
  GameModel({required this.inputNumber, required this.difficulty}) {
    // numberRange에 따라 격자 크기를 결정합니다.

    switch (difficulty) {
      case Difficulty.easy:
        if (inputNumber <= 106) {
          gridWidth = 14;
          gridHeight = 8;
        } else if (inputNumber <= 114) {
          gridWidth = 15;
          gridHeight = 8;
        } else if (inputNumber <= 122) {
          gridWidth = 16;
          gridHeight = 8;
        } else if (inputNumber <= 137) {
          gridWidth = 16;
          gridHeight = 9;
        } else if (inputNumber <= 145) {
          gridWidth = 17;
          gridHeight = 9;
        } else if (inputNumber <= 161) {
          gridWidth = 17;
          gridHeight = 10;
        } else if (inputNumber <= 171) {
          gridWidth = 18;
          gridHeight = 10;
        } else if (inputNumber <= 180) {
          gridWidth = 19;
          gridHeight = 10;
        } else if (inputNumber <= 199) {
          gridWidth = 19;
          gridHeight = 11;
        } else if (inputNumber <= 209) {
          gridWidth = 20;
          gridHeight = 11;
        } else if (inputNumber <= 219) {
          gridWidth = 21;
          gridHeight = 11;
        } else if (inputNumber <= 239) {
          gridWidth = 21;
          gridHeight = 12;
        } else if (inputNumber <= 251) {
          gridWidth = 22;
          gridHeight = 12;
        } else if (inputNumber <= 262) {
          gridWidth = 23;
          gridHeight = 12;
        } else if (inputNumber <= 284) {
          gridWidth = 23;
          gridHeight = 13;
        } else if (inputNumber <= 296) {
          gridWidth = 24;
          gridHeight = 13;
        } else if (inputNumber <= 319) {
          gridWidth = 24;
          gridHeight = 14;
        } else if (inputNumber <= 332) {
          gridWidth = 25;
          gridHeight = 14;
        } else if (inputNumber <= 346) {
          gridWidth = 26;
          gridHeight = 14;
        } else if (inputNumber <= 370) {
          gridWidth = 26;
          gridHeight = 15;
        } else if (inputNumber <= 385) {
          gridWidth = 27;
          gridHeight = 15;
        } else if (inputNumber <= 426) {
          gridWidth = 28;
          gridHeight = 16;
        } else if (inputNumber <= 441) {
          gridWidth = 29;
          gridHeight = 16;
        } else if (inputNumber <= 456) {
          gridWidth = 30;
          gridHeight = 16;
        } else if (inputNumber <= 484) {
          gridWidth = 30;
          gridHeight = 17;
        } else {
          gridWidth = 31;
          gridHeight = 17;
        }

      case Difficulty.medium:
        if (inputNumber <= 102) {
          gridWidth = 15;
          gridHeight = 8;
        } else if (inputNumber <= 109) {
          gridWidth = 16;
          gridHeight = 8;
        } else if (inputNumber <= 122) {
          gridWidth = 16;
          gridHeight = 9;
        } else if (inputNumber <= 130) {
          gridWidth = 17;
          gridHeight = 9;
        } else if (inputNumber <= 144) {
          gridWidth = 17;
          gridHeight = 10;
        } else if (inputNumber <= 153) {
          gridWidth = 18;
          gridHeight = 10;
        } else if (inputNumber <= 161) {
          gridWidth = 19;
          gridHeight = 10;
        } else if (inputNumber <= 178) {
          gridWidth = 19;
          gridHeight = 11;
        } else if (inputNumber <= 187) {
          gridWidth = 20;
          gridHeight = 11;
        } else if (inputNumber <= 196) {
          gridWidth = 21;
          gridHeight = 11;
        } else if (inputNumber <= 214) {
          gridWidth = 21;
          gridHeight = 12;
        } else if (inputNumber <= 224) {
          gridWidth = 22;
          gridHeight = 12;
        } else if (inputNumber <= 235) {
          gridWidth = 23;
          gridHeight = 12;
        } else if (inputNumber <= 254) {
          gridWidth = 23;
          gridHeight = 13;
        } else if (inputNumber <= 265) {
          gridWidth = 24;
          gridHeight = 13;
        } else if (inputNumber <= 286) {
          gridWidth = 24;
          gridHeight = 14;
        } else if (inputNumber <= 297) {
          gridWidth = 25;
          gridHeight = 14;
        } else if (inputNumber <= 309) {
          gridWidth = 26;
          gridHeight = 14;
        } else if (inputNumber <= 331) {
          gridWidth = 26;
          gridHeight = 15;
        } else if (inputNumber <= 344) {
          gridWidth = 27;
          gridHeight = 15;
        } else if (inputNumber <= 357) {
          gridWidth = 28;
          gridHeight = 15;
        } else if (inputNumber <= 381) {
          gridWidth = 28;
          gridHeight = 16;
        } else if (inputNumber <= 394) {
          gridWidth = 29;
          gridHeight = 16;
        } else if (inputNumber <= 408) {
          gridWidth = 30;
          gridHeight = 16;
        } else if (inputNumber <= 433) {
          gridWidth = 30;
          gridHeight = 17;
        } else if (inputNumber <= 448) {
          gridWidth = 31;
          gridHeight = 17;
        } else if (inputNumber <= 462) {
          gridWidth = 32;
          gridHeight = 17;
        } else if (inputNumber <= 490) {
          gridWidth = 32;
          gridHeight = 18;
        } else {
          gridWidth = 33;
          gridHeight = 18;
        }

      case Difficulty.hard:
        if (inputNumber <= 101) {
          gridWidth = 16;
          gridHeight = 9;
        } else if (inputNumber <= 107) {
          gridWidth = 17;
          gridHeight = 9;
        } else if (inputNumber <= 119) {
          gridWidth = 17;
          gridHeight = 10;
        } else if (inputNumber <= 126) {
          gridWidth = 18;
          gridHeight = 10;
        } else if (inputNumber <= 133) {
          gridWidth = 19;
          gridHeight = 10;
        } else if (inputNumber <= 146) {
          gridWidth = 19;
          gridHeight = 11;
        } else if (inputNumber <= 154) {
          gridWidth = 20;
          gridHeight = 11;
        } else if (inputNumber <= 162) {
          gridWidth = 21;
          gridHeight = 11;
        } else if (inputNumber <= 176) {
          gridWidth = 21;
          gridHeight = 12;
        } else if (inputNumber <= 185) {
          gridWidth = 22;
          gridHeight = 12;
        } else if (inputNumber <= 193) {
          gridWidth = 23;
          gridHeight = 12;
        } else if (inputNumber <= 209) {
          gridWidth = 23;
          gridHeight = 13;
        } else if (inputNumber <= 218) {
          gridWidth = 24;
          gridHeight = 13;
        } else if (inputNumber <= 235) {
          gridWidth = 24;
          gridHeight = 14;
        } else if (inputNumber <= 245) {
          gridWidth = 25;
          gridHeight = 14;
        } else if (inputNumber <= 255) {
          gridWidth = 26;
          gridHeight = 14;
        } else if (inputNumber <= 273) {
          gridWidth = 26;
          gridHeight = 15;
        } else if (inputNumber <= 283) {
          gridWidth = 27;
          gridHeight = 15;
        } else if (inputNumber <= 294) {
          gridWidth = 28;
          gridHeight = 15;
        } else if (inputNumber <= 314) {
          gridWidth = 28;
          gridHeight = 16;
        } else if (inputNumber <= 325) {
          gridWidth = 29;
          gridHeight = 16;
        } else if (inputNumber <= 336) {
          gridWidth = 30;
          gridHeight = 16;
        } else if (inputNumber <= 357) {
          gridWidth = 30;
          gridHeight = 17;
        } else if (inputNumber <= 369) {
          gridWidth = 31;
          gridHeight = 17;
        } else if (inputNumber <= 381) {
          gridWidth = 32;
          gridHeight = 17;
        } else if (inputNumber <= 403) {
          gridWidth = 32;
          gridHeight = 18;
        } else if (inputNumber <= 416) {
          gridWidth = 33;
          gridHeight = 18;
        } else if (inputNumber <= 439) {
          gridWidth = 33;
          gridHeight = 19;
        } else if (inputNumber <= 452) {
          gridWidth = 34;
          gridHeight = 19;
        } else if (inputNumber <= 465) {
          gridWidth = 35;
          gridHeight = 19;
        } else if (inputNumber <= 490) {
          gridWidth = 35;
          gridHeight = 20;
        } else {
          gridWidth = 36;
          gridHeight = 20;
        }
    }

    if (gridHeight <= 12) {
      fontSize = 24.0;
    } else if (gridHeight <= 15) {
      fontSize = 20.0;
    } else {
      fontSize = 16.0;
    }

    totalCells = gridWidth * gridHeight;

    // 셀 데이터를 생성합니다.
    final List<int> specialNumbers = List.generate(inputNumber, (i) => i + 1);
    final List<int> fillerNumbers = List.generate(
      totalCells - inputNumber,
      (_) => -1,
    );
    numbers = specialNumbers + fillerNumbers;
    numbers.shuffle(Random());

    // 나머지 상태 변수들을 초기화합니다.
    revealedCells = List.generate(totalCells, (_) => false);
    revealedCount = 0;
    bombsFoundCount = 0;
  }

  // 셀을 여는 로직
  void revealCell(int index) {
    if (!revealedCells[index]) {
      revealedCells[index] = true;
      if (numbers[index] == -1) {
        bombsFoundCount++;
      } else {
        revealedCount++;
      }
    }
  }

  void revealAllCells() {
    revealedCells = List.generate(totalCells, (_) => true);
  }

  // 찾은 숫자 목록을 반환하는 로직
  List<int> getFoundNumbers() {
    final List<int> foundNumbers = [];
    for (int i = 0; i < totalCells; i++) {
      if (revealedCells[i] && numbers[i] != -1) {
        foundNumbers.add(numbers[i]);
      }
    }
    foundNumbers.sort();
    return foundNumbers;
  }
}
