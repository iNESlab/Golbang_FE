import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class UserService {
  static Future<http.Response> saveUser({
    required String userId,
    required String email,
    required String password1,
    required String password2
  }) async {

    var uri = Uri.parse("${dotenv.env['API_HOST']}/api/v1/users/signup/step-1/");
    Map<String, String> headers = {"Content-type": "application/json"};
    // body
    Map data = {
      'user_id': '$userId',
      'email': '$email',
      'password1': '$password1',
      'password2': '$password2',
    };
    var body = json.encode(data);
    var response = await http.post(uri, headers: headers, body: body);

    print("${json.decode(utf8.decode(response.bodyBytes))}");

    return response;
  }

  static Future<http.Response> saveAdditionalInfo({
    required int userId,
    required String name,
    String? phoneNumber,
    int? handicap,
    String? dateOfBirth,
    String? address,
    String? studentId
  })async{

    var uri = Uri.parse("${dotenv.env['API_HOST']}/api/v1/users/signup/step-2/");
    Map<String, String> headers = {"Content-type": "application/json"};
    // body
    Map data = {
      'user_id': '$userId',
      'name': '$name',
      'phone_number': '$phoneNumber',
      'handicap': '$handicap',
      'date_of_birth': '$dateOfBirth',
      'address': '$address',
      'student_id': '$studentId',
    };

    var body = json.encode(data);
    var response = await http.post(uri, headers: headers, body: body);

    print("${json.decode(utf8.decode(response.bodyBytes))}");

    return response;
  }
}