import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static Future<http.Response> login ({
    required String username,
    required String password,
    required String fcm_token
})async{
    var uri = Uri.parse("${dotenv.env['API_HOST']}/api/v1/users/login/");
    Map<String, String> headers = {"Content-type": "application/json"};
    // body
    Map data = {
      'username': '$username',
      'password': '$password',
      'fcm_token': '$fcm_token'
    };
    var body = json.encode(data);
    var response = await http.post(uri, headers: headers, body: body);
    print("${json.decode(utf8.decode(response.bodyBytes))}");

    return response;
  }
}