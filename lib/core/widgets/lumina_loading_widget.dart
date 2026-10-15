import 'package:flutter/material.dart';

/// Скелетон списка. Анимация отключается, если пользователь
/// включил «уменьшить движение».
class LuminaLoadingWidget extends StatefulWidget {
  const LuminaLoadingWidget({super.key});

  @override
  State<LuminaLoadingWidget> createState() => _LuminaLoadingWidgetState();
}

class _LuminaLoadingWidgetState extends State<LuminaLoadingWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _opacity = Tween<double>(begin: 0.4, end: 0.9).animate(_controller);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller
        ..stop()
        ..value = 1;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: FadeTransition(
        opacity: _opacity,
        child: ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          itemCount: 6,
          itemBuilder: (_, __) => const _SkeletonRow(),
        ),
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  static const _bone = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.all(Radius.circular(4)),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 72,
      decoration: const BoxDecoration(
        color: Color(0x0F000000),
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: const Row(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: CircleAvatar(backgroundColor: Colors.white, radius: 20),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                  width: 120,
                  height: 12,
                  child: DecoratedBox(decoration: _bone)),
              SizedBox(height: 8),
              SizedBox(
                  width: 80,
                  height: 10,
                  child: DecoratedBox(decoration: _bone)),
            ],
          ),
        ],
      ),
    );
  }
}
