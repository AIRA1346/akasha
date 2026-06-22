import 'package:flutter/material.dart';

class HomeDashboardWelcomeHeader extends StatelessWidget {
  const HomeDashboardWelcomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '안녕하세요, 탐험가님!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 6),
            Image.network(
              'https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Emojis/main/Emojis/Hand%20Gestures/Waving%20Hand.png',
              width: 26,
              height: 26,
              errorBuilder: (_, _, _) =>
                  const Text('👋', style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '오늘도 지식의 우주를 탐험해볼까요?',
          style: TextStyle(fontSize: 13, color: Colors.grey[500]),
        ),
      ],
    );
  }
}
