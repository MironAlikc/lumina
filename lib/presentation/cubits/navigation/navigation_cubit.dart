// --- Класс управления вкладками навигации ---
import 'package:flutter_bloc/flutter_bloc.dart';

enum AppTab { history, analytics, settings }

class NavigationCubit extends Cubit<AppTab> {
  NavigationCubit() : super(AppTab.history);
  void selectTab(AppTab tab) => emit(tab);
}
