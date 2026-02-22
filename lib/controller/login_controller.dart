import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../consts/constants.dart';
import '../models/auth_user_model.dart';

class LoginController {
  Future<UserModel?> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.loginEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "username": username,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserModel.fromJson(data);
      } else {
        debugPrint("Login failed: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("Login exception: $e");
      return null;
    }
  }
}
