import 'package:cloud_firestore/cloud_firestore.dart';

class Notification {
  final String courseId;
  final String message;
  final DateTime timestamp;
  final String title;

  Notification({
    required this.courseId,
    required this.message,
    required this.timestamp,
    required this.title,
  });

  factory Notification.fromMap(Map<String, dynamic> data) {
    return Notification(
      courseId: data['courseId'] as String,
      message: data['message'] as String,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      title: data['title'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'title': title,
    };
  }
}
