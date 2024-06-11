import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'englishpage.dart';
import 'programmingpage.dart';
import 'coursedetail.dart';
import '../../Model/Course.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(const MaterialApp(home: CoursePage()));

class CoursePage extends StatefulWidget {
  const CoursePage({super.key});

  @override
  CoursePageState createState() => CoursePageState();
}

class CoursePageState extends State<CoursePage> {
  List<Course> likedCourses = [];
  List<Course> nearbyCourses = [];
  Position? _currentPosition;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchLikedCourses();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> fetchLikedCourses() async {
    try {
      final coursesQuerySnapshot = await FirebaseFirestore.instance.collection('Courses').get();

      List<Course> validCourses = [];

      for (var courseDoc in coursesQuerySnapshot.docs) {
        final ownerId = courseDoc['ownerId'];
        final ownerDoc = await FirebaseFirestore.instance.collection('Users').doc(ownerId).get();

        if (ownerDoc.exists && ownerDoc['role'] == 'Owner Course') {
          final course = Course.fromMap(courseDoc.data());
          if (course.courseRating > 2.4) {
            validCourses.add(course);
          }
        }
      }

      // Sort the valid courses based on rating
      validCourses.sort((a, b) => b.courseRating.compareTo(a.courseRating));

      // Take the top 4 courses based on rating
      if (mounted) {
        setState(() {
          likedCourses = validCourses.take(4).toList();
        });
      }
    } catch (e) {
      Text('Error fetching courses: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      try {
        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        if (mounted) {
          setState(() {
            _currentPosition = position;
          });
        }
        fetchNearbyCourses();
      } catch (e) {
        Text('Error getting location: $e');
      }
    } else {
      const Text('Location permission denied');
    }
  }

  Future<void> fetchNearbyCourses() async {
    if (_currentPosition == null) return;

    try {
      final coursesQuerySnapshot = await FirebaseFirestore.instance.collection('Courses').get();

      List<Course> validCourses = [];

      for (var courseDoc in coursesQuerySnapshot.docs) {
        final ownerId = courseDoc['ownerId'];
        final ownerDoc = await FirebaseFirestore.instance.collection('Users').doc(ownerId).get();

        if (ownerDoc.exists && ownerDoc['role'] == 'Owner Course') {
          final course = Course.fromMap(courseDoc.data());
          validCourses.add(course);
        }
      }

      validCourses.sort((a, b) {
        double distanceA = _calculateDistance(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          a.courseLocation.latitude,
          a.courseLocation.longitude,
        );
        double distanceB = _calculateDistance(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          b.courseLocation.latitude,
          b.courseLocation.longitude,
        );
        return distanceA.compareTo(distanceB);
      });

      if (mounted) {
        setState(() {
          nearbyCourses = validCourses;
        });
      }
    } catch (e) {
      Text('Error fetching nearby courses: $e');
    }
  }

  double _calculateDistance(double startLatitude, double startLongitude, double endLatitude, double endLongitude) {
    return Geolocator.distanceBetween(startLatitude, startLongitude, endLatitude, endLongitude) / 1000;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Courses',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF4A1C6F),
      ),
      body: isLoading
          ?  const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageCard(
                      context: context,
                      imagePath: 'assets/image/english.png',
                      label: 'Bahasa Inggris',
                      gradientColors: [Colors.pink.shade100, Colors.pink.shade300],
                      imageAlignment: Alignment.bottomRight,
                      navigateTo: const EnglishCoursesPage(),
                      textColor: const Color(0xFF4A1C6F),
                    ),
                    const SizedBox(height: 10),
                    _buildImageCard(
                      context: context,
                      imagePath: 'assets/image/programming.png',
                      label: 'Pemrograman',
                      gradientColors: [Colors.purple.shade100, Colors.purple.shade300],
                      imageAlignment: Alignment.bottomLeft,
                      navigateTo: const ProgrammingCoursesPage(),
                      textColor: const Color(0xFF4A1C6F),
                    ),
                    const SizedBox(height: 20),
                    RecommendedCourses(likedCourses: likedCourses),
                    const SizedBox(height: 20),
                    NearbyCourses(nearbyCourses: nearbyCourses, currentPosition: _currentPosition),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImageCard({
    required BuildContext context,
    required String imagePath,
    required String label,
    required List<Color> gradientColors,
    required Alignment imageAlignment,
    required Widget navigateTo,
    required Color textColor,
  }) {
    return GestureDetector(
      onTap: () {
        Get.to(
          navigateTo,
          transition: Transition.cupertinoDialog,
          duration: const Duration(milliseconds: 800),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        height: 120,
        child: Stack(
          children: [
            Align(
              alignment: imageAlignment,
              child: SizedBox(
                width: 195,
                height: 120,
                child: FittedBox(
                  fit: BoxFit.contain,
                  alignment: imageAlignment,
                  child: Image.asset(imagePath),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: imageAlignment == Alignment.bottomLeft
                    ? Alignment.topRight
                    : Alignment.topLeft,
                child: Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RecommendedCourses extends StatelessWidget {
  final List<Course> likedCourses;

  const RecommendedCourses({required this.likedCourses, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recommended for You',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        if (likedCourses.isEmpty)
          Container(
            height: 100,
            alignment: Alignment.center,
            child: const Text('No courses available', style: TextStyle(fontSize: 16.0, color: Colors.grey)),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: likedCourses.map((course) => _buildCourseCard(course)).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildCourseCard(Course course) {
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
          height: 230,
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
                    Text(
                      course.courseType,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 12.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      height: 35.0,
                      child: Text(
                        course.courseDescription,
                        style: const TextStyle(
                          color: Colors.black45,
                          fontSize: 11.0,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.visible,
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        Text(course.courseRating.toStringAsFixed(1)),
                      ],
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

class NearbyCourses extends StatelessWidget {
  final List<Course> nearbyCourses;
  final Position? currentPosition;

  const NearbyCourses({required this.nearbyCourses, this.currentPosition, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Courses in Your Area',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        if (nearbyCourses.isEmpty)
          Container(
            height: 100,
            alignment: Alignment.center,
            child: const Text('No courses available', style: TextStyle(fontSize: 16.0, color: Colors.grey)),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: nearbyCourses.map((course) => buildNearCard(course)).toList(),
            ),
          ),
      ],
    );
  }

  Widget buildNearCard(Course course) {
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

  double _calculateDistance(double startLatitude, double startLongitude, double endLatitude, double endLongitude) {
    return Geolocator.distanceBetween(startLatitude, startLongitude, endLatitude, endLongitude) / 1000;
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
