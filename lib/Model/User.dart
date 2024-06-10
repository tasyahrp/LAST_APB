import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final List<String> courses;
  final List<String> registrants; // Added registrants field
  final String email;
  final bool isRequestOwner;
  final String password;
  final String phoneNumber;
  final DateTime requestBecomeOwner;
  final String role;
  final String uid;
  final String username;
  final String profileImageUrl;

  User({
    required this.courses,
    required this.registrants, // Added registrants field in constructor
    required this.email,
    required this.isRequestOwner,
    required this.password,
    required this.phoneNumber,
    required this.requestBecomeOwner,
    required this.role,
    required this.uid,
    required this.username,
    required this.profileImageUrl,
  });

  factory User.fromMap(Map<String, dynamic> data) {
    return User(
      courses: List<String>.from(data['courses'] ?? []),
      registrants: List<String>.from(data['registrants'] ?? []), // Initialize registrants field
      email: data['email'] as String? ?? '',
      isRequestOwner: data['isRequestOwner'] as bool? ?? false,
      password: data['password'] as String? ?? '',
      phoneNumber: data['phone_number'] as String? ?? '',
      requestBecomeOwner: (data['requestbecomeowner'] as Timestamp?)?.toDate() ?? DateTime.now(),
      role: data['role'] as String? ?? '',
      uid: data['uid'] as String? ?? '',
      username: data['username'] as String? ?? '',
      profileImageUrl: data['profile_image_url'] as String? ?? "",
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courses': courses,
      'registrants': registrants, // Add registrants to the map
      'email': email,
      'isRequestOwner': isRequestOwner,
      'password': password,
      'phone_number': phoneNumber,
      'requestbecomeowner': requestBecomeOwner,
      'role': role,
      'uid': uid,
      'username': username,
      'profile_image_url': profileImageUrl,
    };
  }
}
