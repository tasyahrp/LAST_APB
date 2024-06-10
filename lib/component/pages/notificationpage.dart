import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../Model/Notification.dart' as custom; // Use the custom Notification model

class NotificationPage extends StatelessWidget {
  final List<custom.Notification> notifications;

  const NotificationPage({Key? key, required this.notifications}) : super(key: key);

  Future<String> _fetchCourseName(String courseId) async {
    final courseDoc = await FirebaseFirestore.instance.collection('Courses').doc(courseId).get();
    if (courseDoc.exists) {
      return courseDoc.data()?['course_name'] ?? 'Unknown Course';
    } else {
      return 'Unknown Course';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Notifications', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF4A1C6F),
      ),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return FutureBuilder<String>(
            future: _fetchCourseName(notification.courseId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ListTile(
                  title: Text('Loading...'),
                  subtitle: Text('Loading...'),
                );
              } else if (snapshot.hasError) {
                return const ListTile(
                  title: Text('Error'),
                  subtitle: Text('Failed to load course name'),
                );
              } else {
                final courseName = snapshot.data!;
                final timeAgo = timeago.format(notification.timestamp);
                return ListTile(
                  title: Text(courseName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(notification.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(notification.message),
                    ],
                  ),
                  trailing: Text(timeAgo),
                );
              }
            },
          );
        },
      ),
    );
  }
}
