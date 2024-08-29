import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import 'additional_info.dart';
import 'widgets/signup_widgets.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true; // 비밀번호(확인) 필드의 숨김 상태

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(''),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IdField(controller: _idController),
                SizedBox(height: 16.0),
                EmailField(controller: _emailController),
                SizedBox(height: 16.0),
                PasswordField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  toggleObscureText: _togglePasswordVisibility,
                ),
                SizedBox(height: 16.0),
                ConfirmPasswordField(
                  controller: _confirmPasswordController,
                  passwordController: _passwordController,
                  obscureText: _obscurePassword,
                  toggleObscureText: _togglePasswordVisibility,
                ),
                SizedBox(height: 16.0),
                SubmitButton(onPressed: () => _signupStep1(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signupStep1(BuildContext ctx) async {
    if (_formKey.currentState!.validate()) {
      print('_idController.text: ${_idController.text}');
      print('_emailController.text: ${_emailController.text}');
      print('_passwordController.text: ${_passwordController.text}');

      try {
        var response = await UserService.saveUser(
          userId: _idController.text,
          email: _emailController.text,
          password1: _passwordController.text,
          password2: _confirmPasswordController.text,
        );

        if (response.statusCode == 201) {
          var data = json.decode(response.body);

          Navigator.of(ctx).push(
            MaterialPageRoute(
              builder: (ctx) => AdditionalInfoPage(
                name: "test", // 실제 이름을 여기에 전달해야 함
                phoneNumber: "01000000000", // 실제 전화번호를 여기에 전달해야 함
                userId: data['data']['user_id'],
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text('회원가입에 실패했습니다. 다시 시도해 주세요.')),
          );
        }
      } catch (e) {
        print('Error: $e');
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다. 다시 시도해 주세요.')),
        );
      }
    }
  }
}
