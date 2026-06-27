import 'package:flutter/material.dart';

import '../../../../theme/akasha_spacing.dart';
import '../../../../theme/akasha_typography.dart';

class HomeDashboardWelcomeHeader extends StatelessWidget {
  const HomeDashboardWelcomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '안녕하세요, 탐험가님!',
              style: AkashaTypography.dashboardHero,
            ),
            SizedBox(width: AkashaSpacing.xs + 2),
            Image.network(
              'https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Emojis/main/Emojis/Hand%20Gestures/Waving%20Hand.png',
              width: 26,
              height: 26,
              errorBuilder: (_, _, _) =>
                  Text('👋', style: AkashaTypography.dashboardHero.copyWith(fontSize: 20)),
            ),
          ],
        ),
        SizedBox(height: AkashaSpacing.xs),
        Text(
          '오늘도 지식의 우주를 탐험해볼까요?',
          style: AkashaTypography.dashboardLead,
        ),
      ],
    );
  }
}
