import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Model/Owner.dart';
import 'deletedetailadmin.dart';
import 'package:firebase_storage/firebase_storage.dart';

class DeleteRole extends StatefulWidget {
  const DeleteRole({super.key});

  @override
  State<DeleteRole> createState() => _DeleteRoleState();
}

class _DeleteRoleState extends State<DeleteRole> {
  List<Owner> owners = [];

  void _fetchOwners() async {
    final ownerDocs = await FirebaseFirestore.instance
        .collection('Users')
        .where('role', isEqualTo: 'Owner Course')
        .get();

    final ownerData = ownerDocs.docs.map((doc) => {
          ...doc.data(),
          'docId': doc.id, // Add docId to the data map
        }).toList();

    final owners = ownerData.map((owner) async {
      final coursesRef = await FirebaseFirestore.instance
          .collection('Courses')
          .where('ownerId', isEqualTo: owner['uid'])
          .get();

      final coursesData = coursesRef.docs.map((doc) => doc.data()).toList();

      return Owner(
        name: owner['username']?.toString() ?? '',
        email: owner['email'] as String,
        courses: coursesData,
        docId: owner['docId'] as String, // Use docId from the map
      );
    }).toList();

    final resolvedOwners = await Future.wait(owners.map((e) => e).toList()); // Wait for all futures
    setState(() {
      this.owners = resolvedOwners.cast<Owner>();
    });
  }

  Future<void> _downPrivilage(String docId) async {
    try {
      // Update the users role to 'Student' and delete their courses field
      await FirebaseFirestore.instance.collection('Users').doc(docId).update({
        'role': 'Student',
        'courses': FieldValue.delete(), 
        'requestbecomeowner': FieldValue.delete(), 
        'isDownPrivilage': true, // Mark
      });

      // Fetch the courses owned by the user
      final courseQuery = FirebaseFirestore.instance
          .collection('Courses')
          .where('ownerId', isEqualTo: docId);

      // safe semua field disini
      final querySnapshot = await courseQuery.get();

      // loop cek semua field & tangkap untuk kebutuhan penghapusan di relasi
      for (var courseDoc in querySnapshot.docs) {
        final courseId = courseDoc.id;
        final courseData = courseDoc.data();
        final courseImageUrl = courseData['course_image_url'] as String?;
        final registrants = courseData['registrants'] as List<dynamic>? ?? [];
        final comments = courseData['comments'] as List<dynamic>? ?? [];
        final notifications = courseData['notifications'] as List<dynamic>? ?? [];
        final syllabi = courseData['syllabi'] as List<dynamic>? ?? [];

       // 1. Relasi Kursus removed
      for (var registrantId in registrants) {
        final registrantDoc = await FirebaseFirestore.instance.collection('Registrants').doc(registrantId).get();
        if (registrantDoc.exists) {
          final registrantData = registrantDoc.data();
          final registeredBy = registrantData?['registered_by'];
          if (registeredBy != null) {
            final userDoc = await FirebaseFirestore.instance.collection('Users').doc(registeredBy).get();
            if (userDoc.exists) {
              final userData = userDoc.data();
              if (userData != null) {
                List<dynamic> userRegistrants = userData['registrants'] ?? [];
                userRegistrants.remove(registrantId);

                await FirebaseFirestore.instance.collection('Users').doc(registeredBy).update({
                  'registrants': userRegistrants,
                });
              }
            }
          }
        }
      }
        // 2. Fetch and delete associated registrants in the 'Registrants' collection
        final registrantQuery = FirebaseFirestore.instance
            .collection('Registrants')
            .where('course_id', isEqualTo: courseId);

        final registrantSnapshot = await registrantQuery.get();
        for (var registrantDoc in registrantSnapshot.docs) {
          await registrantDoc.reference.delete();
        }

        // 3. Fetch and delete associated syllabi in the 'Syllabus' collection
        for (var syllabusId in syllabi) {
        final syllabusDoc = await FirebaseFirestore.instance.collection('Syllabus').doc(syllabusId).get();
        if (syllabusDoc.exists) {
          await syllabusDoc.reference.delete();
        }
      }

        // 4. Delete associated comments in the 'Comments' collection
      for (var commentId in comments) {
        final commentDoc = await FirebaseFirestore.instance.collection('Comments').doc(commentId).get();
        if (commentDoc.exists) {
          final commentData = commentDoc.data();
          final userId = commentData?['userId'];
          if (userId != null) {
            final userDoc = await FirebaseFirestore.instance.collection('Users').doc(userId).get();
            if (userDoc.exists) {
              final userData = userDoc.data();
              if (userData != null) {
                List<dynamic> userComments = userData['comments'] ?? [];
                userComments.remove(commentId);

                await FirebaseFirestore.instance.collection('Users').doc(userId).update({
                  'comments': userComments,
                });
              }
            }
          }
          await commentDoc.reference.delete();
        }
      }


      // 5. Delete associated notifications in the 'Notifications' collection
      for (var notificationId in notifications) {
        final notificationDoc = await FirebaseFirestore.instance.collection('Notifications').doc(notificationId).get();
        if (notificationDoc.exists) {
          await notificationDoc.reference.delete();
        }
      }

        // 6. Delete  course document
        await courseDoc.reference.delete();

        // 7. Delete course image from Firebase Storage 
        if (courseImageUrl != null && courseImageUrl.isNotEmpty) {
          try {
            final Reference imageRef = FirebaseStorage.instance.refFromURL(courseImageUrl);
            await imageRef.delete();
          } catch (e) {
            print('Error deleting course image: $e');
          }
        }
      }
      // Refresh the list after deletion
      _fetchOwners();
    } catch (e) {
      print('Error deleting owner: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchOwners(); // Fetch data on widget initialization
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Owner List',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF4A1C6F),
      ),
      body: owners.isEmpty
          ? Center(
              child: Text(
                'Tidak ada owner yang terdaftar',
                style: TextStyle(fontSize: 18.0, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: owners.length,
              itemBuilder: (context, index) {
                final owner = owners[index]; // Get the current owner object
                return OwnerCard(
                  name: owner.name,
                  company: owner.courses.map((course) => course['course_name'] as String).toList(),
                  email: owner.email,
                  onDelete: () => _downPrivilage(owner.docId), // Pass delete function
                  onDetails: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OwnerDetailsPage(owner: owner),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class OwnerCard extends StatelessWidget {
  final String name;
  final List<String> company;
  final String email;
  final VoidCallback onDelete;
  final VoidCallback onDetails;

  const OwnerCard({
    required this.name,
    required this.company,
    required this.email,
    required this.onDelete,
    required this.onDetails,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade700,
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.0,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        company.join(', '),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14.0,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        email,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: onDelete,
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                TextButton(
                  onPressed: onDetails,
                  child: const Text('Detail'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
