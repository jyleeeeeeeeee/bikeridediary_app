import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// "기록 시작 전 안내" 다이얼로그를 다시 보지 않기 저장/조회.
/// 사용자가 다이얼로그에서 "다시 보지 않기" 체크 후 확인하면 true로 저장한다.
class IntroDialogPreference {
  static const _key = 'banking_intro_dismissed';

  Future<bool> isDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  Future<void> setDismissed(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}

final introDialogPreferenceProvider = Provider<IntroDialogPreference>(
  (ref) => IntroDialogPreference(),
);
