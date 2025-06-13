import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '뽑기 뽑기',
      theme: ThemeData(
        primaryColor: Colors.grey,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: RandomMineSweeper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class RandomMineSweeper extends StatefulWidget {
  const RandomMineSweeper({super.key});

  @override
  State<RandomMineSweeper> createState() => _RandomMineSweeper();
}

class _RandomMineSweeper extends State<RandomMineSweeper> {
  //이미지

  final String _faceWinPath = 'assets/images/face_win.png';
  final String _faceLostPath = 'assets/images/face_lost.png';
  final String _facePlayPath = 'assets/images/face_play.png';

  // 격자 크기 설정
  final int gridWidth = 12;
  final int gridHeight = 25;
  late int totalCells;

  // 게임 데이터
  late List<int> _numbers; // 각 셀에 들어갈 숫자 목록 (1~300)
  late List<bool> _revealedCells; // 각 셀이 열렸는지 여부를 저장

  late List<int> _bombs; // 각 셀에 들어갈 숫자 목록 (1~300)
  late List<bool> _revealedBombs; // 각 셀이 열렸는지 여부를 저장

  //색상 데이터
  late List<Color> _colorPalette; // 255개의 고대비 색상 팔레트
  late List<Color?> _cellColors; // 각 셀에 지정된 색상 (null일 수 있음)
  late int _revealedCount; // 셀을 연 횟수 카운터

  @override
  void initState() {
    super.initState();
    // initState는 위젯이 생성될 때 한 번만 호출됩니다.
    // 여기서 게임을 초기화합니다.
    _colorPalette = _generateHighContrastColors(255);
    _initializeGame();
  }

  /// 255개의 시인성 좋은 색상 리스트를 생성하는 함수
  List<Color> _generateHighContrastColors(int count) {
    final List<Color> colors = [];
    final double step = 360.0 / count; // 360도 색상환을 count 만큼 나눕니다.

    for (int i = 0; i < count; i++) {
      final double hue = i * step;
      // HSL 색 공간을 사용: 채도(Saturation)와 명도(Lightness)를 고정하여
      // 선명하고 너무 어둡거나 밝지 않은 색상을 만듭니다.
      final color =
          HSLColor.fromAHSL(
            1.0, // A (Alpha, 불투명도): 1.0 = 불투명
            hue, // H (Hue, 색상): 0~360
            0.9, // S (Saturation, 채도): 0.0 ~ 1.0 (높을수록 선명)
            0.5, // L (Lightness, 명도): 0.0 ~ 1.0 (0.5가 가장 순수한 색)
          ).toColor();
      colors.add(color);
    }
    return colors;
  }

  // 게임을 초기 상태로 설정하는 함수
  void _initializeGame() {
    totalCells = gridWidth * gridHeight;

    // 1. 1부터 300까지의 숫자가 담긴 리스트를 생성합니다.
    _numbers = List.generate(totalCells, (index) => index + 1);

    // 2. 이 숫자 리스트를 무작위로 섞습니다.
    // 이렇게 하면 각 셀에 중복되지 않는 랜덤한 숫자가 할당됩니다.
    _numbers.shuffle(Random());

    // 3. 모든 셀을 '닫힘' 상태로 초기화합니다.
    _revealedCells = List.generate(totalCells, (_) => false);

    // 4. 셀 색상 리스트와 카운터를 초기화합니다.
    _cellColors = List.generate(totalCells, (_) => null);
    _revealedCount = 0;

    _colorPalette.shuffle(Random());
  }

  // 셀을 클릭했을 때 호출될 함수
  void _revealCell(int index) {
    // UI를 변경하기 위해 setState를 호출합니다.
    setState(() {
      if (!_revealedCells[index]) {
        _revealedCells[index] = true;

        // _revealedCount를 인덱스로 사용하여 팔레트에서 순서대로 색상을 가져옵니다.
        // 255개를 넘어가면 다시 처음부터 순환하도록 % 연산자를 사용합니다.
        _cellColors[index] =
            _colorPalette[_revealedCount % _colorPalette.length];

        // 카운터를 1 증가시킵니다.
        _revealedCount++;
      }
    });
  }

  // 게임을 재시작하는 함수
  void _resetGame() {
    setState(() {
      _initializeGame();
    });
  }

  // 7세그먼트 숫자 표시 위젯
  Widget _buildSegmentDisplay(String text) {
    return Container(
      padding: const EdgeInsets.all(2.0),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(4.0),
      ),
      width: 70,
      height: 50,
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontFamily:
                'sevenSegment', // 디지털 폰트 필요 (assets에 추가하거나 pubspec.yaml에 폰트 정보 추가해야 함)
            fontSize: 30,
            color: Colors.red,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final remainingCell = totalCells - _revealedCount;
    final remainingCellsString = remainingCell.toString().padLeft(3, '0');

    final remainingBomb = 0;
    final remainingBombString = remainingBomb.toString().padLeft(3, '0');

    return Scaffold(
      backgroundColor: Colors.grey,
      body: Column(
        children: <Widget>[
          Container(
            color: Colors.grey.shade400,
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                _buildSegmentDisplay(remainingCellsString),
                ElevatedButton(
                  onPressed: _resetGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade400,
                    padding: const EdgeInsets.all(8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        4.0,
                      ), // 필요에 따라 둥근 모서리 조절
                    ),
                    minimumSize: const Size(48, 48),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(0.0),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade500,
                          offset: const Offset(2, 2),
                          blurRadius: 2,
                          spreadRadius: 0,
                        ),

                        BoxShadow(
                          color: Colors.white,
                          offset: const Offset(-2, -2),
                          blurRadius: 2,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Image.asset(_facePlayPath, width: 36, height: 36),
                  ),
                ),
                _buildSegmentDisplay(remainingBombString),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              // GridView.builder를 사용해 격자를 효율적으로 만듭니다.
              child: GridView.builder(
                //스크롤 비활성화
                physics: const NeverScrollableScrollPhysics(),
                // 격자 항목의 총 개수
                itemCount: totalCells,
                // 격자의 레이아웃을 정의합니다.
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gridWidth, // 가로 방향의 셀 개수
                  mainAxisSpacing: 2.0, // 세로 간격
                  crossAxisSpacing: 2.0, // 가로 간격
                ),
                // 각 격자 항목(셀)을 만드는 방법을 정의합니다.
                itemBuilder: (context, index) {
                  // 현재 셀이 열렸는지 여부
                  final bool isRevealed = _revealedCells[index];
                  // 현재 셀에 할당된 숫자
                  final int number = _numbers[index];

                  // 클릭 이벤트를 감지하기 위해 GestureDetector를 사용합니다.
                  return GestureDetector(
                    onTap: () {
                      // 아직 열리지 않은 셀만 열 수 있습니다.
                      if (!isRevealed) {
                        _revealCell(index);
                      }
                    },
                    child: Container(
                      // 셀의 디자인을 정의합니다.
                      decoration: BoxDecoration(
                        color:
                            isRevealed
                                ? Colors.grey.shade300
                                : Colors.grey.shade400,
                        border: Border.all(
                          color: Colors.grey.shade500,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(0.5),
                        boxShadow: [
                          if (!isRevealed)
                            BoxShadow(
                              color: Colors.grey.shade500,
                              offset: const Offset(1, 1),
                              blurRadius: 0,
                              spreadRadius: 0,
                            ),

                          if (!isRevealed)
                            BoxShadow(
                              color: Colors.white,
                              offset: const Offset(-1, -1),
                              blurRadius: 0,
                              spreadRadius: 0,
                            ),
                        ],
                      ),
                      // 셀의 내용을 중앙에 배치합니다.
                      child: Center(
                        child: Text(
                          // 셀이 열렸으면 숫자를, 아니면 빈 문자열을 보여줍니다.
                          isRevealed ? '$number' : '',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _cellColors[index] ?? Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
