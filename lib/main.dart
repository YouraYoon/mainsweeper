import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:minesweeper_rendom/explosion_dialog_content.dart';
import 'package:minesweeper_rendom/game_model.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:window_manager/window_manager.dart';

enum Difficulty { easy, medium, hard }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      await windowManager.ensureInitialized();

      await windowManager.setTitle("쿨타임 피크닉 2025");

      //const Size initialSize = Size(1600, 900);

      WindowOptions windowOptions = const WindowOptions(
        //size: initialSize,
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.normal,
      );

      windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();

        await windowManager.setFullScreen(true);
      });
    } else if (Platform.isAndroid || Platform.isIOS) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);

      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
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
  Difficulty _selectedDifficulty = Difficulty.easy;
  final Map<Difficulty, String> _difficultyLabels = {
    Difficulty.easy: '5~15%',
    Difficulty.medium: '15~25%',
    Difficulty.hard: '30~35%',
  };

  late GameModel _gameModel;

  String _appVersion = '';
  //이미지
  // final String _faceWinPath = 'assets/images/face_win.png';
  final String _faceLostPath = 'assets/images/face_lost.png';
  final String _facePlayPath = 'assets/images/face_play.png';
  late String _currentFacePath;
  // bool _gaveOver = false;

  int? _pressedCellIndex;
  bool _isFacePressed = false;
  double cellFontSize = 12.0;
  final int _minInputNumber = 100;
  final int _maxInputNumber = 500;

  //색상 데이터
  late List<Color> _colorPalette; // 255개의 고대비 색상 팔레트
  late List<Color?> _cellColors; // 각 셀에 지정된 색상 (null일 수 있음)

  bool _isGameInitialized = false;

  @override
  void initState() {
    super.initState();
    // initState는 위젯이 생성될 때 한 번만 호출됩니다.
    // 여기서 게임을 초기화합니다.
    _colorPalette = _generateHighContrastColors(255);
    _loadVersionInfo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      __startNewGameSequence();
    });
  }

  Future<void> _loadVersionInfo() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      // pubspec.yaml의 version: 1.0.2+3 에서 '1.0.2'는 version, '3'은 buildNumber 입니다.
      _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
    });
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

  Future<void> _handleGameOver(int index) async {
    // Dialog에 전달할, 이전에 찾은 숫자 목록을 미리 수집합니다.
    final List<int> foundNumbers = _gameModel.getFoundNumbers();

    // 1. 게임 종료 시퀀스를 시작합니다.
    setState(() {
      // 모델의 모든 셀을 '열림' 상태로 바꿉니다.
      _currentFacePath = _faceLostPath;
      _gameModel.revealAllCells();

      // 2. 모든 숫자 셀에 색상을 부여하여 보이게 만듭니다. (핵심 수정사항)
      for (int i = 0; i < _gameModel.totalCells; i++) {
        // 아직 색상이 없는 숫자 셀에만 색상을 할당합니다.
        if (_gameModel.numbers[i] != -1 && _cellColors[i] == null) {
          _cellColors[i] = _colorPalette[i % _colorPalette.length];
        }
      }
    });

    // 3. 사용자가 전체 판을 볼 수 있도록 잠시 기다립니다 (예: 2초).
    await Future.delayed(const Duration(seconds: 1));

    // 4. Dialog를 띄우고, 사용자의 다음 행동(게임 리셋)을 기다립니다.
    final bool? shouldReset = await _showCellContentDialog(index, foundNumbers);

    // 5. '다시 시작' 버튼을 누르면 게임을 초기화합니다.
    if (shouldReset == true) {
      _resetGame(_gameModel.inputNumber);
    }
  }

  // 게임을 초기 상태로 설정하는 함수
  void _initializeGame(int number) {
    setState(() {
      _isGameInitialized = true;
      _gameModel = GameModel(
        inputNumber: number,
        difficulty: _selectedDifficulty,
      );
      _currentFacePath = _facePlayPath;
      _cellColors = List.generate(_gameModel.totalCells, (_) => null);
      _colorPalette.shuffle(Random());
      _pressedCellIndex = null;
      _isFacePressed = false;
    });

    print(
      "width: ${_gameModel.gridWidth} heigth: ${_gameModel.gridHeight} cellCNT: ${_gameModel.totalCells} fontSize: ${_gameModel.fontSize}",
    );
  }

  // --- 셀 열기/게임 재시작 로직 수정 ---
  void _revealCell(int index) {
    setState(() {
      _gameModel.revealCell(index);

      if (_gameModel.numbers[index] != -1) {
        _cellColors[index] =
            _colorPalette[_gameModel.revealedCount % _colorPalette.length];
      }
    });
  }

  // 게임을 재시작하는 함수
  void _resetGame(int number) {
    _initializeGame(number);
  }

  Future<void> __startNewGameSequence() async {
    // 앱이 종료될 때까지 설정 루프를 반복합니다.
    while (mounted) {
      // 1단계: 난이도 선택
      final Difficulty? difficulty = await _showDifficultyDialog();
      if (difficulty == null) {
        // 사용자가 Dialog를 닫는 등 예외적인 경우,
        // 게임이 시작되지 않았다면 기본값으로 시작하고 루프 종료
        if (!_isGameInitialized) _resetGame(_gameModel.inputNumber);
        break;
      }
      _selectedDifficulty = difficulty; // 선택된 난이도 저장

      // 2단계: 숫자 입력
      while (mounted) {
        final int? number = await _showNumberInputDialog();
        if (number == null) {
          // '취소'를 눌렀으므로 난이도 선택으로 돌아감
          break; // 안쪽 루프를 탈출하여 바깥 루프 시작점으로
        } else {
          _resetGame(number);
        }

        // 3단계: 설정 확인
        final bool? confirmed = await _showConfirmationDialog(
          difficulty,
          number,
        );
        if (confirmed == true) {
          // '확인'을 눌렀으므로 게임을 시작하고 전체 시퀀스 종료
          return;
        }
        // '취소'를 누르면 현재 루프가 계속되어 숫자 입력창이 다시 뜸
      }
    }
  }

  Future<Difficulty?> _showDifficultyDialog() {
    return showDialog<Difficulty>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        Difficulty selected = _selectedDifficulty;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFB5B5B5),
              title: const Text('지뢰 비율 선택'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children:
                    Difficulty.values.map((difficulty) {
                      return RadioListTile<Difficulty>(
                        title: Text(_difficultyLabels[difficulty]!),
                        value: difficulty,
                        groupValue: selected,
                        onChanged: (Difficulty? value) {
                          setState(() {
                            selected = value!;
                          });
                        },
                      );
                    }).toList(),
              ),
              actions: [
                TextButton(
                  child: const Text(
                    '취소',
                    style: TextStyle(color: Colors.black),
                  ),
                  // '취소'는 null을 반환하며 닫기
                  onPressed: () => Navigator.of(context).pop(null),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(selected),
                  child: const Text(
                    '확인',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<int?> _showNumberInputDialog() async {
    final TextEditingController textFieldController = TextEditingController();

    return showDialog<int>(
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
            decoration: InputDecoration(
              hintText: "$_minInputNumber ~ $_maxInputNumber 사이 숫자",
            ),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('취소', style: TextStyle(color: Colors.black)),
              // '취소'는 null을 반환하며 닫기
              onPressed: () => Navigator.of(context).pop(null),
            ),
            TextButton(
              child: const Text('확인', style: TextStyle(color: Colors.black)),
              onPressed: () {
                final String inputText = textFieldController.text;
                if (inputText.isNotEmpty) {
                  final int? enteredNumber = int.tryParse(inputText);
                  if (enteredNumber != null &&
                      enteredNumber >= _minInputNumber &&
                      enteredNumber <= _maxInputNumber) {
                    // 입력된 숫자를 반환하며 닫기
                    Navigator.of(context).pop(enteredNumber);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '$_minInputNumber에서 $_maxInputNumber 사이의 숫자를 입력해주세요.',
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showConfirmationDialog(Difficulty difficulty, int number) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFB5B5B5),
          title: const Text('설정 확인'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('추첨 숫자: $number'),
              const SizedBox(height: 8),
              Text(
                '지뢰 비율: ${_gameModel.totalCells - number}(${(((_gameModel.totalCells - number) / _gameModel.totalCells) * 100).round()}%)',
              ),
              const SizedBox(height: 8),
              Text(
                '테이블 크기: ${_gameModel.gridWidth} x ${_gameModel.gridHeight} = ${_gameModel.totalCells}',
              ),
              const SizedBox(height: 8),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소', style: TextStyle(color: Colors.black)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('확인', style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showCellContentDialog(
    int index,
    List<int> revealedNumbers,
  ) async {
    final int number = _gameModel.numbers[index];
    Widget dialogContent;

    VoidCallback onOkPressed;

    if (number == -1) {
      dialogContent = ExplosionDialogContent(revealedNumbers: revealedNumbers);

      onOkPressed = () {
        Navigator.of(context).pop(true);
      };
    } else {
      final Color dialogColor =
          _colorPalette[_gameModel.revealedCount % _colorPalette.length];
      dialogContent = Text(
        '$number',
        style: TextStyle(
          fontSize: 150,
          fontWeight: FontWeight.bold,
          color: dialogColor,
        ),
      );

      onOkPressed = () {
        Navigator.of(context).pop(false);
      };
    }
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: number == -1 ? false : true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (
        BuildContext buildContext,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
      ) {
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
              onPressed: onOkPressed,
              child:
                  number == -1
                      ? Text(
                        '다시 시작',
                        style: TextStyle(color: Colors.black, fontSize: 20.0),
                      )
                      : Text(
                        '확인',
                        style: TextStyle(color: Colors.black, fontSize: 20.0),
                      ),
            ),
          ],
        );
      },
      transitionBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
        Widget child,
      ) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutQuint,
        );
        return FadeTransition(
          opacity: curvedAnimation,
          child: ScaleTransition(scale: curvedAnimation, child: child),
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
              children: [
                Text("Developed by BilguuneeSoft"),
                Text("bilguuneeSoft@gmail.com"),
                Text("Random Minesweeper ver $_appVersion"),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                '돌아가기',
                style: TextStyle(color: Colors.black, fontSize: 20.0),
              ),
            ),
            TextButton(
              onPressed: () {
                if (Platform.isWindows ||
                    Platform.isMacOS ||
                    Platform.isLinux) {
                  exit(0);
                }
              },
              child: const Text(
                '앱 종료',
                style: TextStyle(color: Colors.black, fontSize: 20.0),
              ),
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
    // 게임이 아직 초기화되지 않았다면, 로딩 화면을 보여줍니다.
    if (!_isGameInitialized) {
      return const Scaffold(
        backgroundColor: Color(0xFFB6B6B6),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    // 왼쪽 표시창: 남은 숫자 셀 개수
    // (전체 숫자 개수 - 찾은 숫자 개수)
    final remainingValuableCells =
        _gameModel.inputNumber - _gameModel.revealedCount;
    final remainingCellsString = remainingValuableCells.toString().padLeft(
      3,
      '0',
    );

    // 오른쪽 표시창: 남은 폭탄 개수
    // (전체 폭탄 개수 - 찾은 폭탄 개수)
    final totalBombs = _gameModel.totalCells - _gameModel.inputNumber;
    final remainingBombs = totalBombs - _gameModel.bombsFoundCount;
    final remainingBombString = remainingBombs.toString().padLeft(3, '0');
    // final int bombsProbability =
    //     ((totalBombs / _gameModel.totalCells) * 100).round();
    // final String bombsProbabilityString = bombsProbability.toString().padLeft(
    //   2,
    //   '0',
    // );

    return Scaffold(
      backgroundColor: Color(0xFFB6B6B6),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            // 사용 가능한 최대 너비와 높이
            final availableWidth = constraints.maxWidth;
            final availableHeight = constraints.maxHeight;

            // 상단 정보창의 예상 높이와 여백 등을 고려합니다.
            const double topBarApproxHeight = 100.0;
            const double verticalPadding = 10.0 * 2;

            // 순수하게 게임판이 사용할 수 있는 세로 공간
            final availableGridHeight =
                availableHeight - topBarApproxHeight - verticalPadding;

            // 셀 사이의 간격과 게임판 테두리 두께 등을 고려
            const double gridContainerPadding = 8.0 * 2;
            const double gridBorderWidth = 4.0 * 2;
            const double cellSpacing = 2.0;

            // 가로에 맞는 셀 최대 크기 계산
            final cellWidthMax =
                (availableWidth -
                    gridContainerPadding -
                    gridBorderWidth -
                    (cellSpacing * (_gameModel.gridWidth - 1))) /
                _gameModel.gridWidth;
            // 세로에 맞는 셀 최대 크기 계산
            final cellHeightMax =
                (availableGridHeight -
                    gridContainerPadding -
                    gridBorderWidth -
                    (cellSpacing * (_gameModel.gridHeight - 1))) /
                _gameModel.gridHeight;

            // 가로/세로 중 더 작은 값을 최종 셀 크기로 선택
            final double cellSize = min(cellWidthMax, cellHeightMax);

            // 계산된 셀 크기를 바탕으로 게임판 전체의 실제 너비를 계산
            final gridRenderWidth =
                (cellSize * _gameModel.gridWidth) +
                (cellSpacing * (_gameModel.gridWidth - 1)) +
                gridContainerPadding +
                gridBorderWidth;

            // 전체 UI를 화면 중앙에 배치하기 위해 Center 위젯 사용
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min, // 내용물 크기에 맞게 Column 크기 조절
                children: <Widget>[
                  // 1. 상단 정보창
                  Container(
                    width: gridRenderWidth, // 게임판과 동일한 너비를 적용
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB5B5B5),
                      border: const Border(
                        top: BorderSide(color: Color(0xFF6f6f6f), width: 4.0),
                        left: BorderSide(color: Color(0xFF6f6f6f), width: 4.0),
                        bottom: BorderSide(color: Colors.white, width: 4.0),
                        right: BorderSide(color: Colors.white, width: 4.0),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: <Widget>[
                            GestureDetector(
                              onTap: () {
                                __startNewGameSequence();
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
                                _resetGame(_gameModel.inputNumber);
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
                                  _currentFacePath,
                                  width: 36,
                                  height: 36,
                                ),
                              ),
                            ),

                            GestureDetector(
                              onTap: () {
                                _showDeveloperInfo();
                              },
                              child: _buildSegmentDisplay(
                                remainingBombString,
                                // "$bombsProbabilityString%",
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10), // 정보창과 게임판 사이 간격
                  // 2. 게임판
                  Container(
                    width: gridRenderWidth, // 게임판과 동일한 너비를 적용
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB5B5B5),
                      border: const Border(
                        top: BorderSide(color: Color(0xFF6f6f6f), width: 4.0),
                        left: BorderSide(color: Color(0xFF6f6f6f), width: 4.0),
                        bottom: BorderSide(color: Colors.white, width: 4.0),
                        right: BorderSide(color: Colors.white, width: 4.0),
                      ),
                    ),
                    child: GridView.builder(
                      shrinkWrap: true, // Column 안에서 스크롤 위젯을 사용하기 위해 필요
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _gameModel.totalCells,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _gameModel.gridWidth,
                        mainAxisSpacing: cellSpacing,
                        crossAxisSpacing: cellSpacing,
                        childAspectRatio: 1.0, // 셀은 항상 정사각형
                      ),
                      itemBuilder: (context, index) {
                        // 현재 셀이 열렸는지 여부
                        final bool isRevealed = _gameModel.revealedCells[index];
                        // 현재 셀에 할당된 숫자
                        final int number = _gameModel.numbers[index];

                        final bool isPressed = _pressedCellIndex == index;

                        final Border boxBorder;

                        if (isPressed && !isRevealed) {
                          boxBorder = const Border(
                            top: BorderSide(
                              color: Color(0xFF6f6f6f),
                              width: 4.0,
                            ),
                            left: BorderSide(
                              color: Color(0xFF6f6f6f),
                              width: 4.0,
                            ),
                            bottom: BorderSide(color: Colors.white, width: 4.0),
                            right: BorderSide(color: Colors.white, width: 4.0),
                          );
                        } else if (isRevealed) {
                          boxBorder = Border.all(
                            color: Color(0xFFb7b7b7),
                            width: 4.0,
                          );
                        } else {
                          boxBorder = Border(
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
                        }
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
                            // 이미 열린 셀은 아무 동작도 하지 않도록 맨 위에서 막습니다.
                            if (_gameModel.revealedCells[index]) return;

                            setState(() {
                              _pressedCellIndex = null;
                            });

                            // --- 실행 순서 로직을 명확하게 수정 ---
                            if (_gameModel.numbers[index] == -1) {
                              // 지뢰일 경우, 게임 오버 시퀀스를 시작합니다.
                              // 이전에 클릭했던 셀도 여기서 함께 열립니다.
                              _revealCell(index);
                              _handleGameOver(index);
                            } else {
                              // 일반 숫자일 경우, 셀을 즉시 열고 숫자 팝업을 띄웁니다.
                              _revealCell(index);
                              await _showCellContentDialog(index, []);
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
                                          fontSize: _gameModel.fontSize,
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
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
