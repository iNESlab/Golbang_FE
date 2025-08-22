import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../models/event.dart';
import '../diagonal_text_painter.dart';

class CourseInfoCard extends StatelessWidget {
  final LatLng? selectedLocation;
  final String golfClubName;
  final Event event;
  final double fontSizeLarge;
  final double fontSizeMedium;

  const CourseInfoCard({
    super.key,
    required this.selectedLocation,
    required this.golfClubName,
    required this.event,
    required this.fontSizeLarge,
    required this.fontSizeMedium,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedLocation == null) return const SizedBox.shrink();


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text("골프장 위치", style: TextStyle(fontSize: fontSizeLarge, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          height: 200,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8.0)),
          child: GoogleMap(
            initialCameraPosition: CameraPosition(target: selectedLocation!, zoom: 14.0),
            markers: {
              Marker(markerId: const MarkerId('selected-location'), position: selectedLocation!)
            },
          ),
        ),
        const SizedBox(height: 16),
        Text("코스 정보", style: TextStyle(fontSize: fontSizeLarge, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        event.golfCourse != null
            ? Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (golfClubName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      golfClubName,
                      style: TextStyle(fontSize: fontSizeMedium, fontWeight: FontWeight.bold, color: Colors.teal),
                    ),
                  ),
                Text(
                  event.golfCourse!.golfCourseName,
                  style: TextStyle(fontSize: fontSizeLarge, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("홀 수: ${event.golfCourse!.holes}",
                        style: TextStyle(fontSize: fontSizeMedium, color: Colors.grey[700])),
                    Text("코스 Par: ${event.golfCourse!.par}",
                        style: TextStyle(fontSize: fontSizeMedium, color: Colors.grey[700])),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: event.golfCourse!.tees.isEmpty
                        ? []
                        : List.generate(event.golfCourse!.holes, (index) {
                      final holeNumber = index + 1;
                      final par = event.golfCourse!.tees[0].holePars[index];
                      return Container(
                        width: 50,
                        height: 50,
                        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                          border: Border.all(color: Colors.grey[300]!, width: 1),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CustomPaint(
                            painter: DiagonalTextPainter(holeNumber: holeNumber, par: par),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        )
            : Text("코스 정보가 없습니다.", style: TextStyle(color: Colors.redAccent, fontSize: fontSizeMedium)),
      ],
    );
  }
}
