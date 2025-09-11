/*
import 'package:flutter/material.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationSearchDialog extends StatefulWidget {
  final TextEditingController locationController;
  final Function(LatLng) onLocationSelected;

  LocationSearchDialog({
    required this.locationController,
    required this.onLocationSelected,
  });

  @override
  _LocationSearchDialogState createState() => _LocationSearchDialogState();
}

class _LocationSearchDialogState extends State<LocationSearchDialog> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20.0)),
      ),
      titlePadding: EdgeInsets.zero,
      title: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
        ),
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(),
            Text(
              '장소 검색',
              style: TextStyle(color: Colors.green, fontSize: 25),
            ),
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
      content: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GooglePlaceAutoCompleteTextField(
              textEditingController: widget.locationController,
              googleAPIKey: "YOUR_API_KEY", // 여기에 실제 API 키를 입력하세요.
              inputDecoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: '장소를 입력하세요',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
              ),
              focusNode: _focusNode,
              debounceTime: 800, // 검색 요청 사이의 딜레이 시간
              countries: ['kr'], // 한국 지역으로 제한
              isLatLngRequired: true, // 선택된 장소의 좌표를 받기 위해 true로 설정
              getPlaceDetailWithLatLng: (Prediction prediction) {
                double lat = double.parse(prediction.lat!);
                double lng = double.parse(prediction.lng!);
                LatLng selectedLatLng = LatLng(lat, lng);

                widget.onLocationSelected(selectedLatLng);
                Navigator.of(context).pop(); // 다이얼로그 닫기
              },
              itmClick: (Prediction prediction) {
                widget.locationController.text = prediction.description!;
                _focusNode.unfocus();
              },
            ),
          ],
        ),
      ),
      actions: <Widget>[
        Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('완료'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              minimumSize: Size(double.infinity, 50),
            ),
          ),
        ),
      ],
    );
  }
}


 */