import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user_account.dart';
import '../../services/user_service.dart';
import '../../services/user_service_provider.dart';
import 'package:numberpicker/numberpicker.dart';

class UserInfoPage extends ConsumerStatefulWidget {
  final UserAccount initialUserAccount;

  UserInfoPage({required this.initialUserAccount});

  @override
  _UserInfoPageState createState() => _UserInfoPageState();
}


class _UserInfoPageState extends ConsumerState<UserInfoPage> {
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  late UserAccount _userAccount; // 상태로 관리하는 UserAccount

  @override
  void initState() {
    super.initState();
    _userAccount = widget.initialUserAccount; // 초기 상태 설정
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }

  Future<void> _updateUserInfo({String? field, String? value}) async {
    try {
      final userService = ref.watch(userServiceProvider);
      UserAccount updatedUser = await userService.updateUserInfo(
        userId: _userAccount.userId,
        name: field == '이름' ? value : _userAccount.name,
        email: field == '이메일' ? value : _userAccount.email,
        phoneNumber: field == '연락처' ? value : _userAccount.phoneNumber,
        handicap: field == '핸디캡' ? int.tryParse(value ?? _userAccount.handicap.toString()) : _userAccount.handicap,
        address: field == '집 주소' ? value : _userAccount.address,
        dateOfBirth: field == '생일' ? DateTime.parse(value!) : _userAccount.dateOfBirth,
        studentId: field == '학번' ? value : _userAccount.studentId,
        profileImage: _imageFile != null ? File(_imageFile!.path) : null,
      );

      setState(() {
        _userAccount = updatedUser; // 업데이트된 UserAccount를 상태로 설정
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$field 업데이트 완료')));
    } catch (e) {
      print('Failed to update $field: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$field 업데이트 실패')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('내 정보'),
        actions: [
          TextButton(
            onPressed: () {
              // 프로필 이미지가 선택되었거나 기존 상태가 변경되었는지 확인
              if (_imageFile != null) {
                // 프로필 이미지가 변경된 경우 API 호출
                _updateUserInfo(
                  field: '프로필 이미지',
                  value: _imageFile!.path,
                );
              } else {
                // 기존 상태 변경 확인 후 API 호출
                _updateUserInfo(
                  field: '이름',
                  value: _userAccount.name,
                );
                // 필요한 다른 필드들도 동일한 방식으로 API 호출 가능
              }
            },
            child: const Text(
              '확인',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          const SizedBox(height: 10),
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.transparent,
                backgroundImage: _imageFile != null
                    ? FileImage(File(_imageFile!.path))
                    : (_userAccount.profileImage != null
                    ? NetworkImage(_userAccount.profileImage!) as ImageProvider
                    : AssetImage('assets/default_profile.png')),
                child: _imageFile == null && _userAccount.profileImage == null
                    ? Icon(Icons.person, size: 50, color: Colors.white)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Center(
            child: TextButton(
              onPressed: _pickImage,
              child: const Text(
                '프로필 이미지 변경',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildEditableListTile('아이디', _userAccount.userId, false),
          _buildEditableListTile('이름', _userAccount.name, true),
          _buildEditableListTile('이메일', _userAccount.email, true),
          _buildEditableListTile('연락처', _userAccount.phoneNumber, true),
          _buildEditableListTile('핸디캡', _userAccount.handicap.toString(), true, isNumeric: true),
          _buildEditableListTile('집 주소', _userAccount.address, true),
          _buildEditableListTile(
              '생일',
              _userAccount.dateOfBirth != null
                  ? '${_userAccount.dateOfBirth!.year}년 ${_userAccount.dateOfBirth!.month}월 ${_userAccount.dateOfBirth!.day}일'
                  : '입력되지 않음',
              true),
          _buildEditableListTile('학번', _userAccount.studentId ?? '입력되지 않음', true),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              '* 대학 동문회 모임을 위해 필요한 경우 입력 바랍니다',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableListTile(String title, String value, bool editable, {bool isNumeric = false}) {
    return ListTile(
      title: Text(title),
      subtitle: Text(value),
      trailing: editable ? Icon(Icons.chevron_right) : null,
      onTap: editable
          ? () {
        if (isNumeric) {
          _showNumberPicker(context, title, int.parse(value));
        } else if (title == '생일') {
          _showDatePicker(context, title, _userAccount.dateOfBirth);
        } else {
          _showEditDialog(context, title, value);
        }
      }
          : null,
    );
  }

  // NumberPicker를 사용하는 다이얼로그
  void _showNumberPicker(BuildContext context, String field, int initialValue) {
    int selectedValue = initialValue;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 화면에 꽉 차도록 설정
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: Color(0xFFF6F6F6),
                borderRadius: BorderRadius.vertical(top: Radius.circular(40)), // 상단 모서리 둥글게
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      height: 200, // 높이를 200으로 설정
                      decoration: BoxDecoration(
                        color: Color(0xFFF6F6F6), // 내부 배경색 (NumberPicker 영역)
                        borderRadius: BorderRadius.circular(15), // 모서리를 둥글게 설정
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 24), // 좌우 패딩 추가
                      child: NumberPicker(
                        value: selectedValue,
                        minValue: 0,
                        maxValue: 100,
                        onChanged: (value) {
                          setState(() {
                            selectedValue = value;
                          });
                        },
                        selectedTextStyle: TextStyle(
                          color: Color(0xFF2DC653), // 숫자 색상 2DC653
                          fontSize: 27,
                          fontWeight: FontWeight.bold,
                        ),
                        textStyle: TextStyle(
                          color: Colors.black45, // 비선택 숫자 색상
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 15),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        // 선택된 값을 저장
                        _updateUserInfo(field: field, value: selectedValue.toString());
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Color(0xFF2DC653), // 버튼 배경 색상 2DC653
                        minimumSize: Size(MediaQuery.of(context).size.width - 40, 50), // 버튼 너비와 높이를 조정
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15), // 버튼 모서리를 둥글게
                        ),
                      ),
                      child: const Text('저장', style: TextStyle(fontSize: 18)), // 폰트 크기를 20으로 설정
                    ),
                  ),
                  SizedBox(height: 10, child: Container(color: Color(0xFFF6F6F6))), // 버튼 아래에 공간을 추가하여 배경색이 보이도록 함
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, String field, String value) {
    TextEditingController controller = TextEditingController(text: value);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('$field 수정'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: '새로운 $field 입력',
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF2DC653)), // 입력창 밑줄 색상 설정
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF2DC653)), // 포커스 시 밑줄 색상 설정
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                '취소',
                style: TextStyle(color: Colors.black54), // 메인 컬러로 설정
              ),
            ),
            TextButton(
              onPressed: () {
                _updateUserInfo(field: field, value: controller.text);
                Navigator.of(context).pop();
              },
              child: const Text(
                '저장',
                style: TextStyle(color: Color(0xFF2DC653)), // 메인 컬러로 설정
              ),
            ),
          ],
          backgroundColor: Color(0xFFF6F6F6), // 다이얼로그 배경색 설정
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // 모서리를 둥글게 설정
          ),
        );
      },
    );
  }

  void _showDatePicker(BuildContext context, String field, DateTime? initialDate) {
    showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Color(0xFF2DC653), // 달력의 메인 컬러 설정
            hintColor: Color(0xFF2DC653), // 선택된 날짜의 컬러 설정
            colorScheme: ColorScheme.light(primary: Color(0xFF2DC653)),
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    ).then((pickedDate) {
      if (pickedDate != null) {
        String formattedDate =
            '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';
        _updateUserInfo(field: field, value: formattedDate);
      }
    });
  }
}
