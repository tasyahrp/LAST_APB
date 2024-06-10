import 'package:cloud_firestore/cloud_firestore.dart';

class Course {
  final String courseId;
  final String courseType;
  final String courseDescription;
  final String courseEmail;
  final GeoPoint courseLocation;
  final String courseName;
  final String coursePhoneNumber;
  final String coursePricing;
  final String courseSubdistrict;
  final String courseAddress;  // New field for course address
  final double courseRating;
  final String ownerId;
  final List<String> courseOpenDays;
  final String courseImageUrl;
  final List<String> syllabi;

  Course({
    required this.courseId,
    required this.courseType,
    required this.courseDescription,
    required this.courseEmail,
    required this.courseLocation,
    required this.courseName,
    required this.coursePhoneNumber,
    required this.coursePricing,
    required this.courseSubdistrict,
    required this.courseAddress,  // Initialize new field
    required this.courseRating,
    required this.ownerId,
    required this.courseOpenDays,
    required this.courseImageUrl,
    required this.syllabi,
  });

  factory Course.fromMap(Map<String, dynamic> data) {
    return Course(
      courseId: data['courseId'] as String? ?? '',
      courseType: data['course_Type'] as String? ?? '',
      courseDescription: data['course_description'] as String? ?? '',
      courseEmail: data['course_email'] as String? ?? '',
      courseLocation: data['course_location'] as GeoPoint? ?? const GeoPoint(0, 0),
      courseName: data['course_name'] as String? ?? '',
      coursePhoneNumber: data['course_phone_number'] as String? ?? '',
      coursePricing: data['course_pricing'] as String? ?? '',
      courseSubdistrict: data['course_subdistrict'] as String? ?? '',
      courseAddress: data['course_address'] as String? ?? '',  // Map new field
       courseRating: (data['course_rating'] is int) 
                  ? (data['course_rating'] as int).toDouble()
                  : (data['course_rating'] as double?) ?? 0.0,
      ownerId: data['ownerId'] as String? ?? '',
      courseOpenDays: List<String>.from(data['course_open_days'] ?? []),
      courseImageUrl: data['course_image_url'] as String? ?? '',
      syllabi: List<String>.from(data['syllabi'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'course_Type': courseType,
      'course_description': courseDescription,
      'course_email': courseEmail,
      'course_location': courseLocation,
      'course_name': courseName,
      'course_phone_number': coursePhoneNumber,
      'course_pricing': coursePricing,
      'course_subdistrict': courseSubdistrict,
      'course_address': courseAddress,  // Add new field to map
      'course_rating': courseRating,
      'ownerId': ownerId,
      'course_open_days': courseOpenDays,
      'course_image_url': courseImageUrl,
      'syllabi': syllabi,
    };
  }
}
