import 'dart:ui';
import 'package:flutter/material.dart';
import 'login.dart';




class HiScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            // Top part with a reduced height for the background image
            Container(
              height: MediaQuery.of(context).size.height * 0.06, // Adjust height as needed
              color: Colors.black,
            ),
            Container(
              height: MediaQuery.of(context).size.height * 0.34, // Set the height as 40% of the screen height
              child: Stack(
                children: [
                  // Background image
                  Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/founder.JPG'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Dark overlay
                  Container(
                    color: Colors.black.withOpacity(0.5),
                  ),
                ],
              ),
            ),
            // Bottom part with content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 40), // Adjust space for the circular widget
                      Text(
                        '편하고 쉽게 모임 방을 만들어\n 골프를 즐겨보세요!',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          decoration: TextDecoration.none,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),
                      // Join button
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: Size(400, 50),
                        ),
                        child: Text('가입하기',
                            style:TextStyle(
                              color: Colors.white,
                                fontSize: 18)),
                      ),
                      SizedBox(height: 20),
                      // Continue with Google button
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: Icon(Icons.account_circle, color: Colors.white),
                        label: Text('Google로 계속하기', style: TextStyle(color: Colors.white)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.white),
                          minimumSize: Size(400, 50),
                        ),
                      ),
                      SizedBox(height: 20),
                      // Continue with KakaoTalk button
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: Icon(Icons.chat, color: Colors.yellow),
                        label: Text('카카오톡으로 계속하기', style: TextStyle(color: Colors.white)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.white),
                          minimumSize: Size(400, 50),
                        ),
                      ),
                      SizedBox(height: 20),
                      // Continue with Naver button
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: Icon(Icons.search, color: Colors.green),
                        label: Text('네이버로 계속하기', style: TextStyle(color: Colors.white)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.white),
                          minimumSize: Size(400, 50),
                        ),
                      ),
                      SizedBox(height: 20),
                      // Login button
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => LoginPage()),
                          );
                        },
                        child: Text('로그인하기', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        // Circular widget in the middle
        Positioned(
          top: MediaQuery.of(context).size.height * 0.25, // Adjust this value to move the text down
          left: 0,
          right: 0,
          child: Text(
            'GolBang',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              decoration: TextDecoration.none,
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height * 0.4 - 50, // Adjust position based on image height
          left: MediaQuery.of(context).size.width / 2 - 50,
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.golf_course,
              size: 50,
              color: Colors.green,
            ),
          ),
        ),
      ],
    );
  }
}


class ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}