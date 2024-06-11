import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_application_1/component/fragments/notificationdialog.dart';
import 'package:get/get.dart'; // Import Get package
import 'package:flutter_application_1/component/fragments/google_navbar.dart';
import 'package:flutter_application_1/component/pages/coursepage.dart';
import 'package:flutter_application_1/component/pages/profilepage.dart';
import 'package:flutter_application_1/component/pages/coursedetail.dart';
import '../../Model/Course.dart';
import 'searchpage.dart';
import '../fragments/carouselcard.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});
  
  @override
  HomepageState createState() => HomepageState();
}

class HomepageState extends State<Homepage> {
  int _selectedIndex = 0;
  String _selectedCategory = 'Programming';
  String? myusername;
  String _currentAddress = 'Getting your location';
  List<Course> recommendedCourses = [];
  List<String> courseCategories = [];
  bool _locationFetched = false;

  @override
  void initState() {
    super.initState();
    _fetchCourses();
    _fetchCourseCategories();
    _getCurrentLocation(); 
  }

  Future<void> _getCurrentLocation() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      try {
        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        _getAddressFromCoordinates(position.latitude, position.longitude);
      } catch (e) {
        setState(() {
          _currentAddress = 'Error getting location: $e';
        });
      }
    } else {
      setState(() {
        _currentAddress = 'Can\'t find your location';
      });
    }
  }

  Future<void> _getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String result = [
          if (place.locality != null) place.locality!,
          if (place.administrativeArea != null) place.administrativeArea!,
          if (place.country != null) place.country!,
        ].join(', ');

        setState(() {
          _currentAddress = result.isNotEmpty ? result : 'No address available';
         // Update that location has been fetched
        });
      } else {
        setState(() {
          _currentAddress = 'No address found at this location.';
        });
      }
    } catch (e) {
      setState(() {
        _currentAddress = 'Failed to get address: $e';
      });
    }
  }

  Future<void> _fetchCourses() async {
    try {
      final coursesQuerySnapshot = await FirebaseFirestore.instance.collection('Courses').get();
      List<Course> validCourses = [];

      for (var courseDoc in coursesQuerySnapshot.docs) {
        final ownerId = courseDoc['ownerId'];
        final ownerDoc = await FirebaseFirestore.instance.collection('Users').doc(ownerId).get();

        if (ownerDoc.exists && ownerDoc['role'] == 'Owner Course') {
          final course = Course.fromMap(courseDoc.data());
          if (course.courseRating > 2.4) {
            validCourses.add(course);
          }
        }
      }

      validCourses.sort((a, b) => b.courseRating.compareTo(a.courseRating));
      setState(() {
        recommendedCourses = validCourses.take(4).toList();
      });
    } catch (e) {
      print('Error fetching courses: $e');
    }
  }

  Future<void> _fetchCourseCategories() async {
    try {
      final results = await FirebaseFirestore.instance.collection('Courses').get();
      final categories = results.docs.map((doc) => doc['course_Type'] as String).toSet().toList();

      setState(() {
        courseCategories = categories;
      });
    } on FirebaseException catch (e) {
      print('Error fetching course categories: $e');
    }
  }

  Future<List<Course>> _fetchCoursesByCategory(String category) async {
    try {
      final results = await FirebaseFirestore.instance.collection('Courses').where('course_Type', isEqualTo: category).get();
      List<Course> validCourses = [];

      for (var courseDoc in results.docs) {
        final ownerId = courseDoc['ownerId'];
        final ownerDoc = await FirebaseFirestore.instance.collection('Users').doc(ownerId).get();

        if (ownerDoc.exists && ownerDoc['role'] == 'Owner Course') {
          final course = Course.fromMap(courseDoc.data());
          if (course.courseRating > 2.4) {
            validCourses.add(course);
          }
        }
      }

      validCourses.sort((a, b) => b.courseRating.compareTo(a.courseRating));
      return validCourses;
    } on FirebaseException catch (e) {
      print('Error fetching courses by category: $e');
      return [];
    }
  }

  void _onTabChange(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  Future<void> _fetch() async {
    await Firebase.initializeApp();
    final firebaseUser = await FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      try {
        final docSnapshot = await FirebaseFirestore.instance.collection('Users').doc(firebaseUser.uid).get();
        if (docSnapshot.exists) {
          myusername = docSnapshot.data()!['username'];
        } else {
          print('Username not found in document');
        }
      } on FirebaseException catch (e) {
        print('Error fetching username: $e');
      }
    } else {
      print('No signed-in user found');
    }
  }

 Future<void> _searchCourses(String query) async {
  if (query.isEmpty){
    Get.dialog(const NotificationDialog(message: 'Please enter a search query.'));
    return;
  }
  try {
    final queryWithPrefix = 'Kecamatan $query';

    final results = await FirebaseFirestore.instance.collection('Courses')
        .where('course_name', isGreaterThanOrEqualTo: query)
        .where('course_name', isLessThanOrEqualTo: query + '\uf8ff')
        .get();

    final subdistrictResults = await FirebaseFirestore.instance.collection('Courses')
        .where('course_subdistrict', isGreaterThanOrEqualTo: queryWithPrefix)
        .where('course_subdistrict', isLessThanOrEqualTo: queryWithPrefix + '\uf8ff')
        .get();

    final courseTypeResults = await FirebaseFirestore.instance.collection('Courses')
        .where('course_Type', isGreaterThanOrEqualTo: query)
        .where('course_Type', isLessThanOrEqualTo: query + '\uf8ff')
        .get();

    final allResults = [...results.docs, ...subdistrictResults.docs, ...courseTypeResults.docs].toSet().toList();
    final courses = allResults.map((doc) => Course.fromMap(doc.data())).toList();

    Get.to(
      SearchResultsPage(query: query, searchResults: courses),
      transition: Transition.size,
      duration: const Duration(milliseconds: 800),
    );
  } catch (e) {
    print('Error searching courses: $e');
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        toolbarHeight: 10.0,
        backgroundColor: const Color(0xFF4A1C6F),
      ),
      body: Center(
        child: _buildPageContent(),
      ),
      bottomNavigationBar: CustomNavBar(
        selectedIndex: _selectedIndex,
        onTabChange: _onTabChange,
      ),
    );
  }

  Widget _buildPageContent() {
    if (_selectedIndex == 0) {
      return _buildHomePage();
    } else if (_selectedIndex == 1) {
      return const CoursePage();
    } else {
      return const ProfilePage();
    }
  }

  Widget _buildHomePage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Info and Search Bar Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              color: Color(0xFF4A1C6F),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(25.0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8.0, 0.0, 8.2, 0),
                  child: FutureBuilder(
                    future: _fetch(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else {
                        return Text(
                          'Hello, $myusername',
                          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Colors.white),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 4.0),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.white),
                    Text(
                      _currentAddress,
                      style: const TextStyle(fontSize: 12.0, color: Colors.white),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  onSubmitted: (query) {
                    _searchCourses(query);
                  },
                  decoration: InputDecoration(
                    hintText: 'Find Course by Subdistrict, Type, name',
                    hintStyle: const TextStyle(color: Colors.white70, fontSize: 12.0, fontWeight: FontWeight.w600),
                    prefixIcon: const Icon(Icons.search, color: Colors.white),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide.none,
                    ),
                    fillColor: const Color.fromARGB(40, 217, 217, 217),
                    filled: true,
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const NewCourseBanner(),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recommended Course',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                if (recommendedCourses.isEmpty)
                  Container(
                    height: 120,
                    alignment: Alignment.center,
                    child: const Text(
                      'No recommended courses available',
                      style: TextStyle(fontSize: 16.0, color: Colors.grey),
                    ),
                  ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: recommendedCourses.map((course) => _buildRecommendedCourseCard(course)).toList(),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Course',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () {
                        _onTabChange(1);
                      },
                      child: const Text('Show All', style: TextStyle(color: Color.fromARGB(255, 68, 24, 104))),
                    ),
                  ],
                ),
                if (courseCategories.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(42.0),
                    child: Center(
                      child: Text('No courses available', style: TextStyle(fontSize: 16.0, color: Colors.grey)),
                    ),
                  ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: courseCategories.map((category) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: _buildCategoryButton(category),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
                if (_selectedCategory.isNotEmpty) _buildCategoryCourses(_selectedCategory),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedCourseCard(Course course) {
    return GestureDetector(
      onTap: () {
        Get.to(
          CourseDetailPage(course: course),
          transition: Transition.native,
          duration: const Duration(milliseconds: 800),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Container(
          height: 220,
          width: 160,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: const Color.fromARGB(255, 207, 205, 205),
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImage(course.courseImageUrl, width: 160),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.courseName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.0,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                    Text(
                      course.courseType,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      height: 35.0,
                      child: Text(
                        course.courseDescription,
                        style: const TextStyle(
                          color: Colors.black45,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.visible,
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        Text(course.courseRating.toStringAsFixed(1)), // Membulatkan angka rating ke atas
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryButton(String category) {
    return GestureDetector(
      onTap: () => _onCategorySelected(category),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: _selectedCategory == category ? const Color(0xFF4A1C6F) : Colors.white,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: const Color(0xFF4A1C6F), width: 2.0),
          boxShadow: _selectedCategory == category
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Text(
          category,
          style: TextStyle(
            fontSize: 14.0,
            color: _selectedCategory == category ? Colors.white : const Color(0xFF4A1C6F),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCourses(String category) {
    return FutureBuilder<List<Course>>(
      future: _fetchCoursesByCategory(category),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center();
        } else {
          final courses = snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: courses.map((course) => _buildDetailedCourseCard(course)).toList(),
          );
        }
      },
    );
  }
  Widget _buildDetailedCourseCard(Course course) {
    return GestureDetector(
      onTap: () {
        Get.to(
          CourseDetailPage(course: course),
          transition: Transition.native,
          duration: const Duration(milliseconds: 800),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color.fromARGB(220, 255, 255, 255), Color.fromARGB(255, 255, 255, 255)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: const Color.fromARGB(255, 68, 24, 104),
              width: 0.3,
            ),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCircularImage(course.courseImageUrl, width: 60, height: 60),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            course.courseName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                              color: Colors.black,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Colors.black),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  course.courseSubdistrict,
                                  style: const TextStyle(
                                    fontSize: 12.0,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Container(
                            height: 40.0,
                            width: 400.0,
                            child: Text(
                              course.courseDescription,
                              maxLines: 2,
                              overflow: TextOverflow.visible,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 12.0,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (course.courseRating > 3.0)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(255, 68, 24, 104),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(0),
                        topRight: Radius.circular(10),
                        bottomRight: Radius.circular(0),
                        bottomLeft: Radius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Recommended',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircularImage(String url, {required double width, required double height}) {
    return ClipOval(
      child: url.isEmpty || Uri.tryParse(url)?.hasAbsolutePath != true
          ? Image.asset('assets/image/adminprofile.png', width: width, height: height, fit: BoxFit.cover)
          : Image.network(url, width: width, height: height, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) {
              return Image.asset('assets/image/adminprofile.png', width: width, height: height, fit: BoxFit.cover);
            }),
    );
  }

  Widget _buildImage(String url, {required double width}) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(8),
        topRight: Radius.circular(8),
      ),
      child: url.isEmpty || Uri.tryParse(url)?.hasAbsolutePath != true
          ? Image.asset(
              'assets/image/adminprofile.png',
              height: 100,
              width: width,
              fit: BoxFit.cover,
            )
          : Image.network(
              url,
              height: 100,
              width: width,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  'assets/image/adminprofile.png',
                  height: 100,
                  width: width,
                  fit: BoxFit.cover,
                );
              },
            ),
    );
  }
}
