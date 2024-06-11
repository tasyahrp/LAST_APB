import 'package:flutter/material.dart';
import 'package:flutter_application_1/component/pages/coursedetail.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import '../../Model/Course.dart';


class NearCard extends StatelessWidget {
  final Course course;
  final Position? currentPosition;

  const NearCard({required this.course, this.currentPosition, super.key});

  double _calculateDistance(double startLatitude, double startLongitude, double endLatitude, double endLongitude) {
    return Geolocator.distanceBetween(startLatitude, startLongitude, endLatitude, endLongitude) / 1000;
  }

  @override
  Widget build(BuildContext context) {
    double? distance;
    if (currentPosition != null) {
      distance = _calculateDistance(
        currentPosition!.latitude,
        currentPosition!.longitude,
        course.courseLocation.latitude,
        course.courseLocation.longitude,
      );
    }

    return GestureDetector(
      onTap: () {
        Get.to(
          CourseDetailPage(course: course),
          transition: Transition.native,
          duration: const Duration(milliseconds: 800),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Container(
          height: 210,
          width: 160,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: const Color.fromARGB(255, 207, 205, 205),
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImage(course.courseImageUrl, width: 160),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.courseName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.0,
                        overflow: TextOverflow.clip,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      height: 35.0,
                      child: Text(
                        course.courseDescription,
                        style: const TextStyle(
                          color: Colors.black45,
                          fontSize: 12.0,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.visible,
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (distance != null)
                      Text(
                        '${distance.toStringAsFixed(1)} km away',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String url, {required double width}) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(8),
        topRight: Radius.circular(8),
      ),
      child: url.isEmpty || Uri.tryParse(url)?.hasAbsolutePath != true
          ? Image.asset(
              'assets/image/adminprofile.png',
              height: 100,
              width: width,
              fit: BoxFit.cover,
            )
          : Image.network(
              url,
              height: 100,
              width: width,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  'assets/image/adminprofile.png',
                  height: 100,
                  width: width,
                  fit: BoxFit.cover,
                );
              },
            ),
    );
  }
}
