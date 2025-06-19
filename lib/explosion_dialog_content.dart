import 'package:flutter/material.dart';

class ExplosionDialogContent extends StatefulWidget {
  // 찾은 숫자 목록을 전달받기 위한 변수
  final List<int> revealedNumbers;

  const ExplosionDialogContent({
    super.key,
    required this.revealedNumbers, // 생성자를 통해 숫자 목록을 받도록 함
  });

  @override
  State<ExplosionDialogContent> createState() => _ExplosionDialogContentState();
}

class _ExplosionDialogContentState extends State<ExplosionDialogContent> {
  // 애니메이션 재생 여부를 기억하는 상태 변수
  bool _isExploding = true;

  @override
  void initState() {
    super.initState();
    // 1.5초 후에 _isExploding 상태를 false로 변경합니다.
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isExploding = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 애니메이션과 숫자 목록을 함께 표시하는 UI
    final int foundCount = widget.revealedNumbers.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. 애니메이션/이미지 표시 부분
        Image.asset(
          _isExploding
              ? 'assets/images/explosion02.gif' // true이면 폭발 애니메이션 GIF
              : 'assets/images/mine.png', // false이면 일반 지뢰 이미지
          width: 150,
          height: 150,
          gaplessPlayback: true, // 이미지가 바뀔 때 깜빡임 없이 부드럽게 전환
        ),
        const SizedBox(height: 16),

        // 2. 숫자 목록 표시 부분
        if (widget.revealedNumbers.isNotEmpty) ...[
          Text(
            '$foundCount개 당첨',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 300, // 목록 영역의 너비
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300.0),
              child: Container(
                padding: const EdgeInsets.all(8.0),
                // decoration: BoxDecoration(
                //   border: Border.all(color: Colors.grey.shade700),
                //   borderRadius: BorderRadius.circular(4.0),
                // ),
                child: SingleChildScrollView(
                  child: Center(
                    child: Wrap(
                      spacing: 6.0,
                      runSpacing: 4.0,
                      // 생성자를 통해 전달받은 widget.revealedNumbers를 사용
                      children:
                          widget.revealedNumbers
                              .map(
                                (num) => Chip(
                                  label: Text('$num'),
                                  backgroundColor: Colors.white70,
                                ),
                              )
                              .toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
