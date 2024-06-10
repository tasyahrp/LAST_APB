import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/component/pages/coursedeletedetail.dart';

class DeleteCoursePage extends StatefulWidget {
  @override
  _DeleteCoursePageState createState() => _DeleteCoursePageState();
}

class _DeleteCoursePageState extends State<DeleteCoursePage> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Your Courses', style: TextStyle(color: Colors.white)),
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
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourseDeleteDetail(courseId: course['courseId']),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        elevation: 5,
        child: Container(
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
