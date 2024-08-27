import 'package:flutter/material.dart';
import 'package:golbang/pages/logins/login.dart';

class HiScreen extends StatelessWidget {
  const HiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            // Top part with a reduced height for the background image
            Container(
              height: MediaQuery.of(context).size.height *
                  0.06, // Adjust height as needed
              color: Colors.black,
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height *
                  0.34, // Set the height as 40% of the screen height
              child: Stack(
                children: [
                  // Background image
                  Container(
                    decoration: const BoxDecoration(
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
                      const SizedBox(
                          height: 40), // Adjust space for the circular widget
                      const Text(
                        '편하고 쉽게 모임 방을 만들어\n 골프를 즐겨보세요!',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          decoration: TextDecoration.none,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      // Join button
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/signup');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: const Size(400, 50),
                        ),
                        child: const Text('가입하기',
                            style:
                                TextStyle(color: Colors.white, fontSize: 18)),
                      ),
                      const SizedBox(height: 20),
                      // Continue with Google button
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: Image.asset('assets/images/google.png', width: 24),
                        label: const Text('Google로 계속하기',
                            style: TextStyle(color: Colors.white)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white),
                          minimumSize: const Size(400, 50),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Continue with KakaoTalk button
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: Image.asset('assets/images/kakao.png', width: 24),
                        label: const Text('카카오톡으로 계속하기',
                            style: TextStyle(color: Colors.white)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white),
                          minimumSize: const Size(400, 50),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Continue with Naver button
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: Image.asset('assets/images/naver.png', width: 24),
                        label: const Text('네이버로 계속하기',
                            style: TextStyle(color: Colors.white)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white),
                          minimumSize: const Size(400, 50),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Login button
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const LoginPage()),
                          );
                        },
                        child: const Text('로그인하기',
                            style: TextStyle(color: Colors.white)),
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
          top: MediaQuery.of(context).size.height *
              0.25, // Adjust this value to move the text down
          left: 0,
          right: 0,
          child: const Text(
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
          top: MediaQuery.of(context).size.height * 0.4 -
              50, // Adjust position based on image height
          left: MediaQuery.of(context).size.width / 2 - 50,
          child: const CircleAvatar(
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
