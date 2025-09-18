import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/persistence_service.dart';
import '../core/models/mosaic.dart';

/// Provider for persistence service
final persistenceServiceProvider = Provider<PersistenceService>((ref) {
  final service = PersistenceService();
  // Service needs to be initialized before use
  return service;
});

/// Provider to initialize persistence service
final persistenceInitProvider = FutureProvider<void>((ref) async {
  final service = ref.watch(persistenceServiceProvider);
  await service.init();
});

/// Provider for user authentication state
final authStateProvider = StateProvider<AuthState>((ref) {
  // Watch for persistence initialization
  ref.watch(persistenceInitProvider);

  final service = ref.watch(persistenceServiceProvider);

  try {
    if (service.isAuthenticated) {
      return AuthState(
        isAuthenticated: true,
        userId: service.userId,
        username: service.username,
        email: service.email,
        authToken: service.authToken,
      );
    }
  } catch (e) {
    // Service not initialized yet
  }

  return const AuthState();
});

/// Provider for user preferences
final userPreferencesProvider =
    StateNotifierProvider<UserPreferencesNotifier, UserPreferences>((ref) {
      return UserPreferencesNotifier(ref);
    });

/// Provider for cached mosaics
final cachedMosaicsProvider = Provider<List<Mosaic>?>((ref) {
  // Watch for persistence initialization
  final initAsync = ref.watch(persistenceInitProvider);

  return initAsync.whenOrNull(
    data: (_) {
      final service = ref.watch(persistenceServiceProvider);
      return service.getCachedMosaics();
    },
  );
});

/// Provider for favorite mosaics
final favoriteMosaicsProvider = StateProvider<List<String>>((ref) {
  // Watch for persistence initialization
  final initAsync = ref.watch(persistenceInitProvider);

  return initAsync.whenOrNull(
        data: (_) {
          final service = ref.watch(persistenceServiceProvider);
          return service.favoriteMosaics;
        },
      ) ??
      [];
});

/// Auth state model
class AuthState {
  final bool isAuthenticated;
  final String? userId;
  final String? username;
  final String? email;
  final String? authToken;

  const AuthState({
    this.isAuthenticated = false,
    this.userId,
    this.username,
    this.email,
    this.authToken,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? userId,
    String? username,
    String? email,
    String? authToken,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      email: email ?? this.email,
      authToken: authToken ?? this.authToken,
    );
  }
}

/// User preferences model
class UserPreferences {
  final String themeMode;
  final bool notificationsEnabled;
  final String viewMode;
  final int? selectedTeam;

  const UserPreferences({
    this.themeMode = 'system',
    this.notificationsEnabled = true,
    this.viewMode = 'grid',
    this.selectedTeam,
  });

  UserPreferences copyWith({
    String? themeMode,
    bool? notificationsEnabled,
    String? viewMode,
    int? selectedTeam,
  }) {
    return UserPreferences(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      viewMode: viewMode ?? this.viewMode,
      selectedTeam: selectedTeam ?? this.selectedTeam,
    );
  }
}

/// Notifier for user preferences
class UserPreferencesNotifier extends StateNotifier<UserPreferences> {
  final Ref ref;

  UserPreferencesNotifier(this.ref) : super(const UserPreferences()) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    // Wait for persistence to be initialized
    await ref.read(persistenceInitProvider.future);
    final service = ref.read(persistenceServiceProvider);

    state = UserPreferences(
      themeMode: service.themeMode,
      notificationsEnabled: service.notificationsEnabled,
      viewMode: service.viewMode,
      selectedTeam: service.selectedTeam,
    );
  }

  void setThemeMode(String mode) {
    final service = ref.read(persistenceServiceProvider);
    service.themeMode = mode;
    state = state.copyWith(themeMode: mode);
  }

  void setNotifications(bool enabled) {
    final service = ref.read(persistenceServiceProvider);
    service.notificationsEnabled = enabled;
    state = state.copyWith(notificationsEnabled: enabled);
  }

  void setViewMode(String mode) {
    final service = ref.read(persistenceServiceProvider);
    service.viewMode = mode;
    state = state.copyWith(viewMode: mode);
  }

  void setSelectedTeam(int? team) {
    final service = ref.read(persistenceServiceProvider);
    service.selectedTeam = team;
    state = state.copyWith(selectedTeam: team);
  }
}

/// Actions for authentication
class AuthActions {
  final Ref ref;

  AuthActions(this.ref);

  Future<void> login(
    String userId,
    String username,
    String email,
    String token,
  ) async {
    await ref.read(persistenceInitProvider.future);
    final service = ref.read(persistenceServiceProvider);

    service.userId = userId;
    service.username = username;
    service.email = email;
    service.authToken = token;

    ref.read(authStateProvider.notifier).state = AuthState(
      isAuthenticated: true,
      userId: userId,
      username: username,
      email: email,
      authToken: token,
    );
  }

  Future<void> logout() async {
    await ref.read(persistenceInitProvider.future);
    final service = ref.read(persistenceServiceProvider);

    await service.clearUserData();

    ref.read(authStateProvider.notifier).state = const AuthState();
  }
}

/// Provider for auth actions
final authActionsProvider = Provider<AuthActions>((ref) {
  return AuthActions(ref);
});
