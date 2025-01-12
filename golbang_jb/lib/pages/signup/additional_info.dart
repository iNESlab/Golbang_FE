import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:golbang/services/user_service.dart';
import 'signup_complete.dart'; // 회원가입 완료 페이지 import

class AdditionalInfoPage extends StatefulWidget {
  final String name;
  final String phoneNumber;
  final int userId;

  const AdditionalInfoPage({
    super.key,
    required this.name,
    required this.phoneNumber,
    required this.userId,
  });

  @override
  _AdditionalInfoPageState createState() => _AdditionalInfoPageState();
}

class _AdditionalInfoPageState extends State<AdditionalInfoPage> {
  final _formKey = GlobalKey<FormState>();

  final _nicknameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _handicapController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _addressController = TextEditingController();
  final _studentIdController = TextEditingController();

  String? _selectedGender;

  @override
  void dispose() {
    _nicknameController.dispose();
    _phoneNumberController.dispose();
    _handicapController.dispose();
    _birthdayController.dispose();
    _addressController.dispose();
    _studentIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(''),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '추가 정보를 기입해주세요',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                '모든 * 필드는 필수 입력 항목입니다.',
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),
              const SizedBox(height: 16),
              _buildRequiredTextFormField(
                '닉네임',
                _nicknameController,
                TextInputType.text,
                hintText: '닉네임 예시',
              ),
              const SizedBox(height: 16),
              _buildDropdownButtonFormField('성별', <String>['남자', '여자']),
              const SizedBox(height: 16),
              _buildRequiredTextFormField(
                '전화번호',
                _phoneNumberController,
                TextInputType.phone,
                hintText: '01012345678',
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),
              _buildOptionalTextFormField(
                '핸디캡',
                _handicapController,
                TextInputType.number,
                hintText: '숫자로 입력 (예: 28)',
              ),
              const SizedBox(height: 16),
              _buildRequiredTextFormField(
                '생일',
                _birthdayController,
                TextInputType.phone,
                hintText: '1990-01-01',
              ),
              const SizedBox(height: 16),
              _buildOptionalTextFormField(
                '주소',
                _addressController,
                TextInputType.streetAddress,
                hintText: '서울시 강남구',
              ),
              const SizedBox(height: 16),
              _buildOptionalTextFormField(
                '학번',
                _studentIdController,
                TextInputType.text,
                hintText: '',
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.green,
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                onPressed: _signUpStep2,
                child: const Text('가입하기', style: TextStyle(color: Colors.white, fontSize: 16)),
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
    );
  }

  Future<void> _signUpStep2() async {
    if (_formKey.currentState!.validate()) {
      var response = await UserService.saveAdditionalInfo(
        userId: widget.userId,
        name: _nicknameController.text,
        phoneNumber: _phoneNumberController.text,
        handicap: int.tryParse(_handicapController.text) ?? 0,
        dateOfBirth: _birthdayController.text,
        address: _addressController.text,
        studentId: _studentIdController.text,
      );

      if (response.statusCode == 200) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const SignupComplete(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('추가 정보 갱신에 실패했습니다. 다시 시도해 주세요.')),
        );
      }
    }
  }

  Widget _buildRequiredTextFormField(
      String label,
      TextEditingController controller,
      TextInputType keyboardType, {
        String? hintText,
        List<TextInputFormatter>? inputFormatters,
      }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: '$label *',
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[400]),
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$label을(를) 입력해주세요';
        }
        if (label == '전화번호' &&
            !RegExp(r'^\d{10,11}$').hasMatch(value)) {
          return '올바른 전화번호 형식이 아닙니다. (예: 01012345678)';
        }
        if (label == '생일' &&
            !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
          return '올바른 생일 형식이 아닙니다. (예: 1990-01-01)';
        }
        return null;
      },
    );
  }

  Widget _buildOptionalTextFormField(
      String label,
      TextEditingController controller,
      TextInputType keyboardType, {
        String? hintText,
        List<TextInputFormatter>? inputFormatters,
      }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[400]),
        border: const OutlineInputBorder(),
      ),
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
      items: ['선택', ...items].map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value == '선택' ? null : value,
          child: Text(value),
        );
      }).toList(),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null) {
          return '$label을(를) 선택해주세요';
        }
        return null;
      },
    );
  }
}
