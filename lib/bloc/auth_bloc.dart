import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

// --- Events ---
abstract class AuthEvent {}

class CheckAuthStatus extends AuthEvent {}

class SignInWithGoogleRequested extends AuthEvent {}

class SignOutRequested extends AuthEvent {}

// --- States ---
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final User user;
  Authenticated(this.user);
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

// --- BLoC ---
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;
  late final StreamSubscription<User?> _authSubscription;

  AuthBloc(this._authService) : super(AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<SignInWithGoogleRequested>(_onSignInWithGoogleRequested);
    on<SignOutRequested>(_onSignOutRequested);

    // Listen to authentication state changes directly from Firebase
    _authSubscription = _authService.userChanges.listen((user) {
      add(CheckAuthStatus());
    });
  }

  Future<void> _onCheckAuthStatus(CheckAuthStatus event, Emitter<AuthState> emit) async {
    final user = _authService.currentUser;
    if (user != null) {
      emit(Authenticated(user));
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> _onSignInWithGoogleRequested(
    SignInWithGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final credential = await _authService.signInWithGoogle();
      if (credential == null) {
        // User cancelled, return to unauthenticated status
        emit(Unauthenticated());
      } else {
        // Firebase auth state changes listener will handle the Authenticated state emission
      }
    } catch (e) {
      emit(AuthError('登入失敗，請稍後再試 ($e)'));
      emit(Unauthenticated());
    }
  }

  Future<void> _onSignOutRequested(SignOutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authService.signOut();
    } catch (e) {
      emit(AuthError('登出失敗 ($e)'));
      // Fallback
      emit(Authenticated(_authService.currentUser!));
    }
  }

  @override
  Future<void> close() {
    _authSubscription.cancel();
    return super.close();
  }
}
