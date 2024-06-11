import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/component/pages/homepage.dart';
import '../../Model/Syllabus.dart';
import '../../Model/Course.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class CourseUpdateFormPage extends StatelessWidget {
  final String courseId;

  CourseUpdateFormPage({required this.courseId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Update Course', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF4A1C6F),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('Courses').doc(courseId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Course not found'));
          }

          final courseData = snapshot.data!.data() as Map<String, dynamic>;
          final course = Course.fromMap(courseData);
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: CourseUpdateForm(course: course),
          );
        },
      ),
    );
  }
}

class CourseUpdateForm extends StatefulWidget {
  final Course course;

  CourseUpdateForm({required this.course});

  @override
  CourseUpdateFormState createState() => CourseUpdateFormState();
}

class CourseUpdateFormState extends State<CourseUpdateForm> {
  late TextEditingController _nameController;
  late TextEditingController _typeController;
  late TextEditingController _descriptionController;
  late TextEditingController _emailController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  late TextEditingController _pricingController;
  late TextEditingController _subdistrictController;
  late TextEditingController _addressController;
  late TextEditingController _ownerIdController;
  late TextEditingController _openDaysController;
  List<Syllabus> _syllabi = [];
  File? _selectedImage;
  String? _oldImageUrl;
  Map<String, bool> _isChanged = {};

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.course.courseName);
    _typeController = TextEditingController(text: widget.course.courseType);
    _descriptionController = TextEditingController(text: widget.course.courseDescription);
    _emailController = TextEditingController(text: widget.course.courseEmail);
    _phoneNumberController = TextEditingController(text: widget.course.coursePhoneNumber);
    _latitudeController = TextEditingController(text: widget.course.courseLocation.latitude.toString());
    _longitudeController = TextEditingController(text: widget.course.courseLocation.longitude.toString());
    _pricingController = TextEditingController(text: widget.course.coursePricing);
    _subdistrictController = TextEditingController(text: widget.course.courseSubdistrict);
    _addressController = TextEditingController(text: widget.course.courseAddress);
    _ownerIdController = TextEditingController(text: widget.course.ownerId);
    _openDaysController = TextEditingController(text: widget.course.courseOpenDays.join(', '));
    _oldImageUrl = widget.course.courseImageUrl;
    _initializeChangedMap();
    _fetchSyllabi();
  }

  void _initializeChangedMap() {
    _isChanged = {
      'courseName': false,
      'courseType': false,
      'courseDescription': false,
      'courseEmail': false,
      'coursePhoneNumber': false,
      'courseLatitude': false,
      'courseLongitude': false,
      'coursePricing': false,
      'courseSubdistrict': false,
      'courseAddress': false,
      'ownerId': false,
      'courseOpenDays': false,
    };
  }

  Future<void> _fetchSyllabi() async {
    final syllabusQuerySnapshot = await FirebaseFirestore.instance
        .collection('Syllabus')
        .where('courseId', isEqualTo: widget.course.courseId)
        .get();
    setState(() {
      _syllabi = syllabusQuerySnapshot.docs.map((doc) => Syllabus.fromMap(doc.data())).toList();
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _latitudeController.text = position.latitude.toString();
        _longitudeController.text = position.longitude.toString();
        _isChanged['courseLatitude'] = true;
        _isChanged['courseLongitude'] = true;
      });

      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        setState(() {
          _addressController.text = '${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}';
          _subdistrictController.text = place.subLocality ?? '';
          _isChanged['courseAddress'] = true;
          _isChanged['courseSubdistrict'] = true;
        });
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _descriptionController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _pricingController.dispose();
    _subdistrictController.dispose();
    _addressController.dispose();
    _ownerIdController.dispose();
    _openDaysController.dispose();
    super.dispose();
  }

  Future<void> _updateCourse() async {
    final courseRef = FirebaseFirestore.instance.collection('Courses').doc(widget.course.courseId);

    try {
      final now = DateTime.now();
      final timestamp = Timestamp.fromDate(now);

      // Upload new image if selected
      if (_selectedImage != null) {
        String uniqueFileName = DateTime.now().millisecondsSinceEpoch.toString();
        Reference referenceRoot = FirebaseStorage.instance.ref();
        Reference referenceDirImages = referenceRoot.child('course_images/');
        Reference referenceImageToUpload = referenceDirImages.child(uniqueFileName);

        final uploadTask = referenceImageToUpload.putFile(_selectedImage!);

        final snapshot = await uploadTask.whenComplete(() {});
        final downloadUrl = await snapshot.ref.getDownloadURL();

        // Delete the old image
        if (_oldImageUrl != null && _oldImageUrl!.isNotEmpty) {
          final oldImageRef = FirebaseStorage.instance.refFromURL(_oldImageUrl!);
          await oldImageRef.delete();
        }

        setState(() {
          _oldImageUrl = downloadUrl;
        });
      }

      await courseRef.update({
        'course_name': _nameController.text,
        'course_Type': _typeController.text,
        'course_description': _descriptionController.text,
        'course_email': _emailController.text,
        'course_phone_number': _phoneNumberController.text,
        'course_latitude': double.parse(_latitudeController.text),
        'course_longitude': double.parse(_longitudeController.text),
        'course_pricing': _pricingController.text,
        'course_subdistrict': _subdistrictController.text,
        'course_address': _addressController.text,
        'ownerId': _ownerIdController.text,
        'course_open_days': _openDaysController.text.split(', ').map((e) => e.trim()).toList(),
        'course_image_url': _oldImageUrl,
        'last_updated': timestamp,
        'isNeedUpdate' : false,
      });

      Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const Homepage()),
    );

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Course updated successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update course: $e')));
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      String uniqueFileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference referenceRoot = FirebaseStorage.instance.ref();
      Reference referenceDirImages = referenceRoot.child('course_images/');
      Reference referenceImageToUpload = referenceDirImages.child(uniqueFileName);

      setState(() {
        _selectedImage = File(pickedFile.path);
      });

      try {
        // Delete previous image if exists
        if (_oldImageUrl != null && _oldImageUrl!.isNotEmpty) {
          await FirebaseStorage.instance.refFromURL(_oldImageUrl!).delete();
        }

        await referenceImageToUpload.putFile(_selectedImage!);
        final downloadUrl = await referenceImageToUpload.getDownloadURL();

        setState(() {
          _oldImageUrl = downloadUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image updated successfully')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update image: $e')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No image selected')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildTextField(_nameController, 'Course Name', 'courseName'),
          _buildTextField(_typeController, 'Course Type', 'courseType'),
          _buildTextField(_descriptionController, 'Course Description', 'courseDescription'),
          _buildTextField(_emailController, 'Course Email', 'courseEmail'),
          _buildTextField(_phoneNumberController, 'Course Phone Number', 'coursePhoneNumber'),
          _buildTextField(_latitudeController, 'Course Latitude', 'courseLatitude'),
          _buildTextField(_longitudeController, 'Course Longitude', 'courseLongitude'),
          _buildTextField(_pricingController, 'Course Pricing', 'coursePricing'),
          _buildTextFieldWithButton(_addressController, 'Course Address', _getCurrentLocation, 'courseAddress'),
          _buildTextFieldWithButton(_subdistrictController, 'Course Subdistrict', _getCurrentLocation, 'courseSubdistrict'),
          _buildTextField(_ownerIdController, 'Owner ID', 'ownerId'),
          _buildTextField(_openDaysController, 'Course Open Days (comma separated)', 'courseOpenDays'),
          _buildImagePreview(),
          const SizedBox(height: 20),
          _buildSyllabusList(),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _updateCourse,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A1C6F),
            ),
            child: const Text('Update Course', style: TextStyle(fontSize: 12.0, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String field) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        onChanged: (value) {
          setState(() {
            _isChanged[field] = value != '';
          });
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: _isChanged[field]! ? Colors.green : Colors.grey),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: _isChanged[field]! ? Colors.green : Colors.grey, width: _isChanged[field]! ? 2 : 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: _isChanged[field]! ? Colors.green : Colors.grey, width: _isChanged[field]! ? 2 : 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: _isChanged[field]! ? Colors.green : Colors.grey, width: _isChanged[field]! ? 2 : 1),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFieldWithButton(TextEditingController controller, String label, VoidCallback onPressed, String field) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: (value) {
                setState(() {
                  _isChanged[field] = value != '';
                });
              },
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(color: _isChanged[field]! ? Colors.green : Colors.grey),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: _isChanged[field]! ? Colors.green : Colors.grey, width: _isChanged[field]! ? 2 : 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: _isChanged[field]! ? Colors.green : Colors.grey, width: _isChanged[field]! ? 2 : 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: _isChanged[field]! ? Colors.green : Colors.grey, width: _isChanged[field]! ? 2 : 1),
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.my_location),
            onPressed: () {
              onPressed();
              setState(() {
                _isChanged['courseLatitude'] = true;
                _isChanged['courseLongitude'] = true;
                _isChanged['courseAddress'] = true;
                _isChanged['courseSubdistrict'] = true;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          DottedBorder(
            color: _selectedImage != null ? Colors.green : Colors.grey,
            strokeWidth: _selectedImage != null ? 2 : 1,
            dashPattern: [8, 4],
            child: Container(
              height: 200,
              width: double.infinity,
              child: ClipRect(
                child: Center(
                  child: _selectedImage != null
                      ? Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                          height: 200,
                          width: double.infinity,
                        )
                      : (widget.course.courseImageUrl.isNotEmpty
                          ? Image.network(
                              widget.course.courseImageUrl,
                              fit: BoxFit.cover,
                              height: 200,
                              width: double.infinity,
                            )
                          : const Center(child: Text('No image available'))),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            child: ElevatedButton(
              onPressed: _pickImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black.withOpacity(0.7),
              ),
              child: const Text('Update Image', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyllabusList() {
    if (_syllabi.isEmpty) {
      return const Text('Loading syllabi...');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Syllabi:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _syllabi.length,
          itemBuilder: (context, index) {
            final syllabus = _syllabi[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              child: ListTile(
                title: Text(syllabus.syllabusTitles),
                subtitle: Text('Meetings: ${syllabus.syllabusMeetings}'),
              ),
            );
          },
        ),
      ],
    );
  }
}
