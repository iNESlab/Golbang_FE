import 'package:flutter/material.dart';
import 'package:golbang/pages/signup/term_of_service_page.dart';
import 'package:golbang/pages/signup/widgets/welcome_header_widget.dart';
import '../common/privacy_policy_page.dart';
import 'marketing_agreement_page.dart';
import 'signup.dart';

// 약관 동의 메인 페이지

class TermsAgreementPage extends StatefulWidget {
  const TermsAgreementPage({super.key});

  @override
  _TermsAgreementPageState createState() => _TermsAgreementPageState();
}

class _TermsAgreementPageState extends State<TermsAgreementPage> {
  bool isAllChecked = false;

  // 약관 상태 관리
  Map<String, bool> terms = {
    '[필수] 이용약관 동의': false,
    '[필수] 개인정보 수집 및 이용 동의': false,
    '[선택] 광고성 정보 수신 동의': false,
  };

  void _checkAll(bool? value) {
    setState(() {
      isAllChecked = value ?? false;
      terms.updateAll((key, _) => isAllChecked);
    });
  }

  void _checkIndividual(String key, bool? value) {
    setState(() {
      terms[key] = value ?? false;
      isAllChecked = terms.values.every((v) => v);
    });
  }

  void _onSubmit() {
    if (terms['[필수] 이용약관 동의']! && terms['[필수] 개인정보 수집 및 이용 동의']!) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpPage()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('필수 약관에 동의해주세요.')),
      );
    }
  }

  void _navigateToTermsDetail(String key) {
    Widget targetPage;

    // 약관 항목에 따라 이동할 페이지 설정
    if (key == '[필수] 이용약관 동의') {
      targetPage = const TermsOfServicePage(); // 이용약관 페이지 연결
    }
    else if (key == '[필수] 개인정보 수집 및 이용 동의') {
      targetPage = const PrivacyPolicyPage(); // 개인정보처리방침 페이지 연결
    }
    else {
      targetPage = const MarketingAgreementPage(); // 광고성 정보 수신 동의 페이지 연결
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => targetPage),
    ).then((_) {
      setState(() {
        terms[key] = true; // 약관 페이지를 다녀오면 동의 처리
        isAllChecked = terms.values.every((v) => v);
      });
    });
  }


  @override
  Widget build(BuildContext context) {
    final double padding = MediaQuery.of(context).size.width * 0.08;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const WelcomeHeader(), // 웰컴 헤
            // 약관 전체 동의
            CheckboxListTile(
              title: const Text('약관 전체동의'),
              activeColor: Colors.green,
              value: isAllChecked,
              onChanged: _checkAll,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const Divider(),
            // 개별 약관 동의
            ...terms.keys.map((key) {
              return ListTile(
                leading: Checkbox(
                  activeColor: Colors.green,
                  value: terms[key],
                  onChanged: (value) => _checkIndividual(key, value),
                ),
                title: Text(key),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _navigateToTermsDetail(key),
              );
            }),
            const Spacer(),
            // 하단 버튼
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: ElevatedButton(
                onPressed: (terms['[필수] 이용약관 동의']! &&
                    terms['[필수] 개인정보 수집 및 이용 동의']!)
                    ? _onSubmit
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  disabledBackgroundColor: Colors.grey.shade300,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('다음', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
