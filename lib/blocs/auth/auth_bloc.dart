import 'package:bloc/bloc.dart';
import 'package:zabytki_app/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(AuthInitial()) {
    on<AuthStarted>(_onStarted);
    on<AuthLoggedOut>(_onLoggedOut);
    on<AuthLoggedIn>(_onLoggedIn); // Dodaj obsługę zdarzenia logowania
  }

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    final User? user = _authRepository.currentUser;
    if (user != null) {
      print('AuthStarted: User is authenticated');
      emit(AuthAuthenticated(user: user));
    } else {
      print('AuthStarted: User is unauthenticated');
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoggedIn(AuthLoggedIn event, Emitter<AuthState> emit) async {
    emit(AuthAuthenticated(user: event.user));
  }

  Future<void> _onLoggedOut(AuthLoggedOut event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    print('AuthLoggedOut: Attempting to log out user');
    try {
      await _authRepository.signOut();
      print('AuthLoggedOut: User logged out');
      emit(AuthUnauthenticated());
    } catch (e) {
      print('AuthLoggedOut Error: $e');
      emit(AuthError(message: e.toString()));
    }
  }

  // Nie będziesz miał tych metod bez Firebase
  // Future<void> createUserDocument(String userId, {Map<String, dynamic>? additionalData}) async {
  //   // Implementacja komunikacji z Twoją bazą danych
  // }

  // Future<void> createEmptyBoard(String userId) async {
  //   // Implementacja komunikacji z Twoją bazą danych
  // }
}

// Dodaj nowe zdarzenie dla udanego logowania
class AuthLoggedIn extends AuthEvent {
  final User user;

  AuthLoggedIn({required this.user});

  @override
  List<Object?> get props => [user]; // Dodaj właściwości do porównania
}