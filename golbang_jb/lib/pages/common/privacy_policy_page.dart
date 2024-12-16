// 개인정보처리방침

import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
            '개인정보처리방침',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      backgroundColor: Colors.white,  // 전체 페이지 배경 흰색
      body: ListView(
        padding: const EdgeInsets.all(16.0),

        children: const [

          Section(
              title: '1. 개인정보 수집 항목',
              content: '''
저희 골프 모임 관리 서비스는 회원가입 및 원활한 서비스 제공을 위해 다음과 같은 개인정보를 수집합니다.

필수 항목:
- 사용자 아이디(user_id)
- 이메일(email)
- 비밀번호(password) (소셜 로그인 시 비밀번호 제외)
- 이름(name)
- 전화번호(phone_number)

선택 항목:
- 주소(address)
- 생년월일(date_of_birth)
- 학번(student_id)
- 프로필 사진(profile_image)
                '''
          ),
          Section(
              title: '2. 개인정보 수집 및 이용 목적',
              content: '''
수집된 개인정보는 다음과 같은 목적으로 사용됩니다.

서비스 제공:
- 골프 모임 관리 서비스의 주요 기능(스케줄 관리, 회원 통계, 모임 알림 등)을 제공하기 위해 사용.

회원 관리:
- 회원 가입 및 본인 인증
- 비밀번호 분실 시 계정 복구
- 회원 상태 관리 (활성/비활성)

서비스 향상:
- 서비스 품질 향상 및 기능 개발을 위한 데이터 분석.

알림 및 공지:
- FCM 토큰을 통해 모임 공지 및 주요 알림 전달.

법적 의무 준수:
- 법령에서 요구하는 기록 보관.
                '''
          ),
          Section(
              title: '3. 회원 탈퇴 및 개인정보 처리',
              content: '''
회원 탈퇴 시 개인정보는 아래와 같이 처리됩니다.

탈퇴 즉시 삭제:
- 회원의 개인정보(이름, 이메일, 전화번호 등)는 탈퇴 즉시 삭제됩니다.
- 관련 법령에서 정한 기간 동안 보관이 필요한 정보는 해당 기간이 지나면 완전히 삭제됩니다.

계정 복구를 위한 제한적 정보 보관:
- 사용자 아이디(user_id), 비밀번호(password)는 안전하게 보관됩니다.
- 소셜 로그인 계정의 경우 소셜 제공자의 정책에 따릅니다.
                '''
          ),
          Section(
              title: '4. 개인정보 보관 기간',
              content: '''
개인정보는 회원 탈퇴 시 즉시 삭제됩니다.

법적 의무에 따라 특정 정보는 일정 기간 동안 보관할 수 있습니다.
- 전자상거래법에 따른 거래 기록: 5년
- 통신비밀보호법에 따른 로그인 기록: 3개월
                '''
          ),
          Section(
              title: '5. 개인정보 제공 및 공유',
              content: '''
사용자의 개인정보는 원칙적으로 외부에 제공하지 않으며, 법령에 따라 요구되는 경우에만 제공됩니다.
                '''
          ),
          Section(
              title: '6. 개인정보 처리 위탁',
              content: '''
서비스 운영 및 관리를 위해 일부 정보를 신뢰할 수 있는 외부 업체에 위탁할 수 있으며, 계약을 통해 보호 조치를 관리합니다.
                '''
          ),
          Section(
              title: '7. 사용자의 권리 및 행사 방법',
              content: '''
회원은 언제든지 자신의 개인정보를 조회, 수정, 삭제할 수 있으며, 다음 권리를 행사할 수 있습니다.
- 개인정보 열람 요청
- 개인정보 수정 요청
- 개인정보 삭제 요청
- 회원 탈퇴 요청
                '''
          ),
          Section(
              title: '8. 개인정보 보호를 위한 기술적/관리적 조치',
              content: '''
개인정보 보호를 위해 다음과 같은 조치를 취하고 있습니다.
- 데이터 암호화
- 접근 통제
- 보안 점검
                '''
          ),
          Section(
              title: '9. 문의 및 정보 보호 책임자',
              content: '''
개인정보 보호 책임자: 김현철
연락처: iamgolbang@gmail.com
                '''
          ),
        ],
      ),
    );
  }
}

class Section extends StatelessWidget {
  final String title;
  final String content;

  const Section({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
        ],
      ),
    );
  }
}
