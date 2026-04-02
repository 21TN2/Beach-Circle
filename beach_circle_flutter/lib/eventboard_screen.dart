// eventboard_screen.dart
// Entry point screen for Event Board — mirrors dormlife_screen.dart

import 'package:flutter/material.dart';
import 'package:beach_circle_flutter/community_goods/event_board/screens/eb_homepg.dart';

class EventBoardScreen extends StatelessWidget {
  const EventBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EBHomePage();
  }
}