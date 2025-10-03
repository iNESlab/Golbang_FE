import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:golbang/pages/signup/widgets/calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golbang/provider/user/user_service_provider.dart';
import 'package:golbang/repoisitory/secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:golbang/pages/home/splash_screen.dart';
import 'package:golbang/pages/home/splash_screen.dart' as home;
import 'package:golbang/pages/logins/login.dart';

// 회원가입 완료 페이지 import

class AdditionalInfoPage extends ConsumerStatefulWidget {
  final int? userId;        // 기존 회원가입용
  final String? email;      // 소셜 로그인용 (새로 추가)
  final String? displayName; // 소셜 로그인용 (새로 추가)
  final bool isSocialLogin;  // 소셜 로그인 여부 (새로 추가)

  const AdditionalInfoPage({
    super.key,
    this.userId,
    this.email,
    this.displayName,
    this.isSocialLogin = false,
  });

  @override
  _AdditionalInfoPageState createState() => _AdditionalInfoPageState();
}

class _AdditionalInfoPageState extends ConsumerState<AdditionalInfoPage> {
  final _formKey = GlobalKey<FormState>();

  final _nicknameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _handicapController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _addressController = TextEditingController();
  final _studentIdController = TextEditingController();

  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    
    if (widget.isSocialLogin) {
      // Google 정보로 닉네임 자동 채우기 (사용자가 수정 가능)
      _nicknameController.text = widget.displayName ?? '';
      // 이메일은 표시만 (수정 불가)
    }
  }

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
            if (widget.isSocialLogin) {
              // 소셜 로그인 사용자는 로그인 화면으로 직접 이동
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginPage(),
                ),
                (route) => false, // 모든 이전 화면 제거
              );
            } else {
              // 일반 회원가입 사용자는 이전 화면으로
              context.pop();
            }
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
              if (widget.isSocialLogin) ...[
                // 소셜 로그인용 환영 메시지
                const Text(
                  '🏌️‍♂️ 골방에 오신 것을 환영합니다!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  '프로필을 완성해주세요',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 24),
              ] else ...[
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
              ],
              // 닉네임 (필수)
              _buildNicknameTextFormField(
                '닉네임',
                _nicknameController,
                TextInputType.text,
                hintText: '닉네임 예시',
              ),
              const SizedBox(height: 16),
              // 이메일 (Google 로그인 시에만 표시)
              if (widget.isSocialLogin) ...[
                TextFormField(
                  initialValue: widget.email,
                  decoration: const InputDecoration(
                    labelText: '이메일',
                    border: OutlineInputBorder(),
                  ),
                  enabled: false, // Google에서 가져온 이메일이므로 수정 불가
                ),
                const SizedBox(height: 16),
              ],
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
                inputFormatters: [FilteringTextInputFormatter.digitsOnly], // 🔧 추가: 숫자만 입력 허용
              ),
              const SizedBox(height: 16),
              DayPickerField(controller: _birthdayController), // ✅ 생일 선택 필드 사용
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
                child: Text(
                  widget.isSocialLogin ? '프로필 완성하기' : '가입하기',
                  style: const TextStyle(color: Colors.white, fontSize: 16)
                ),
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
      if (widget.isSocialLogin) {
        // 소셜 로그인용: 프로필 정보만 저장
        await _saveSocialUserProfile();
      } else {
        // 기존 회원가입용: 기존 로직 사용
        await _saveAdditionalInfo();
      }
    }
  }

  Future<void> _saveAdditionalInfo() async {
    // 🔧 수정: 핸디캡은 선택사항으로 변경
    final handicapText = _handicapController.text.trim();
    int? handicap;
    
    if (handicapText.isNotEmpty) {
      handicap = int.tryParse(handicapText);
      if (handicap == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('핸디캡은 정수로 입력해주세요. (예: 28)'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }
    
    final userService = ref.watch(userServiceProvider);
    var response = await userService.saveAdditionalInfo(
      userId: widget.userId!,
      name: _nicknameController.text,
      phoneNumber: _phoneNumberController.text,
      handicap: handicap ?? 0, // 핸디캡이 null이면 0으로 전송
      dateOfBirth: _birthdayController.text,
      address: _addressController.text,
      studentId: _studentIdController.text,
    );
    log(_phoneNumberController.text);
    log(_addressController.text);
    log(response.statusCode.toString());
    
    if (response.statusCode == 200) {
      // 🔧 수정: GoRouter 사용으로 화면 전환
      if (mounted) {
        context.go('/app/signup/complete');
      }
    } else {
      // 🔧 추가: 상세한 에러 메시지 표시
      try {
        final errorData = response.data;
        if (errorData != null && errorData['handicap'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('핸디캡 입력 오류: ${errorData['handicap'][0]}'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('추가 정보 갱신에 실패했습니다. 다시 시도해 주세요.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('추가 정보 갱신에 실패했습니다. 다시 시도해 주세요.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveSocialUserProfile() async {
    try {
      // JWT 토큰에서 userId 추출
      final accessToken = await ref.read(secureStorageProvider).readAccessToken();
      final decodedToken = JwtDecoder.decode(accessToken);
      final userId = int.parse(decodedToken['user_id'].toString());
      
      // 기존 saveAdditionalInfo API 활용
      final userService = ref.watch(userServiceProvider);
      // 🔧 수정: 핸디캡은 선택사항으로 변경
      final handicapText = _handicapController.text.trim();
      int? handicap;
      
      if (handicapText.isNotEmpty) {
        handicap = int.tryParse(handicapText);
        if (handicap == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('핸디캡은 정수로 입력해주세요. (예: 28)'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
      
      final response = await userService.saveAdditionalInfo(
        userId: userId,
        name: _nicknameController.text,
        phoneNumber: _phoneNumberController.text,
        handicap: handicap ?? 0, // 핸디캡이 null이면 0으로 전송
        dateOfBirth: _birthdayController.text,
        address: _addressController.text,
        studentId: _studentIdController.text,
      );
      
      if (response.statusCode == 200) {
        log('✅ 프로필 저장 성공! 화면 전환 시작...');
        // 🔧 수정: GoRouter 사용으로 화면 전환 (Navigator API 충돌 방지)
        if (mounted) {
          context.go('/app/splash');
          log('✅ 화면 전환 완료!');
        }
      } else {
        throw Exception('프로필 저장 실패');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('프로필 저장에 실패했습니다: $e')),
      );
    }
  }
  Widget _buildNicknameTextFormField(
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
        labelText: label,
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[400]),
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return null;
        }
        /*
        if (value == null || value.isEmpty) {
          return '$label을(를) 입력해주세요';
        }
        */
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
