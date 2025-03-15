import 'package:flutter/material.dart';
import 'package:golbang/services/event_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../repoisitory/secure_storage.dart';

import '../../../models/responseDTO/LocationResponseDTO.dart';

class LocationSearchDialog extends ConsumerStatefulWidget {
  final TextEditingController locationController;
  final Function(LocationResponseDTO) onLocationSelected;

  const LocationSearchDialog({super.key, 
    required this.locationController,
    required this.onLocationSelected,
  });

  @override
  _LocationSearchDialogState createState() => _LocationSearchDialogState();
}

class _LocationSearchDialogState extends ConsumerState<LocationSearchDialog> {
  List<LocationResponseDTO> _sites = [];
  late EventService _eventService;

  @override
  void initState() {
    super.initState();
    _eventService = EventService(ref.read(secureStorageProvider));
    _sites = _eventService.getLocationList() as List<LocationResponseDTO>;
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
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
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
                onChanged: (value) {
                  setState(() {
                    _sites = _sites
                        .where((location) => location.golfClubName.toLowerCase().contains(value.toLowerCase()))
                        .toList();
                  });
                },
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 300,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _sites.length,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                      title: Text(_sites[index].golfClubName),
                      onTap: () {
                        final site = _sites[index];
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
        ),
      ),
      actions: <Widget>[
        Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('완료'),
          ),
        ),
      ],
    );
  }
}
