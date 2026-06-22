import 'package:flutter_riverpod/flutter_riverpod.dart';

/// API 요청 중 로딩 오버레이 표시를 위한 글로벌 카운터.
/// 동시에 여러 요청이 있을 수 있으므로 int 카운터 사용.
final loadingCountProvider = StateProvider<int>((ref) => 0);

final isLoadingProvider = Provider<bool>((ref) {
  return ref.watch(loadingCountProvider) > 0;
});
