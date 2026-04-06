class UserModel {
  final String id;
  final String email;
  final String? name;
  final String createdAt;

  UserModel({
    required this.id,
    required this.email,
    this.name,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'created_at': createdAt,
    };
  }
}

class AuthState {
  final UserModel? user;
  final String? token;
  final bool isLoading;
  final String? error;

  AuthState({
    this.user,
    this.token,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null && token != null;

  AuthState copyWith({
    UserModel? user,
    String? token,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  AuthState clearError() {
    return AuthState(
      user: user,
      token: token,
      isLoading: isLoading,
      error: null,
    );
  }

  AuthState loading() {
    return AuthState(
      user: user,
      token: token,
      isLoading: true,
      error: null,
    );
  }

  AuthState authenticated(UserModel user, String token) {
    return AuthState(
      user: user,
      token: token,
      isLoading: false,
      error: null,
    );
  }

  AuthState unauthenticated() {
    return AuthState(
      user: null,
      token: null,
      isLoading: false,
      error: null,
    );
  }

  AuthState withError(String error) {
    return AuthState(
      user: user,
      token: token,
      isLoading: false,
      error: error,
    );
  }
}
