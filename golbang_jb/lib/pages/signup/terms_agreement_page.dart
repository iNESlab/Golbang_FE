import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:golbang/pages/signup/widgets/welcome_header_widget.dart';

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
      context.push('/signup');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('필수 약관에 동의해주세요.')),
      );
    }
  }

  void _navigateToTermsDetail(String key) {

   context.push('/signup/terms/detail', extra: {'key': key}).then((_) {
      // 돌아온 뒤 동의 처리
      setState(() {
        terms[key] = true;
        isAllChecked = terms.values.every((v) => v);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final padding = constraints.maxWidth * 0.08;

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: padding),
              child: Column(
                children: [
                  // 상단(중앙 정렬) 영역
                  Expanded(
                    child: Center(
                      // Column을 Center로 감싸면, 남은 공간에서 세로 중앙 배치
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // 내용 높이에 맞게 축소
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 웰컴 헤더 (상단 패딩 최소화)
                          const WelcomeHeader(topPadding: 0.0),
                          // 약관 전체동의
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
                        ],
                      ),
                    ),
                  ),
                  // 하단 버튼 (화면 아래쪽 고정)
                  ElevatedButton(
                    onPressed: (terms['[필수] 이용약관 동의']! &&
                        terms['[필수] 개인정보 수집 및 이용 동의']!)
                        ? _onSubmit
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      disabledBackgroundColor: Colors.grey.shade300,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text(
                      '다음',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 16), // 버튼 아래쪽 여백
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
