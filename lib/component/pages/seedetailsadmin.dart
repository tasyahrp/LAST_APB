import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Model/User.dart';
import '../../Model/Course.dart';
import 'package:intl/intl.dart';

class SeeDetailsPage extends StatelessWidget {
  final User applicant;

  const SeeDetailsPage({required this.applicant, super.key});

  Future<void> _approveApplicant(String docId, BuildContext context) async {
    // Update user information (approve to course owner)
    await FirebaseFirestore.instance.collection('Users').doc(docId).update({
      'isRequestOwner': false, // Set request owner to false
      'role': 'Owner Course', // Set role to "Owner Course"
      'registrants': FieldValue.delete(),
    });
    Navigator.of(context).pop(); // Navigate back to the previous screen
  }

  Future<List<Course>> _fetchCourses(List<String> courseIds) async {
    final courses = <Course>[];
    for (var courseId in courseIds) {
      final docSnapshot = await FirebaseFirestore.instance.collection('Courses').doc(courseId).get();
      if (docSnapshot.exists) {
        courses.add(Course.fromMap(docSnapshot.data()!));
      }
    }
    return courses;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Applicant Details', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF4A1C6F),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const SizedBox(height: 16.0),
            const Text("Person information", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 21.0)),
            const SizedBox(height: 16.0),
            DetailItem(title: "Username", value: applicant.username),
            DetailItem(title: "Email", value: applicant.email),
            DetailItem(title: "Phone Number", value: applicant.phoneNumber),
            DetailItem(title: "Requested On", value: DateFormat('dd-MM-yyyy').format(applicant.requestBecomeOwner)),
            const SizedBox(height: 16.0),
            const Text("Courses information", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 21.0)),
            const SizedBox(height: 16.0),
            FutureBuilder<List<Course>>(
              future: _fetchCourses(applicant.courses),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Text('Error fetching courses');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('No courses found');
                } else {
                  return Column(
                    children: snapshot.data!.map((course) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DetailItem(title: "Course Name", value: course.courseName),
                          DetailItem(title: "Course Type", value: course.courseType),
                          DetailItem(title: "Description", value: course.courseDescription),
                          DetailItem(title: "Email", value: course.courseEmail),
                          DetailItem(title: "Phone Number", value: course.coursePhoneNumber),
                          DetailItem(title: "Subdistrict", value: course.courseSubdistrict),
                        ],
                      );
                    }).toList(),
                  );
                }
              },
            ),
            const SizedBox(height: 12.0),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A1C6F), // background color
              ),
              onPressed: () {
                _approveApplicant(applicant.uid, context);
              },
              child: const Text('Approve', style: TextStyle(color: Colors.white, fontSize: 16.0),),
            ),
          ],
        ),
      ),
    );
  }
}

class DetailItem extends StatelessWidget {
  final String title;
  final String value;

  const DetailItem({required this.title, required this.value, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 4.0),
          Text(value),
          const Divider(color: Colors.grey),
        ],
      ),
    );
  }
}
