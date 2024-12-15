import 'package:flutter/material.dart';
import 'signup.dart'; // SignUpPage를 불러옵니다.

class TermsAgreementPage extends StatefulWidget {
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
      Navigator.push(context, MaterialPageRoute(builder: (context) => SignUpPage()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('필수 약관에 동의해주세요.')),
      );
    }
  }

  void _navigateToTermsDetail(String title, String content) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TermsDetailPage(title: title, content: content),
      ),
    ).then((_) {
      setState(() {
        terms[title] = true; // 약관 페이지를 다녀오면 동의되도록 설정
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
            SizedBox(height: MediaQuery.of(context).size.height * 0.3), // 상단 여백
            // 로고
            Image.asset(
              'assets/images/logo-green.png',
              width: 100,
              height: 100,
              alignment: Alignment.centerLeft,
            ),
            SizedBox(height: 20),
            // 환영 메시지
            Text('환영합니다!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text('편하고 쉽게 골프를 즐겨보세요.',
                style: TextStyle(fontSize: 20)),
            SizedBox(height: 30),
            // 약관 전체 동의
            CheckboxListTile(
              title: Text('약관 전체동의'),
              activeColor: Colors.green,
              value: isAllChecked,
              onChanged: _checkAll,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            Divider(),
            // 개별 약관 동의
            ...terms.keys.map((key) {
              return ListTile(
                leading: Checkbox(
                  activeColor: Colors.green,
                  value: terms[key],
                  onChanged: (value) => _checkIndividual(key, value),
                ),
                title: Text(key),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _navigateToTermsDetail(
                  key,
                  '$key에 대한 상세 약관 내용이 여기에 표시됩니다. 아주 긴 내용을 넣어도 스크롤이 가능하게 구현했습니다.',
                ),
              );
            }).toList(),
            Spacer(),
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
                  minimumSize: Size(double.infinity, 50),
                ),
                child: Text('다음', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TermsDetailPage extends StatelessWidget {
  final String title;
  final String content;

  const TermsDetailPage({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title, style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(content, style: TextStyle(fontSize: 16, height: 1.5)),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            minimumSize: Size(double.infinity, 50),
          ),
          child: Text('동의', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}
