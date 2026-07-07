import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/lumina_localizations.dart';
import '../../../../presentation/cubits/language/language_cubit.dart';
import '../../../history/presentation/cubits/history_cubit.dart';
import '../../../history/presentation/cubits/history_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = LuminaLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          loc.translate('settingsTitle') ?? 'Настройки',
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocBuilder<HistoryCubit, HistoryState>(
        builder: (context, state) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Блок пользователя
                _buildProfileCard(loc),
                const SizedBox(height: 32),

                Text(
                  loc.translate('budgetManagement') ?? 'Управление бюджетом',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Карточка лимита
                _buildBudgetSlider(context, state, loc),
                const SizedBox(height: 32),

                Text(
                  loc.translate('appSection') ?? 'Приложение',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                _buildSettingsTile(
                  icon: Icons.language_rounded,
                  iconColor: const Color(0xFF8B5CF6),
                  title:
                      loc.translate('interfaceLanguage') ?? 'Язык интерфейса',
                  trailing: Text(
                    loc.translate('currentLanguageLabel') ?? 'RU',
                    style: const TextStyle(color: Colors.black38, fontSize: 14),
                  ),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.read<LanguageCubit>().toggleLanguage();
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(LuminaLocalizations loc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.1),
            child: const Text('👋', style: TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.translate('myWallet') ?? 'Мой кошелек',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                loc.translate('localProfile') ?? 'Локальный профиль',
                style: const TextStyle(color: Colors.black38),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetSlider(
    BuildContext context,
    HistoryState state,
    LuminaLocalizations loc,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(loc.translate('monthlyLimit') ?? 'Месячный лимит'),
              Text(
                '${state.budgetLimit.toStringAsFixed(0)} ₴',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
          Slider(
            value: state.budgetLimit.clamp(5000, 100000),
            min: 5000,
            max: 100000,
            divisions: 19,
            activeColor: const Color(0xFF3B82F6),
            onChanged: (value) {
              HapticFeedback.selectionClick();
              context.read<HistoryCubit>().updateBudgetLimit(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}
