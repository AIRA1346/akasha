import 'package:flutter/material.dart';

/// `HomeShellController`가 Presentation 콜백에 접근하는 호스트.
abstract class HomeShellHost {
  BuildContext get context;
  bool get mounted;
  void scheduleRebuild([void Function()? mutate]);
}
