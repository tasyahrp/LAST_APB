import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emailjs/emailjs.dart';

class CourseAdminDetailPage extends StatefulWidget {
  final Map<String, dynamic> course;

  const CourseAdminDetailPage({required this.course, super.key});

  @override
  CourseDetailPageState createState() => CourseDetailPageState();
}

class CourseDetailPageState extends State<CourseAdminDetailPage> {
  bool showNotificationForm = false;
  final TextEditingController notificationTitleController = TextEditingController();
  final TextEditingController notificationMessageController = TextEditingController();

  @override
  void dispose() {
    notificationTitleController.dispose();
    notificationMessageController.dispose();
    super.dispose();
  }

  void _showNotificationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF4A1C6F),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          title: const Text(
            "Notification Sent",
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            "You have notified the owner",
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              child: const Text(
                "OK",
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendNotification() async {
    final courseId = widget.course['courseId'];
    final notificationTitle = notificationTitleController.text;
    final notificationMessage = notificationMessageController.text;

    if (courseId != null) {
      // Create a new notification document
      final notificationDoc = await FirebaseFirestore.instance.collection('Notifications').add({
        'courseId': courseId,
        'title': notificationTitle,
        'message': notificationMessage,
        'timestamp': Timestamp.now(),
      });

      // Get the notification document ID
      final notificationId = notificationDoc.id;

      // Update the Courses collection with the new notification ID
      await FirebaseFirestore.instance.collection('Courses').doc(courseId).update({
        'notifications': FieldValue.arrayUnion([notificationId]),
        'isNeedUpdate': true,
      });

      // Fetch course owner's email
      final courseEmail = widget.course['email'] ?? 'dzakyrazi@gmail.com'; // Default to test email if not found

      // Send email using EmailJS
      await _sendEmail(notificationTitle, notificationMessage, courseEmail, widget.course['title']);

      _showNotificationDialog();
    }
  }

  Future<void> _sendEmail(String title, String message, String toEmail, String toName) async {
    try {
      await EmailJS.send(
        'service_nwhub0c',
        'template_5e4v9ay',
        {
          'to_name': toName, 
          'message': message,
          'to_email': toEmail,
          'title_message': title,
        },
        const Options(
          publicKey: 'KX6uZQI-9h5p3C_DK',
          privateKey: 'n5Fy5aqlXsBQu7PO314v4',
        ),
      );
      print('SUCCESS!');
    } catch (error) {
      if (error is EmailJSResponseStatus) {
        print('ERROR... ${error.status}: ${error.text}');
      }
      print(error.toString());
    }
  }

  Future<String> _fetchOwnerName(String ownerId) async {
    final docSnapshot = await FirebaseFirestore.instance.collection('Users').doc(ownerId).get();
    if (docSnapshot.exists) {
      return docSnapshot.data()?['username'] as String? ?? 'Unknown Owner';
    } else {
      return 'Unknown Owner';
    }
  }

  @override
  Widget build(BuildContext context) {
    print("Course Data2: ${widget.course['schedule']}");
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Course Details', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF4A1C6F),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            FutureBuilder<String>(
              future: _fetchOwnerName(widget.course["ownerId"] ?? ''),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const DetailItem(title: "Owner", value: "Loading...");
                } else if (snapshot.hasError) {
                  return const DetailItem(title: "Owner", value: "Error loading owner name");
                } else {
                  return DetailItem(title: "Owner", value: snapshot.data!);
                }
              },
            ),
            DetailItem(title: "Course ID", value: widget.course["courseId"] ?? ''),
            DetailItem(title: "Course Type", value: widget.course["type"] ?? ''),
            DetailItem(title: "Course Name", value: widget.course["title"] ?? 'kosong'),
            DetailItem(title: "Course Description", value: widget.course["description"] ?? ''),
            DetailItem(title: "Course Email", value: widget.course["email"] ?? ''),
            DetailItem(title: "Course Phone Number", value: widget.course["number"] ?? ''),
            DetailItem(title: "Course Pricing", value: widget.course["pricing"] ?? ''),
            DetailItem(title: "Course Subdistrict", value: widget.course["location"] ?? ''),
            DetailItem(title: "Course Open Days", value: widget.course["schedule"] ?? 'no days available'),
            const SizedBox(height: 16.0),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A1C6F),
              ),
              onPressed: () {
                setState(() {
                  showNotificationForm = true;
                });
              },
              child: const Text('Confirm Course', style: TextStyle(color: Colors.white)),
            ),
            if (showNotificationForm) ...[
              const SizedBox(height: 16.0),
              const Text("Insert Your Notification Info", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8.0),
              TextField(
                controller: notificationTitleController,
                decoration: const InputDecoration(
                  labelText: 'Notification Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8.0),
              TextField(
                controller: notificationMessageController,
                decoration: const InputDecoration(
                  labelText: 'Notification Message',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A1C6F),
                ),
                onPressed: _sendNotification,
                child: const Text('Send Notification', style: TextStyle(color: Colors.white)),
              ),
            ],
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
