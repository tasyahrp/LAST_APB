import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Model/Course.dart';
import 'coursedetail.dart';

class EnglishCoursesPage extends StatefulWidget {
  const EnglishCoursesPage({super.key});

  @override
  _EnglishCoursesPageState createState() => _EnglishCoursesPageState();
}

class _EnglishCoursesPageState extends State<EnglishCoursesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('English Course', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF4A1C6F),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Find by location, name',
                hintStyle: const  TextStyle(fontSize: 14.0),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(60),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Courses')
                    .where('course_Type', isEqualTo: 'English')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final courses = snapshot.data!.docs
                      .map((doc) => Course.fromMap(doc.data() as Map<String, dynamic>))
                      .where((course) =>
                          course.courseName.toLowerCase().contains(_searchQuery) ||
                          course.courseSubdistrict.toLowerCase().contains(_searchQuery))
                      .toList();
                  return ListView.builder(
                    itemCount: courses.length,
                    itemBuilder: (context, index) {
                      return _buildCourseItem(context, courses[index]);
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

  Widget _buildCourseItem(BuildContext context, Course course) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CourseDetailPage(course: course),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: course.courseImageUrl.isNotEmpty
                    ? Image.network(
                        course.courseImageUrl,
                        height: 80,
                        width: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/image/adminprofile.png', // Add a placeholder image in your assets
                            height: 80,
                            width: 80,
                            fit: BoxFit.cover,
                          );
                        },
                      )
                    : Image.asset(
                        'assets/image/adminprofile.png', // Add a placeholder image in your assets
                        height: 80,
                        width: 80,
                        fit: BoxFit.cover,
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.courseName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(course.courseSubdistrict),
                    Text(_abbreviateCourseOpenDays(course.courseOpenDays)),
                    Text(course.coursePricing),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        Text(course.courseRating.toString()),
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

  String _abbreviateCourseOpenDays(List<String> days) {
    if (days.isEmpty) return '';

    const daysOfWeek = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];

    final dayIndices = days.map((day) => daysOfWeek.indexOf(day)).toList();
    dayIndices.sort();

    if (dayIndices.length == 7) {
      return 'Everyday';
    }

    final ranges = <String>[];
    var rangeStart = dayIndices.first;
    var previousDay = dayIndices.first;

    for (var i = 1; i < dayIndices.length; i++) {
      if (dayIndices[i] != previousDay + 1) {
        ranges.add(_formatRange(rangeStart, previousDay, daysOfWeek));
        rangeStart = dayIndices[i];
      }
      previousDay = dayIndices[i];
    }
    ranges.add(_formatRange(rangeStart, previousDay, daysOfWeek));

    return ranges.join(', ');
  }

  String _formatRange(int start, int end, List<String> daysOfWeek) {
    if (start == end) {
      return daysOfWeek[start];
    }
    return '${daysOfWeek[start]} - ${daysOfWeek[end]}';
  }
}
