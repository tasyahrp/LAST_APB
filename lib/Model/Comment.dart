import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String commentId;
  final String userId;
  final String comment;
  final double rating;
  final String courseId;
  final DateTime timeComment;
  String? username;
  String? profileImageUrl;

  Comment({
    required this.commentId,
    required this.userId,
    required this.comment,
    required this.rating,
    required this.courseId,
    required this.timeComment,
    this.username,
    this.profileImageUrl,
  });

  // Mengonversi dari Map ke Comment
  factory Comment.fromMap(Map<String, dynamic> data) {
    return Comment(
      commentId: data['commentId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      comment: data['comment'] as String? ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      courseId: data['courseId'] as String? ?? '',
      timeComment: (data['timeComment'] as Timestamp?)?.toDate() ?? DateTime.now(),
      username: data['username'] as String?,
      profileImageUrl: data['profile_image_url'] as String?,
    );
  }

  // Mengonversi dari Comment ke Map
  Map<String, dynamic> toMap() {
    return {
      'commentId': commentId,
      'userId': userId,
      'comment': comment,
      'rating': rating,
      'courseId': courseId,
      'timeComment': timeComment,
      'username': username,
      'profile_image_url': profileImageUrl,
    };
  }
}
