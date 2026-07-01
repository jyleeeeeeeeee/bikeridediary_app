import '../data/model/user_response.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final UserResponse? user;
  final String? errorMessage;

  /// 서버 통신 없이 로컬 flag로만 진입한 게스트 세션.
  /// 네트워크 없이 continueAsGuest 시도 시 세팅됨.
  /// 로컬 우선 도메인(뱅킹 등)만 정상 사용 가능. 서버 도메인은 UI에서 제한.
  final bool isLocalGuest;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.isLocalGuest = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserResponse? user,
    String? errorMessage,
    bool? isLocalGuest,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
      isLocalGuest: isLocalGuest ?? this.isLocalGuest,
    );
  }
}
