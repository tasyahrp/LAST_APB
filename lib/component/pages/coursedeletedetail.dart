import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/component/pages/homepage.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CourseDeleteDetail extends StatefulWidget {
  final String courseId;

  CourseDeleteDetail({required this.courseId});

  @override
  CourseDeleteDetailState createState() => CourseDeleteDetailState();
}

class CourseDeleteDetailState extends State<CourseDeleteDetail> {
  Map<String, dynamic>? course;

  @override
  void initState() {
    super.initState();
    _fetchCourseDetails();
  }

  Future<void> _fetchCourseDetails() async {
    final courseSnapshot = await FirebaseFirestore.instance
        .collection('Courses')
        .doc(widget.courseId)
        .get();
    if (courseSnapshot.exists) {
      setState(() {
        course = courseSnapshot.data();
      });
    }
  }

  Future<void> _deleteCourse() async {
    final courseId = widget.courseId;

    try{
      // 1. Delete comments related to the course
    final commentsQuery = await FirebaseFirestore.instance
        .collection('Comments')
        .where('courseId', isEqualTo: courseId)
        .get();
    for (var commentDoc in commentsQuery.docs) {
      final commentData = commentDoc.data();
      final commentId = commentData['commentId'];

      // Delete comment from comments collection
      await commentDoc.reference.delete();

      // Remove commentId from the course's comments field
      await FirebaseFirestore.instance.collection('Courses').doc(courseId).update({
        'comments': FieldValue.arrayRemove([commentId])
      });

      // Remove commentId from the user's comments field
      final userId = commentData['userId'];
      await FirebaseFirestore.instance.collection('Users').doc(userId).update({
        'comments': FieldValue.arrayRemove([commentId])
      });
    }

    // 2. Delete notifications related to the course
    if (course!['notifications'] != null) {
      for (String notificationId in course!['notifications']) {
        await FirebaseFirestore.instance.collection('Notifications').doc(notificationId).delete();
      }
    }

    // 3. Delete registrants related to the course
    final registrantsQuery = await FirebaseFirestore.instance
        .collection('Registrants')
        .where('course_id', isEqualTo: courseId)
        .get();
    for (var registrantDoc in registrantsQuery.docs) {
      final registrantData = registrantDoc.data();
      final registrantId = registrantData['registrant_id'];
      final registeredBy = registrantData['registered_by'];

      // Delete registrant from registrants collection
      await registrantDoc.reference.delete();

      // Remove registrantId from the user's registrants field
      final userDoc = await FirebaseFirestore.instance.collection('Users').doc(registeredBy).get();
      if (userDoc.exists) {
        await userDoc.reference.update({
          'registrants': FieldValue.arrayRemove([registrantId])
        });
      }
    }

    // 4. Delete syllabus dari kursus yang tersambung
    if (course!['syllabi'] != null) {
      for (String syllabusId in course!['syllabi']) {
        await FirebaseFirestore.instance.collection('Syllabus').doc(syllabusId).delete();
      }
    }

    // 5. Delete course nya sendiri
    await FirebaseFirestore.instance.collection('Courses').doc(courseId).delete();

    // 6. hapus foto di firestorage
    if (course!['course_image_url'] != null) {
    try {
      final ref = FirebaseStorage.instance.refFromURL(course!['course_image_url']);
      await ref.delete();
    } catch (e) {
      print('Error deleting course image: $e');
    }
  }

   // 7. Remove course ID from owner's courses field
  final ownerId = course!['ownerId'];
  await FirebaseFirestore.instance.collection('Users').doc(ownerId).update({
    'courses': FieldValue.arrayRemove([courseId])
  });

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => const Homepage()),
  );   
  
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Course deleted successfully')));
    } catch(e){
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete course: $e')));
    }
  }


  @override
  Widget build(BuildContext context) {
    if (course == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Course Details'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    String formattedDate = DateFormat('dd/MM/yyyy').format((course!['last_updated'] as Timestamp).toDate());

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Course Details', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF4A1C6F),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Course Name : ${course!['course_name']}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black)),
            const SizedBox(height: 8),
             Text(course!['courseId'], style: const TextStyle(fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 16),
            Text(course!['course_Type'], style: const TextStyle(fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 16),
            const Text('Email:', style:  TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(course!['course_email'], style: const TextStyle(fontSize: 14, color: Colors.black87)),
            const SizedBox(height: 16),
            const Text('Phone Number:', style:  TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(course!['course_phone_number'], style: const TextStyle(fontSize: 14, color: Colors.black87)),
            const SizedBox(height: 16),
            const Text('Address:', style:  TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(course!['course_address'], style: const TextStyle(fontSize: 14, color: Colors.black87)),
            const SizedBox(height: 16),
            const Text('Subdistrict:', style:  TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(course!['course_subdistrict'], style: const TextStyle(fontSize: 14, color: Colors.black87)),
            const SizedBox(height: 16),
            const Text('Pricing:', style:  TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(course!['course_pricing'].toString(), style: const TextStyle(fontSize: 14, color: Colors.black87)),
            const SizedBox(height: 16),
            const Text('Description:', style:  TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(course!['course_description'], style: const TextStyle(fontSize: 14, color: Colors.black87)),
            const SizedBox(height: 16),
            const Text('Last Updated:', style:  TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(formattedDate, style: const TextStyle(fontSize: 14, color: Colors.black87)),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: _deleteCourse,
                style: ElevatedButton.styleFrom(
                 backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: const Text('Delete Course', style: TextStyle(color: Colors.white),),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
