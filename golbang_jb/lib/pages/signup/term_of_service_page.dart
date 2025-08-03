// 이용 약관 동의 페이지
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          '이용약관 동의',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          Section(
            title: '1. 서비스 개요',
            content: '''
본 서비스는 사용자가 골프 모임을 관리하고, 스케줄을 조율하며, 멤버 간의 소통을 지원하는 플랫폼입니다.
이용자는 본 약관을 준수함으로써 서비스의 다양한 기능을 사용할 수 있습니다.
              ''',
          ),
          Section(
            title: '2. 회원 가입 및 계정 관리',
            content: '''
회원 가입 시 정확하고 최신의 정보를 제공해야 합니다.
타인의 정보를 도용하거나 허위 정보를 제공하는 경우 서비스 이용이 제한될 수 있습니다.
이용자는 계정 보안을 유지할 책임이 있으며, 계정 정보가 유출된 경우 즉시 관리자에게 알려야 합니다.
              ''',
          ),
          Section(
            title: '3. 서비스 이용 제한',
            content: '''
다음과 같은 행위는 서비스 이용이 제한될 수 있습니다:
- 타인의 권리를 침해하거나 불쾌감을 주는 행위
- 서비스의 정상적 운영을 방해하는 행위
- 불법적이거나 부적절한 콘텐츠 업로드
- 스팸 메시지 발송 및 광고 행위
              ''',
          ),
          Section(
            title: '4. 개인 정보 보호',
            content: '''
서비스 이용 시 수집된 개인정보는 개인정보 처리방침에 따라 안전하게 관리됩니다.
서비스 내 제공되는 개인정보 보호 정책을 반드시 확인하시기 바랍니다.
              ''',
          ),
          Section(
            title: '5. 콘텐츠 및 저작권',
            content: '''
서비스 내의 모든 콘텐츠는 저작권법의 보호를 받습니다.
이용자는 서비스 내 콘텐츠를 무단으로 복사, 배포, 수정할 수 없습니다.
개인 사용을 위한 경우에만 제한적으로 사용할 수 있습니다.
              ''',
          ),
          Section(
            title: '6. 면책 조항',
            content: '''
회사는 서비스 이용과 관련하여 발생하는 모든 문제에 대해 책임을 지지 않습니다.
단, 회사의 고의 또는 중대한 과실로 인한 경우는 예외로 합니다.
              ''',
          ),
          Section(
            title: '7. 약관의 변경 및 고지',
            content: '''
회사는 필요한 경우 약관을 변경할 수 있으며, 변경된 약관은 서비스 내 공지사항을 통해 사전 고지합니다.
변경된 약관은 공지된 날로부터 효력이 발생합니다.
이용자는 변경된 약관에 동의하지 않을 경우 서비스 이용을 중단할 수 있습니다.
              ''',
          ),
          Section(
            title: '8. 문의 사항',
            content: '''
서비스와 관련된 문의 사항은 아래 연락처로 문의해 주세요.
이메일: iamgolbang@gmail.com
                ''',
          ),
        ],
      ),
    );
  }
}

class Section extends StatelessWidget {
  final String title;
  final String content;

  const Section({super.key, required this.title, required this.content});

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
