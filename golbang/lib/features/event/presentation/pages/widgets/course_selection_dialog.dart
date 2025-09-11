import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../repoisitory/secure_storage.dart';
import '../../../features/event/data/models/golf_course_detail_response_dto.dart';
import 'package:golbang/services/club_service.dart';

class CourseSelectionDialog extends ConsumerStatefulWidget {
  final int golfClubId;
  final String golfClubName;
  final Function(CourseResponseDTO) onCourseSelected;

  const CourseSelectionDialog({
    super.key,
    required this.golfClubId,
    required this.golfClubName,
    required this.onCourseSelected,
  });

  @override
  ConsumerState<CourseSelectionDialog> createState() => _CourseSelectionDialogState();
}

class _CourseSelectionDialogState extends ConsumerState<CourseSelectionDialog> {
  late ClubService _clubService;
  List<CourseResponseDTO> _courses = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _clubService = ClubService(ref.read(secureStorageProvider));
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    try {
      log('코스 선택 다이얼로그 - 골프장 ID: ${widget.golfClubId}');
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final courses = await _clubService.getGolfCourses(widget.golfClubId);
      log('코스 선택 다이얼로그 - 받은 코스 개수: ${courses.length}');
      
      setState(() {
        _courses = courses;
        _isLoading = false;
      });
    } catch (e) {
      log('코스 선택 다이얼로그 - 에러: $e');
      setState(() {
        _error = '코스 목록을 불러오는데 실패했습니다: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.maxFinite,
        height: 400,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${widget.golfClubName} 코스 선택',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadCourses,
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_courses.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('사용 가능한 코스가 없습니다.'),
                ),
              )
            else
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount = constraints.maxWidth > 600 ? 2 : 1;
                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 2.8,
                      ),
                      itemCount: _courses.length,
                      itemBuilder: (context, index) {
                        final course = _courses[index];
                        const isSelected = false;
                        return InkWell(
                          onTap: () {
                            widget.onCourseSelected(course);
                            context.pop();
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.teal[50] : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? Colors.teal : Colors.grey[300]!,
                                width: isSelected ? 2.5 : 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.golf_course, color: Colors.teal[400]),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        course.golfCourseName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${course.holes}홀 · Par ${course.par}',
                                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle, color: Colors.teal, size: 28),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
} 