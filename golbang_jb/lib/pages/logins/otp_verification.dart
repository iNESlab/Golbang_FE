import 'package:flutter/material.dart';
import 'create_new_password.dart';

class OTPVerificationPage extends StatefulWidget {
  final String email;

  const OTPVerificationPage({super.key, required this.email});

  @override
  _OTPVerificationPageState createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage> {
  List<String> otpDigits = List.filled(4, '');
  final FocusNode _focusNode1 = FocusNode();
  final FocusNode _focusNode2 = FocusNode();
  final FocusNode _focusNode3 = FocusNode();
  final FocusNode _focusNode4 = FocusNode();

  void _verifyOTP() {
    String enteredOTP = otpDigits.join('');

    // OTP 형식 검증 (숫자 4자리인지 확인)
    if (enteredOTP.length != 4 || !RegExp(r'^\d{4}$').hasMatch(enteredOTP)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 4-digit OTP')),
      );
      return; // 유효하지 않은 경우 함수 종료
    }

    if (enteredOTP == '더미데이터') {
      // OTP 일치 - 다음 화면으로 이동 등의 처리
      //Navigator.of(context).pushReplacementNamed('/success');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const CreateNewPasswordPage(), // SuccessPage 생성
        ),
      );
    } else {
      // OTP 불일치 - 에러 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please check your OTP')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'OTP Verification',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Enter the verification code we just sent on your email address.",
              style: TextStyle(fontSize: 16, color: Colors.grey[400]),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildOTPField(0, _focusNode1),
                _buildOTPField(1, _focusNode2),
                _buildOTPField(2, _focusNode3),
                _buildOTPField(3, _focusNode4),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _verifyOTP,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
              child: const Text('Verify',
                  style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
            const Spacer(),
            Center(
              child: TextButton(
                onPressed: () {
                  // OTP 재전송 로직
                },
                child: const Text("Didn't receive code? Resend",
                    style: TextStyle(
                        color: Colors.blueAccent, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOTPField(int index, FocusNode focusNode) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.2,
      child: TextField(
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        onChanged: (value) {
          if (value.length == 1) {
            otpDigits[index] = value;
            if (index < 3) {
              FocusScope.of(context).requestFocus(_focusNode2);
            } else {
              FocusScope.of(context).unfocus();
            }
          } else {
            otpDigits[index] = '';
          }
        },
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.grey[800],
          hintText: '0',
          hintStyle: TextStyle(color: Colors.grey[500]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide.none,
          ),
        ),
        style: const TextStyle(color: Colors.white, fontSize: 24),
      ),
    );
  }
}
