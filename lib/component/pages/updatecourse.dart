import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'updateformpage.dart';
import '../../Model/Syllabus.dart';

class UpdateCoursePage extends StatefulWidget {
  @override
  _UpdateCoursePageState createState() => _UpdateCoursePageState();
}

class _UpdateCoursePageState extends State<UpdateCoursePage> {
  List<Map<String, dynamic>> userCourses = [];

  @override
  void initState() {
    super.initState();
    _fetchOwnedCourses();
  }

  Future<void> _fetchOwnedCourses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .get();
      if (docSnapshot.exists) {
        final userData = docSnapshot.data()!;
        if (userData.containsKey('courses')) {
          final courseIds = List<String>.from(userData['courses']);
          List<Map<String, dynamic>> courses = [];
          for (var courseId in courseIds) {
            final courseSnapshot = await FirebaseFirestore.instance
                .collection('Courses')
                .doc(courseId)
                .get();
            if (courseSnapshot.exists) {
              final courseData = courseSnapshot.data()!;
              final syllabi = await _fetchSyllabi(courseId);
              final syllabusCount = syllabi.length;
              final topicCount = syllabi.fold<int>(
                0,
                (sum, syllabus) => sum + syllabus.syllabusMeetings,
              );

              courseData['course_syllabus_count'] = syllabusCount;
              courseData['course_topic_count'] = topicCount;
              courses.add(courseData);
            }
          }
          setState(() {
            userCourses = courses;
          });
        }
      }
    }
  }

  Future<List<Syllabus>> _fetchSyllabi(String courseId) async {
    final syllabusQuerySnapshot = await FirebaseFirestore.instance
        .collection('Syllabus')
        .where('courseId', isEqualTo: courseId)
        .get();
    return syllabusQuerySnapshot.docs.map((doc) => Syllabus.fromMap(doc.data())).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Your Course', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF4A1C6F),
      ),
      body: ListView.builder(
        itemCount: userCourses.length,
        itemBuilder: (context, index) {
          final course = userCourses[index];
          return _buildCourseCard(context, course);
        },
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, Map<String, dynamic> course) {
    String formattedDate = DateFormat('dd/MM/yyyy').format((course['last_updated'] as Timestamp).toDate());

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourseUpdateFormPage(courseId: course['courseId']),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        elevation: 5,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4A1C6F), Color(0xFF9C27B0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(course['course_name'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(course['course_Type'], style: const TextStyle(fontSize: 14, color: Color.fromARGB(225, 255, 255, 255))),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Syllabus:', style: TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.bold)),
                            Text('${course['course_syllabus_count']}', style: const TextStyle(fontSize: 14, color: Colors.white70)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Topics:', style: TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.bold)),
                            Text('${course['course_topic_count']}', style: const TextStyle(fontSize: 14, color: Colors.white70)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Last Update:', style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold)),
                            Text(formattedDate, style: const TextStyle(fontSize: 14, color: Colors.white)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (course['isNeedUpdate'] == true)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 44, 0, 80),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(15.0),
                      bottomLeft: Radius.circular(10.0),
                    ),
                  ),
                  child: const Text(
                    'Update!',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
