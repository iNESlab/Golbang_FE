import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golbang/services/event_service.dart';
import '../../../repoisitory/secure_storage.dart';
import '../../../models/responseDTO/LocationResponseDTO.dart';

class LocationSearchDialog extends ConsumerStatefulWidget {
  final TextEditingController locationController;
  final Function(LocationResponseDTO) onLocationSelected;

  const LocationSearchDialog({
    super.key,
    required this.locationController,
    required this.onLocationSelected,
  });

  @override
  _LocationSearchDialogState createState() => _LocationSearchDialogState();
}

class _LocationSearchDialogState extends ConsumerState<LocationSearchDialog> {
  late EventService _eventService;
  List<LocationResponseDTO> _sites = [];
  List<LocationResponseDTO> _filteredSites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _eventService = EventService(ref.read(secureStorageProvider));
    _fetchLocations();
  }

  Future<void> _fetchLocations() async {
    try {
      List<LocationResponseDTO> sites = await _eventService.getLocationList();
      if (mounted) {
        setState(() {
          _sites = sites;
          _filteredSites = sites; // 초기 데이터 설정
          _isLoading = false;
        });
      }
    } catch (e) {
      log("Error fetching locations: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterLocations(String query) {
    setState(() {
      _filteredSites = _sites
          .where((location) =>
          location.golfClubName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20.0)),
      ),
      titlePadding: EdgeInsets.zero,
      title: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(),
            const Text(
              '장소 검색',
              style: TextStyle(color: Colors.green, fontSize: 25),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
      content: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: '장소를 입력하세요',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _filterLocations, // ✅ 검색어 입력 시 필터링 함수 호출
            ),
            const SizedBox(height: 10),
            Flexible( // ✅ ListView가 Column 안에서 동적으로 크기를 조절할 수 있도록 함
              child: _filteredSites.isEmpty
                  ? const Center(
                child: Text(
                  "검색 결과가 없습니다.",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
                  : ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredSites.length,
                itemBuilder: (BuildContext context, int index) {
                  return ListTile(
                    title: Text(_filteredSites[index].golfClubName),
                    onTap: () {
                      final site = _filteredSites[index];
                      widget.locationController.text = site.golfClubName;
                      widget.onLocationSelected(site);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      )
    );
  }
}
