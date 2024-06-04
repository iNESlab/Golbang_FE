import 'package:flutter/material.dart';

class OTPVerificationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'OTP Verification',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Enter the verification code we just sent on your email address.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[400],
              ),
            ),
            SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildOTPField(context),
                _buildOTPField(context),
                _buildOTPField(context),
                _buildOTPField(context),
              ],
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // OTP 확인 기능을 여기에 구현합니다.
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal, // 배경색
                minimumSize: Size(double.infinity, 50), // 전체 너비 버튼
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
              child: Text(
                'Verify',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
            Expanded(child: Container()), // 남은 공간을 채우기 위해 사용
            Center(
              child: GestureDetector(
                onTap: () {
                  // OTP 재전송 기능을 여기에 구현합니다.
                },
                child: Text(
                  "Didn't receive code? Resend",
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOTPField(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.2,
      child: TextField(
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
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
        style: TextStyle(color: Colors.white, fontSize: 24),
      ),
    );
  }
}
