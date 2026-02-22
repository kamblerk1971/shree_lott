class UserModel {
  final String username;
  final String password;
  final String? token;

  UserModel({
    required this.username,
    required this.password,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      username: json['username'] ?? '',
      password: '',
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
    };
  }
}
