import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:golbang/pages/signup/widgets/welcome_header_widget.dart';
import 'package:golbang/pages/signup/additional_info.dart';

// 약관 동의 메인 페이지

class TermsAgreementPage extends StatefulWidget {
  final String? email;
  final String? displayName;
  final bool isSocialLogin;
  final String? provider;
  final String? tempUserId;  // 🔧 추가: 임시 사용자 ID

  const TermsAgreementPage({
    super.key,
    this.email,
    this.displayName,
    this.isSocialLogin = false,
    this.provider,
    this.tempUserId,
  });

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
      if (widget.isSocialLogin) {
        // 소셜 로그인 사용자는 AdditionalInfoPage로 바로 이동 (아이디/비밀번호 입력 건너뛰기)
        String queryParams = 'isSocialLogin=true';
        if (widget.email != null && widget.email!.isNotEmpty) {
          queryParams += '&email=${widget.email}';
        }
        if (widget.displayName != null && widget.displayName!.isNotEmpty) {
          queryParams += '&displayName=${widget.displayName}';
        }
        if (widget.provider != null) {
          queryParams += '&provider=${widget.provider}';
        }
        if (widget.tempUserId != null && widget.tempUserId!.isNotEmpty) {
          queryParams += '&tempUserId=${widget.tempUserId}';
        }
        context.push('/app/signup/additional-info?$queryParams');
      } else {
        // 일반 회원가입 사용자는 아이디/비밀번호 입력 페이지로 이동
        context.push('/app/signup');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('필수 약관에 동의해주세요.')),
      );
    }
  }

  void _navigateToTermsDetail(String key) {

   context.push('/app/signup/terms/detail', extra: {'key': key}).then((_) {
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
                          // 소셜 로그인 사용자 환영 메시지
                          if (widget.isSocialLogin) ...[
                            const Text(
                              '🏌️‍♂️ 골방에 오신 것을 환영합니다!',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${widget.displayName ?? '사용자'}님, 약관에 동의해주세요',
                              style: const TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                            const SizedBox(height: 24),
                          ],
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
