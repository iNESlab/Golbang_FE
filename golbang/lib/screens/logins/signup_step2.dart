import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignUpStep2 extends StatefulWidget {
  final int userId;
  const SignUpStep2({super.key, required this.userId});

  @override
  SignUpStep2State createState() => SignUpStep2State();
}

class SignUpStep2State extends State<SignUpStep2> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _handicapController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();
  final _educationController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _handicapController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _educationController.dispose();
    super.dispose();
  }

  Future<void> _signupStep2() async {
    final name = _nameController.text;
    final phoneNumber = _phoneController.text;
    final handicap = _handicapController.text;
    final dateOfBirth = _dobController.text;
    final address = _addressController.text;
    final studentId = _educationController.text;

    final url = Uri.parse('http://127.0.0.1:8000/api/user/signup/step-2/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': widget.userId,
        'name': name,
        'phone_number': phoneNumber,
        'handicap': handicap,
        'date_of_birth': dateOfBirth,
        'address': address,
        'student_id': studentId,
      }),
    );

    if (response.statusCode == 200) {
      Navigator.pushNamed(context, '/signupComplete');
    } else {
      final responseBody = jsonDecode(response.body);
      _showErrorDialog(responseBody.toString());
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('정보를 기입해주세요'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '이름',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '이름을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: '전화번호',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '전화번호를 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _handicapController,
                decoration: const InputDecoration(
                  labelText: '핸디캡',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '핸디캡 정보를 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _dobController,
                decoration: const InputDecoration(
                  labelText: '생일',
                ),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: '주소',
                ),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _educationController,
                decoration: const InputDecoration(
                  labelText: '학번',
                  helperText: '대학 동문회 모임을 위해 필요한 경우 입력 바랍니다',
                ),
              ),
              const SizedBox(height: 32.0),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _signupStep2();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(400, 50),
                ),
                child: const Text('가입하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
