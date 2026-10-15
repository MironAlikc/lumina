import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lumina/core/constants/app_tabs.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/widgets/lumina_nav_bar_widget.dart';

class MainShellScreen extends StatelessWidget {
  const MainShellScreen({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final index = shell.currentIndex;

    // «Назад» на других вкладках возвращает на дашборд, а не закрывает приложение.
    return PopScope(
      canPop: index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) shell.goBranch(0);
      },
      child: Scaffold(
        backgroundColor: LuminaColors.background,
        // Панель не должна «прыгать» над клавиатурой.
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            Positioned.fill(child: shell),
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.paddingOf(context).bottom + 14,
              child: Align(
                heightFactor: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: LuminaNavBarWidget(
                      activeTab: AppTab.values[index],
                      onTabSelected: (tab) => shell.goBranch(
                        tab.index,
                        // Повторное нажатие возвращает вкладку к её корню.
                        initialLocation: tab.index == index,
                      ),
                      onAddPressed: () => context.push('/add-transaction'),
                    ),
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
