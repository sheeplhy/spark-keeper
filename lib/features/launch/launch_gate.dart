import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../ui/core/spark_logo.dart';

class LaunchGate extends StatefulWidget {
  const LaunchGate({required this.child, super.key});

  final Widget child;

  @override
  State<LaunchGate> createState() => _LaunchGateState();
}

class _LaunchGateState extends State<LaunchGate> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1100), () {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      child: _ready ? widget.child : const LaunchScreen(),
    );
  }
}

class LaunchScreen extends StatelessWidget {
  const LaunchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF061826), Color(0xFF082A35)],
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, 0.2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SparkLogo(size: 92),
                const SizedBox(height: 24),
                Text(
                  '火花管家',
                  style: Theme.of(context).textTheme.headlineLarge
                      ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 2),
                ),
                const SizedBox(height: 10),
                const Text(
                  '让每一次互动都有温度',
                  style: TextStyle(color: AppColors.muted, letterSpacing: 1),
                ),
                const SizedBox(height: 64),
                const Text(
                  '轻量好友管理助手',
                  style: TextStyle(color: AppColors.text, fontSize: 13),
                ),
                const SizedBox(height: 8),
                const Text(
                  '安全 · 便捷 · 智能 · 省心',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 150,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.transparent, Color(0xAA19D6A5)],
                ),
                borderRadius: BorderRadius.vertical(
                  top: Radius.elliptical(260, 70),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
