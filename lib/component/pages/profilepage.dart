import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_application_1/component/pages/deletecourse.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'dart:io';
import '../../Model/Course.dart';
import '../../Model/User.dart' as model;
import '../../Model/Notification.dart' as custom; // Import the custom Notification model
import 'addcourse.dart';
import 'loginpage.dart';
import 'personalinfo.dart';
import 'coursedetail.dart';
import 'requestowner.dart';
import 'updatecourse.dart';
import 'notificationpage.dart'; // Import Notification Page

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  model.User? currentUser;
  List<Course> userCourses = [];
  List<custom.Notification> notifications = []; // Use the custom Notification model
  final _profileImageFile = ValueNotifier<File?>(null);
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  
  Future<void> _fetchUserData() async {
    await Firebase.initializeApp();

    final firebaseUser = auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      try {
        final docSnapshot = await FirebaseFirestore.instance
            .collection('Users')
            .doc(firebaseUser.uid)
            .get();

        if (docSnapshot.exists) {
          final userData = model.User.fromMap(docSnapshot.data()!);
          setState(() {
            currentUser = userData;
          });
          if (currentUser!.role == 'Owner Course') {
            await _fetchOwnedCourses(currentUser!.uid); // Fetch owned courses
            await _fetchNotifications(currentUser!.uid); // Fetch notifications for owner
          } else if (currentUser!.role == 'Student') {
            await _fetchRegisteredCourses(currentUser!.registrants); // Fetch registered courses for student
          }
        } else {
          print('User document not found');
        }
      } on FirebaseException catch (e) {
        print('Error fetching user data: $e');
      }
    } else {
      print('No signed-in user found');
    }
  }

  Future<void> _fetchOwnedCourses(String ownerId) async {
    List<Course> courses = [];

    try {
      final userDoc = await FirebaseFirestore.instance.collection('Users').doc(ownerId).get();
      if (userDoc.exists) {
        final ownedCourses = userDoc.data()?['courses'] as List<dynamic>? ?? [];
        for (var courseId in ownedCourses) {
          final courseDoc = await FirebaseFirestore.instance.collection('Courses').doc(courseId).get();
          if (courseDoc.exists) {
            courses.add(Course.fromMap(courseDoc.data()!));
          } else {
            print('Course document not found for ID: $courseId');
          }
        }
      } else {
        print('User document not found for ID: $ownerId');
      }
    } on FirebaseException catch (e) {
      print('Error fetching owned courses: $e');
    } catch (e) {
      print('Unknown error fetching owned courses: $e');
    }

    setState(() {
      userCourses = courses;
    });
  }

  Future<void> _fetchRegisteredCourses(List<String> registrantIds) async {
    List<Course> courses = [];

    for (var registrantId in registrantIds) {
      try {
        final registrantDoc = await FirebaseFirestore.instance.collection('Registrants').doc(registrantId).get();
        if (registrantDoc.exists) {
          final courseId = registrantDoc.data()!['course_id'];
          final courseDoc = await FirebaseFirestore.instance.collection('Courses').doc(courseId).get();
          if (courseDoc.exists) {
            courses.add(Course.fromMap(courseDoc.data()!));
          }
        }
      } on FirebaseException catch (e) {
        print('Error fetching registered course data: $e');
      }
    }

    setState(() {
      userCourses = courses;
    });
  }

  Future<void> _fetchNotifications(String ownerId) async {
    List<custom.Notification> fetchedNotifications = [];
    try {
      final userDoc = await FirebaseFirestore.instance.collection('Users').doc(ownerId).get();
      if (userDoc.exists) {
        final ownedCourses = userDoc.data()?['courses'] as List<dynamic>? ?? [];
        for (var courseId in ownedCourses) {
          final courseDoc = await FirebaseFirestore.instance.collection('Courses').doc(courseId).get();
          if (courseDoc.exists) {
            final notificationsField = courseDoc.data()?['notifications'] as List<dynamic>?;
            if (notificationsField != null) {
              for (var notificationId in notificationsField) {
                final notificationDoc = await FirebaseFirestore.instance.collection('Notifications').doc(notificationId).get();
                if (notificationDoc.exists) {
                  fetchedNotifications.add(custom.Notification.fromMap(notificationDoc.data()!));
                }
              }
            }
          }
        }
      }
    } on FirebaseException catch (e) {
      print('Error fetching notifications: $e');
    }

    setState(() {
      notifications = fetchedNotifications;
    });
  }

  Future<void> _changeProfileImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final File imageFile = File(pickedFile.path);
      _profileImageFile.value = imageFile;
    }
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            color: Colors.black,
            child: PhotoView(
              imageProvider: NetworkImage(imageUrl),
              backgroundDecoration: BoxDecoration(color: Colors.black),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String appBarTitle;
    if (currentUser?.role == 'Owner Course') {
      appBarTitle = 'Owner Profile';
    } else if (currentUser?.role == 'Student') {
      appBarTitle = 'Student Profile';
    } else {
      appBarTitle = 'My Profile';
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          appBarTitle,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF4A1C6F),
        actions: [
          if (notifications.isNotEmpty)
            IconButton(
              icon: Stack(
                children: [
                  const Icon(Icons.notifications, size: 24, color: Colors.white),
                  if (notifications.isNotEmpty)
                    Positioned(
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 12,
                          minHeight: 12,
                        ),
                        child: Text(
                          '${notifications.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotificationPage(notifications: notifications),
                  ),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (_profileImageFile.value != null) {
                        _showImageDialog(_profileImageFile.value!.path);
                      } else if (currentUser != null && currentUser!.profileImageUrl.isNotEmpty) {
                        _showImageDialog(currentUser!.profileImageUrl);
                      }
                    },
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: ValueListenableBuilder<File?>(
                        valueListenable: _profileImageFile,
                        builder: (context, profileImageFile, child) {
                          if (profileImageFile != null) {
                            return ClipOval(
                              child: Image.file(
                                profileImageFile,
                                fit: BoxFit.cover,
                              ),
                            );
                          } else if (currentUser != null && currentUser!.profileImageUrl.isNotEmpty) {
                            return ClipOval(
                              child: Image.network(
                                currentUser!.profileImageUrl,
                                fit: BoxFit.cover,
                              ),
                            );
                          } else {
                            return const Icon(
                              Icons.account_circle,
                              size: 80,
                              color: Colors.grey,
                            );
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentUser?.username ?? '',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                       Text(
                        currentUser?.role ?? '',
                        style: const TextStyle(fontSize: 12, color: Colors.black54 ,fontWeight: FontWeight.w600),
                      ),
                      Text(
                        currentUser?.email ?? '',
                        style: const TextStyle(fontSize: 12,color: Colors.black54, fontWeight: FontWeight.w600),
                      ),
                     
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Your Course',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: userCourses.map((course) => _buildCourseCard(course)).toList(),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Find More',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12.0,
                runSpacing: 2.0,
                children: [
                  _buildListTile(
                    icon: Icons.person,
                    title: 'Personal Information',
                    onTap: () {
                      Get.to(
                        const PersonalInfoPage(),
                        transition: Transition.rightToLeft,
                        duration: const Duration(milliseconds: 800),
                      );
                    },
                  ),
                  if (currentUser?.role != 'Owner Course' && currentUser?.isRequestOwner == false)
                    _buildListTile(
                      icon: Icons.people,
                      title: 'Request Become Owner',
                      onTap: () {
                        Get.to(
                          const RequestOwnerPage(),
                          transition: Transition.downToUp,
                          duration: const Duration(milliseconds: 800),
                        );
                      },
                    ),
                  if (currentUser?.role == 'Owner Course')
                    _buildListTile(
                      icon: Icons.bookmark_add,
                      title: 'Add More Course',
                      onTap: () {
                        Get.to(
                          const AddCourse(),
                          transition: Transition.downToUp,
                          duration: const Duration(milliseconds: 800),
                        );
                      },
                    ),
                  if (currentUser?.role == 'Owner Course')
                    _buildListTile(
                      icon: Icons.edit_document,
                      title: 'Update Course',
                      onTap: () {
                        Get.to(
                          UpdateCoursePage(),
                          transition: Transition.native,
                          duration: const Duration(milliseconds: 800),
                        );
                      },
                    ),
                    if (currentUser?.role == 'Owner Course')
                    _buildListTile(
                      icon: Icons.delete_forever,
                      title: 'Delete Your Course',
                      onTap: () {
                        Get.to(
                          DeleteCoursePage(),
                          transition: Transition.native,
                          duration: const Duration(milliseconds: 800),
                        );
                      },
                    ),
                  _buildListTile(
                    icon: Icons.logout,
                    title: 'Log Out',
                    onTap: () {
                      _showLogoutConfirmationDialog(context);
                    },
                  ),
                  const SizedBox(height: 60.0),
                  if (currentUser?.role != 'Owner Course' && currentUser?.isRequestOwner == true)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.timelapse,
                            size: 120.0,
                            color: Colors.grey,
                          ),
                          Text(
                            "Your Registration on Checking",
                            style: TextStyle(color: Colors.grey, fontSize: 21.0),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCard(Course course) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourseDetailPage(course: course),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4.0),
            border: Border.all(
              color: const Color.fromARGB(255, 207, 205, 205),
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              course.courseImageUrl.isNotEmpty
                  ? Image.network(
                      course.courseImageUrl,
                      height: 100,
                      fit: BoxFit.cover,
                      width: 160,
                    )
                  : const Icon(
                      Icons.book,
                      size: 100,
                      color: Colors.grey,
                    ),
              const SizedBox(height: 5),
              Center(
                child: Text(
                  course.courseName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Center(
                child: Text(
                  course.courseEmail,
                  style: const TextStyle(fontWeight: FontWeight.w600 ,fontSize: 11.0,color: Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required Function() onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Are you sure?'),
          content: const Text('Do you want to log out?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () async {
                Navigator.of(context).pop();
                Get.offAll(
                  () => const LoginRegisterScreen(),
                  transition: Transition.leftToRight,
                  duration: const Duration(milliseconds: 500),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
