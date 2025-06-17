import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();

    await windowManager.setTitle("쿨타임 피크닉 2025");

    WindowOptions windowOptions = const WindowOptions(
      size: Size(900, 1020),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '쿨타임 피크닉 2025',
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
  late int gridWidth;
  late int gridHeight;
  late int totalCells;
  int? _pressedCellIndex;
  bool _isFacePressed = false;
  double cellFontSize = 12.0;
  double mineSize = 10;

  // 게임 데이터
  int _numberRange = 300;
  late List<int> _numbers; // 각 셀에 들어갈 숫자 목록 (1~300)
  late List<bool> _revealedCells; // 각 셀이 열렸는지 여부를 저장
  late int _bombsFoundCount; // 찾은 폭탄(-1)의 개수

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
    _initializeGame(_numberRange);
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
  void _initializeGame(int numberRange) {
    _numberRange = numberRange;

    int gridSize;
    if (numberRange <= 64) {
      gridSize = 9;
      cellFontSize = 20;
    } else if (numberRange <= 115) {
      gridSize = 12;
      cellFontSize = 18;
    } else if (numberRange <= 231) {
      gridSize = 17;
      cellFontSize = 16;
    } else if (numberRange <= 352) {
      gridSize = 21;
      cellFontSize = 12;
    } else {
      gridSize = 24;
      cellFontSize = 10;
    }
    gridWidth = gridSize;
    gridHeight = gridSize;
    totalCells = gridWidth * gridHeight;

    // 3. 셀 데이터 생성 (가장 큰 변경점)
    // 1부터 입력된 숫자(numberRange)까지의 리스트 생성
    final List<int> specialNumbers = List.generate(numberRange, (i) => i + 1);
    // 나머지 공간을 -1로 채울 리스트 생성
    final List<int> fillerNumbers = List.generate(
      totalCells - numberRange,
      (_) => -1,
    );

    // 두 리스트를 합친 후 무작위로 섞어서 _numbers에 할당
    _numbers = specialNumbers + fillerNumbers;
    _numbers.shuffle(Random());

    // 4. 나머지 상태 변수들 초기화 (새로운 totalCells 기준)
    _revealedCells = List.generate(totalCells, (_) => false);
    _cellColors = List.generate(totalCells, (_) => null);
    _revealedCount = 0;
    _colorPalette.shuffle(Random());
    _pressedCellIndex = null;
    _isFacePressed = false;

    _bombsFoundCount = 0;
  }

  // --- 셀 열기/게임 재시작 로직 수정 ---
  void _revealCell(int index) {
    setState(() {
      if (!_revealedCells[index]) {
        _revealedCells[index] = true;

        // 게임 로직 노트: 만약 클릭한 셀이 -1이면 게임오버 처리를 할 수 있습니다.
        if (_numbers[index] == -1) {
          _bombsFoundCount++;
          print("폭탄(-1)을 클릭했습니다!!");
          // 여기에 게임오버 UI 변경 로직 추가 가능 (예: 모든 폭탄 표시)
        } else {
          _cellColors[index] =
              _colorPalette[_revealedCount % _colorPalette.length];
          _revealedCount++;
        }
      }
    });
  }

  // 게임을 재시작하는 함수
  void _resetGame(int numberRange) {
    setState(() {
      _initializeGame(numberRange);
    });
  }

  Future<void> _showCellContentDialog(int index) async {
    final int number = _numbers[index];
    Widget dialogContent;

    if (number == -1) {
      dialogContent = Image.asset(
        'assets/images/mine.png',
        width: 150,
        height: 150,
      );
    } else {
      final Color dialogColor =
          _colorPalette[_revealedCount % _colorPalette.length];
      dialogContent = Text(
        '$number',
        style: TextStyle(
          fontSize: 150,
          fontWeight: FontWeight.bold,
          color: dialogColor,
        ),
      );
    }
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFB5B5B5),
          content: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [dialogContent],
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                '확인',
                style: TextStyle(color: Colors.black, fontSize: 20.0),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeveloperInfo() {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFB5B5B5),
          content: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [Text("Developed by BilguuneeSoft")],
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                '확인',
                style: TextStyle(color: Colors.black, fontSize: 20.0),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- Dialog 로직 수정 ---
  Future<void> _showNumberInputDialog() async {
    final TextEditingController textFieldController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFB5B5B5),
          title: const Text('숫자 범위 입력'),
          content: TextField(
            controller: textFieldController,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: const InputDecoration(hintText: "50 ~ 500 사이 숫자"),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('확인', style: TextStyle(color: Colors.black)),
              onPressed: () {
                final String inputText = textFieldController.text;
                if (inputText.isNotEmpty) {
                  final int? enteredNumber = int.tryParse(inputText);
                  // 유효성 검사: 50 ~ 500 사이인지 확인
                  if (enteredNumber != null &&
                      enteredNumber >= 50 &&
                      enteredNumber <= 500) {
                    Navigator.of(context).pop(); // 먼저 Dialog를 닫고
                    _resetGame(enteredNumber); // 새로운 숫자로 게임을 리셋
                  } else {
                    // 유효하지 않은 범위일 경우 사용자에게 알림 (SnackBar)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('50에서 500 사이의 숫자를 입력해주세요.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
            ),
            TextButton(
              child: const Text('취소', style: TextStyle(color: Colors.black)),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
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
    // 왼쪽 표시창: 남은 숫자 셀 개수
    // (전체 숫자 개수 - 찾은 숫자 개수)
    final remainingValuableCells = _numberRange - _revealedCount;
    final remainingCellsString = remainingValuableCells.toString().padLeft(
      3,
      '0',
    );

    // 오른쪽 표시창: 남은 폭탄 개수
    // (전체 폭탄 개수 - 찾은 폭탄 개수)
    final totalBombs = totalCells - _numberRange;
    final remainingBombs = totalBombs - _bombsFoundCount;
    final remainingBombString = remainingBombs.toString().padLeft(3, '0');

    return Scaffold(
      backgroundColor: Color(0xFFB6B6B6),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Color(0xFFB5B5B5),

                  border: const Border(
                    top: BorderSide(color: Color(0xFF6f6f6f), width: 4.0),
                    left: BorderSide(color: Color(0xFF6f6f6f), width: 4.0),
                    bottom: BorderSide(color: Color(0xFFFFFFFF), width: 4.0),
                    right: BorderSide(color: Color(0xFFFFFFFF), width: 4.0),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        GestureDetector(
                          onTap: () {
                            _showNumberInputDialog();
                          },
                          child: _buildSegmentDisplay(remainingCellsString),
                        ),

                        GestureDetector(
                          onTapDown: (_) {
                            setState(() {
                              _isFacePressed = true;
                            });
                          },
                          onTapUp: (_) {
                            setState(() {
                              _isFacePressed = false;
                            });
                            _resetGame(_numberRange);
                          },
                          onTapCancel: () {
                            setState(() {
                              _isFacePressed = false;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(0.0),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              border:
                                  _isFacePressed
                                      ? Border(
                                        top: BorderSide(
                                          color: Color(0xFF6f6f6f),
                                          width: 4.0,
                                        ),
                                        left: BorderSide(
                                          color: Color(0xFF6f6f6f),
                                          width: 4.0,
                                        ),
                                        bottom: BorderSide(
                                          color: Color(0xFFFFFFFF),
                                          width: 4.0,
                                        ),
                                        right: BorderSide(
                                          color: Color(0xFFFFFFFF),
                                          width: 4.0,
                                        ),
                                      )
                                      : const Border(
                                        bottom: BorderSide(
                                          color: Color(0xFF6f6f6f),
                                          width: 4.0,
                                        ),
                                        right: BorderSide(
                                          color: Color(0xFF6f6f6f),
                                          width: 4.0,
                                        ),
                                        top: BorderSide(
                                          color: Color(0xFFFFFFFF),
                                          width: 4.0,
                                        ),
                                        left: BorderSide(
                                          color: Color(0xFFFFFFFF),
                                          width: 4.0,
                                        ),
                                      ),
                            ),
                            child: Image.asset(
                              _facePlayPath,
                              width: 36,
                              height: 36,
                            ),
                          ),
                        ),

                        GestureDetector(
                          onTap: () {
                            _showDeveloperInfo();
                          },
                          child: _buildSegmentDisplay(remainingBombString),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Color(0xFFB5B5B5),

                    border: const Border(
                      top: BorderSide(color: Color(0xFF6f6f6f), width: 4.0),
                      left: BorderSide(color: Color(0xFF6f6f6f), width: 4.0),
                      bottom: BorderSide(color: Color(0xFFFFFFFF), width: 4.0),
                      right: BorderSide(color: Color(0xFFFFFFFF), width: 4.0),
                    ),
                  ),
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

                      final bool inPressed = _pressedCellIndex == index;

                      final Border boxBorder =
                          isRevealed
                              ? Border.all(color: Color(0xFFb7b7b7), width: 4.0)
                              : Border(
                                bottom: BorderSide(
                                  color: Color(0xFF6f6f6f),
                                  width: 4.0,
                                ),
                                right: BorderSide(
                                  color: Color(0xFF6f6f6f),
                                  width: 4.0,
                                ),
                                top: BorderSide(
                                  color: Color(0xFFFFFFFF),
                                  width: 4.0,
                                ),
                                left: BorderSide(
                                  color: Color(0xFFFFFFFF),
                                  width: 4.0,
                                ),
                              );
                      final String displayText =
                          isRevealed ? (number == -1 ? 'B' : '$number') : '';
                      // 클릭 이벤트를 감지하기 위해 GestureDetector를 사용합니다.
                      return GestureDetector(
                        onTapDown: (details) {
                          if (!isRevealed) {
                            setState(() {
                              _pressedCellIndex = index;
                            });
                          }
                        },
                        onTapUp: (details) async {
                          if (!isRevealed) {
                            setState(() {
                              _pressedCellIndex = null;
                            });
                            await _showCellContentDialog(index);
                            _revealCell(index);
                          }
                        },
                        onTapCancel: () {
                          if (!isRevealed) {
                            setState(() {
                              _pressedCellIndex = null;
                            });
                          }
                        },
                        child: Container(
                          // 셀의 디자인을 정의합니다.
                          decoration: BoxDecoration(
                            color:
                                isRevealed
                                    ? Color(0xFFb7b7b7)
                                    : Color(0xFFb8b8b8),
                            border: boxBorder,
                          ),
                          // 셀의 내용을 중앙에 배치합니다.
                          child: Center(
                            child:
                                isRevealed && number == -1
                                    ? Image.asset(
                                      'assets/images/mine.png',
                                      width: 40,
                                      height: 40,
                                    )
                                    : Text(
                                      // 셀이 열렸으면 숫자를, 아니면 빈 문자열을 보여줍니다.
                                      displayText,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: cellFontSize,
                                        color:
                                            number == -1
                                                ? Colors.black
                                                : (_cellColors[index] ??
                                                    Colors.transparent),
                                      ),
                                    ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
