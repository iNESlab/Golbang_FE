import 'package:flutter/material.dart';
import 'signup_complete.dart'; // 회원가입 완료 페이지 import

class AdditionalInfoPage extends StatefulWidget {
  final String name;
  final String phoneNumber;

  const AdditionalInfoPage({Key? key, required this.name, required this.phoneNumber}) : super(key: key);

  @override
  _AdditionalInfoPageState createState() => _AdditionalInfoPageState();
}

class _AdditionalInfoPageState extends State<AdditionalInfoPage> {
  final _formKey = GlobalKey<FormState>();
  // TextEditingController에 초기값 설정
  final _nicknameController = TextEditingController(text: '닉네임 예시');
  final _handicapController = TextEditingController(text: '28'); // 예시 핸디캡
  final _birthdayController = TextEditingController(text: '1990-01-01'); // 예시 생일
  final _addressController = TextEditingController(text: '서울시 강남구'); // 예시 주소
  final _studentIdController = TextEditingController(text: '12345678'); // 예시 학번

  String? _selectedGender = '남자'; // 성별 초기값 설정

  @override
  void dispose() {
    _nicknameController.dispose();
    _handicapController.dispose();
    _birthdayController.dispose();
    _addressController.dispose();
    _studentIdController.dispose();
    super.dispose();
  }

  void _signUp() {
    if (_formKey.currentState!.validate()) {
      // 회원가입 로직 (예: 서버 API 호출)
      // 회원가입 성공 시 SignUpPage로 이동
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SignupComplete(),
        ),
      );
    }
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
          child: SingleChildScrollView( // 스크롤 가능하도록 SingleChildScrollView 추가
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTextFormField('닉네임', _nicknameController, TextInputType.text),
                const SizedBox(height: 16),
                _buildDropdownButtonFormField('성별', <String>['남자', '여자']),
                const SizedBox(height: 16),
                _buildTextFormField('전화번호', _handicapController, TextInputType.number),
                const SizedBox(height: 16),
                _buildTextFormField('핸디캡', _handicapController, TextInputType.number),
                const SizedBox(height: 16),
                _buildTextFormField('생일', _birthdayController, TextInputType.datetime),
                const SizedBox(height: 16),
                _buildTextFormField('주소', _addressController, TextInputType.streetAddress),
                const SizedBox(height: 16),
                _buildTextFormField('학번', _studentIdController, TextInputType.text),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _signUp,
                  child: const Text('가입하기'),
                ),
                const SizedBox(height: 16),
                const Text(
                  '대학 동문 학교 인증을 위해 필요한 경우만 입력바랍니다.',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField(String label, TextEditingController controller, TextInputType keyboardType) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$label을(를) 입력해주세요';
        }
        return null;
      },
    );
  }

  Widget _buildDropdownButtonFormField(String label, List<String> items) {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      onChanged: (String? newValue) {
        setState(() {
          _selectedGender = newValue;
        });
      },
      items: items.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$label을(를) 선택해주세요';
        }
        return null;
      },
    );
  }
}
