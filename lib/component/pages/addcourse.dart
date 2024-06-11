import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_application_1/component/pages/profilepage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoding/geocoding.dart';
import 'package:bottom_picker/bottom_picker.dart';
class AddCourse extends StatefulWidget {
  const AddCourse({super.key});

  @override
  AddCourseState createState() => AddCourseState();
}

class AddCourseState extends State<AddCourse> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _lowestPriceController = TextEditingController();
  final TextEditingController _highestPriceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _subdistrictController = TextEditingController();
  final TextEditingController _syllabusCountController = TextEditingController();
  var _syllabusTitles = List<TextEditingController>.generate(0, (index) => TextEditingController());
  var _syllabusTopics = List<TextEditingController>.generate(0, (index) => TextEditingController());
  final _profileImageFile = ValueNotifier<File?>(null);
  final ImagePicker _picker = ImagePicker();
  String? _selectedCourseType;
  String imageUrl = '';
  String previousImageUrl = '';
  String? _currentLatitude;
  String? _currentLongitude;
   bool _useCurrentLocation = false; 

  final List<bool> _isOpenOn = List.filled(7, false);

  final Map<String, int> _dayNameToIndex = {
    'Monday': 0,
    'Tuesday': 1,
    'Wednesday': 2,
    'Thursday': 3,
    'Friday': 4,
    'Saturday': 5,
    'Sunday': 6,
  };

  Widget _buildCheckbox(String dayName) {
    final int index = _dayNameToIndex[dayName]!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Checkbox(
          value: _isOpenOn[index],
          onChanged: (value) {
            setState(() {
              _isOpenOn[index] = value!;
            });
          },
        ),
        Text(dayName),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String labelText, String hintText, {TextInputType keyboardType = TextInputType.text, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            labelText,
            style: const TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4A1C6F),
            ),
          ),
          const SizedBox(height: 8.0),
          TextFormField(
            style: const TextStyle(fontSize: 12.0),
            controller: controller,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: Color(0xFF4A1C6F), fontSize: 13.0),
              prefixIcon: Icon(_getIconForLabel(labelText), color: const Color(0xFF4A1C6F)),
              border: const OutlineInputBorder(
                borderSide: BorderSide(
                  color: Color(0xFF4A1C6F),
                  width: 2.0,
                ),
              ),
            ),
            keyboardType: keyboardType,
            validator: validator ?? (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter $labelText';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  IconData _getIconForLabel(String label) {
    switch (label) {
      case 'Course Pricing':
        return Icons.attach_money_outlined;
      case 'Name':
      case 'Course Name':
        return Icons.person;
      case 'Email':
      case 'Course Email':
        return Icons.email;
      case 'Phone Number':
      case 'Course Phone Number':
        return Icons.phone;
      case 'Course Location':
        return Icons.location_on;
      case 'Course Latitude':
      case 'Course Longitude':
        return Icons.public;
      default:
        return Icons.text_fields;
    }
  }

  Future<void> _getCurrentLocation() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      try {
        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        setState(() {
          _currentLatitude = position.latitude.toString();
          _currentLongitude = position.longitude.toString();
          _latitudeController.text = _currentLatitude!;
          _longitudeController.text = _currentLongitude!;
        });

        // Reverse geocoding to get the subdistrict
        List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        Placemark place = placemarks[0];
        String subdistrict = place.locality ?? 'Unknown';

        // Update the selected location with the subdistrict
        setState(() {
          _subdistrictController.text = subdistrict;
          _locationController.text = '${place.street}, ${place.subLocality}, ${place.locality}, ${place.subAdministrativeArea}, ${place.administrativeArea}, ${place.country}, ${place.postalCode}';
        });
      } catch (e) {
        setState(() {
          _currentLatitude = 'Error getting location';
          _currentLongitude = 'Error getting location';
        });
      }
    } else {
      setState(() {
        _currentLatitude = 'Permission denied';
        _currentLongitude = 'Permission denied';
      });
    }
  }

  Future<void> _uploadProfileImage() async {
    XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;
    String uniqueFileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference referenceRoot = FirebaseStorage.instance.ref();
    Reference referenceDirImages = referenceRoot.child('course_images/');
    Reference referenceImageToUpload = referenceDirImages.child(uniqueFileName);

    setState(() {
      _profileImageFile.value = File(pickedFile.path);
    });
    try {
      // Delete previous image if exists
      if (previousImageUrl.isNotEmpty) {
        await FirebaseStorage.instance.refFromURL(previousImageUrl).delete();
      }

      await referenceImageToUpload.putFile(File(pickedFile.path));
      imageUrl = await referenceImageToUpload.getDownloadURL();

      setState(() {
        previousImageUrl = imageUrl;
      });
    } catch (e) {
      // Handle error
    }
  }

  Widget _buildProfileImagePicker() {
    return Row(
      children: [
        SizedBox(
          width: 150,
          height: 150,
          child: _profileImageFile.value != null
              ? Image.file(_profileImageFile.value!)
              : const Icon(Icons.person, size: 150),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: _uploadProfileImage,
          child: const Text('Select Profile Image'),
        ),
      ],
    );
  }

  Widget _buildPriceRangeFields() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(
            child: _buildTextField(_lowestPriceController, 'Lowest Price', "Enter lowest price", keyboardType: TextInputType.number),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: _buildTextField(_highestPriceController, 'Highest Price', "Enter highest price", keyboardType: TextInputType.number, validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter Highest Price';
              }
              if (double.tryParse(value)! < double.tryParse(_lowestPriceController.text)!) {
                return 'Highest Price must be greater than Lowest Price';
              }
              return null;
            }),
          ),
        ],
      ),
    );
  }

  Future<void> _addCourse() async {
    if (_formKey.currentState!.validate()) {
      try {
        final userNow = FirebaseAuth.instance.currentUser!;
        final userId = userNow.uid;
        final now = DateTime.now();
        final timestamp = Timestamp.fromDate(now);

        final List<String> selectedOpenDays = [];
        for (int i = 0; i < _isOpenOn.length; i++) {
          if (_isOpenOn[i]) {
            selectedOpenDays.add(_dayNameToIndex.keys.toList()[i]);
          }
        }

        // Convert latitude and longitude to GeoPoint
        final double latitude = double.tryParse(_latitudeController.text) ?? 0.0;
        final double longitude = double.tryParse(_longitudeController.text) ?? 0.0;
        final GeoPoint courseLocation = GeoPoint(latitude, longitude);

        if (imageUrl.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload the image')));
          return;
        }
        final String coursePricing = '${_lowestPriceController.text} - ${_highestPriceController.text}';

        final courseData = {
          'course_name': _nameController.text,
          'course_email': _emailController.text,
          'course_phone_number': _phoneNumberController.text,
          'course_pricing': coursePricing,
          'course_Type': _selectedCourseType,
          'course_subdistrict': _subdistrictController.text,
          'course_location': courseLocation,
          'course_description': _descriptionController.text,
          'course_address': _locationController.text,
          'last_updated': timestamp,
          'courseId': '', 
          'ownerId': userId,
          'course_open_days': selectedOpenDays,
          'course_image_url': imageUrl,
          'course_rating': 0.1,
          'syllabi': [], 
        };

        final courseRef = await FirebaseFirestore.instance.collection('Courses').add(courseData);
        final courseId = courseRef.id;

        await FirebaseFirestore.instance.collection('Courses').doc(courseId).update({
          'courseId': courseId,
        });

        final userDoc = FirebaseFirestore.instance.collection('Users').doc(userId);
        await userDoc.update({
          'courses': FieldValue.arrayUnion([courseId]),
        });

        // Create Syllabus in Firestore
        final List<Map<String, dynamic>> syllabusData = [];
        for (int i = 0; i < _syllabusTitles.length; i++) {
          int syllabusMeetings = int.tryParse(_syllabusTopics[i].text) ?? 0; // Ensure syllabusMeetings is an integer
          syllabusData.add({
            'syllabusId': '',
            'courseId': courseId,
            'syllabusTitles': _syllabusTitles[i].text,
            'syllabusMeetings': syllabusMeetings,
          });
        }
        final List<String> syllabusIds = [];
        for (var syllabus in syllabusData) {
          final syllabusRef = await FirebaseFirestore.instance.collection('Syllabus').add(syllabus);
          final syllabusId = syllabusRef.id;
          await FirebaseFirestore.instance.collection('Syllabus').doc(syllabusId).update({
            'syllabusId': syllabusId,
          });
          syllabusIds.add(syllabusId);
        }

        // Update course with syllabus IDs
        await FirebaseFirestore.instance.collection('Courses').doc(courseId).update({
          'syllabi': syllabusIds,
        });

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Course added successfully!')));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        );
      } on FirebaseException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add course: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 55.0,
        centerTitle: true,
        title: const Text('Add Course', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF4A1C6F),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Course Information',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24.0),
              ),
              const SizedBox(height: 8),
              const Text('Fill this form with your course information'),
              const SizedBox(height: 16),
              _buildTextField(_nameController, 'Course Name', 'Insert Your Course name'),
              _buildTextField(_emailController, 'Course Email', 'Insert Your Course email', keyboardType: TextInputType.emailAddress, validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                  return 'Please enter a valid email address';
                }
                return null;
              }),
              _buildTextField(_phoneNumberController, 'Course Phone Number', 'Insert Your Course Number', keyboardType: TextInputType.phone),
              _buildPriceRangeFields(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Course Type",
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A1C6F),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    GestureDetector(
                      onTap: () {
                        List<String> courseTypes = ['English', 'Programming'];
                        BottomPicker(
                          pickerTitle: const Text(
                            "Select Course Type",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.0,
                              color: Color(0xFF4A1C6F),
                            ),
                          ),
                          items: courseTypes.map((courseType) => Text(
                            courseType,
                            style: const TextStyle(fontSize: 21.0,), // Set the font size here
                          )).toList(),
                          itemExtent: 40.0, // Adjust the spacing between items here
                          onSubmit: (index) {
                            setState(() {
                              _selectedCourseType = courseTypes[index];
                            });
                          },
                          displaySubmitButton: true,
                        ).show(context);
                      },
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: TextEditingController(text: _selectedCourseType),
                          style: const TextStyle(fontSize: 12.0),
                          decoration: const InputDecoration(
                            hintText: "Input Your Course Type",
                            hintStyle: TextStyle(color: Color(0xFF4A1C6F), fontSize: 13.0),
                            prefixIcon: Icon(Icons.type_specimen_sharp, color: Color(0xFF4A1C6F)),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a course type';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height:12.0),
              const Text(
                'Course Location',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 21.0),
              ),
              const SizedBox(height: 4.0),
              const Text('Provide the course location details'),
              const SizedBox(height: 16),
              _buildTextField(_locationController, 'Course Location', 'Insert Your Course location'),
              _buildTextField(_subdistrictController, 'Course Subdistrict', 'Insert Your Course subdistrict'),
              _buildTextField(_latitudeController, 'Course Latitude', 'Insert Your Course latitude'),
              _buildTextField(_longitudeController, 'Course Longitude', 'Insert Your Course longitude'),
               Row(
                children: [
                  Checkbox(
                    value: _useCurrentLocation,
                    onChanged: (bool? value) {
                      setState(() {
                        _useCurrentLocation = value ?? false;
                        if (_useCurrentLocation) {
                          _getCurrentLocation();
                        }
                      });
                    },
                  ),
                  const Text('Use Current Location', style: TextStyle(fontSize: 14.0)),
                ],
              ),
              const SizedBox(height:12.0),
              const Text(
                'Course Additional',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 21.0),
              ),
              const SizedBox(height:4.0),
              const Text('Additional information for the course'),
              const SizedBox(height:16.0),
              _buildTextField(_descriptionController, 'Course Description', 'Insert Your Course description', keyboardType: TextInputType.multiline),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Course Open Days",
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A1C6F),
                      ),
                    ),
                    SizedBox(height: 8.0),
                  ],
                ),
              ),
              Wrap(
                children: _dayNameToIndex.keys.map((dayName) => _buildCheckbox(dayName)).toList(),
              ),
              _buildProfileImagePicker(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Number of Syllabuses",
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A1C6F),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    TextFormField(
                      controller: _syllabusCountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: "Enter the number of syllabuses (max 10)",
                        hintStyle: TextStyle(color: Color(0xFF4A1C6F), fontSize: 13.0),
                        prefixIcon: Icon(Icons.description_outlined, color: Color(0xFF4A1C6F)),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please specify the number of syllabuses.';
                        }
                        final syllabusCount = int.tryParse(value);
                        if (syllabusCount == null || syllabusCount < 1 || syllabusCount > 10) {
                          return 'Please enter a valid number of syllabuses (between 1 and 10).';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        final newSyllabusCount = int.tryParse(value) ?? 0;
                        setState(() {
                          _syllabusTitles = List<TextEditingController>.generate(
                            newSyllabusCount.clamp(0, 10),
                            (index) => TextEditingController(),
                          );
                          _syllabusTopics = List<TextEditingController>.generate(
                            newSyllabusCount.clamp(0, 10),
                            (index) => TextEditingController(),
                          );
                        });
                      },
                    ),
                  ],
                ),
              ),
              ..._syllabusTitles.asMap().entries.map((entry) {
                int index = entry.key;
                TextEditingController syllabusTitleController = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: syllabusTitleController,
                          style: const TextStyle(fontSize: 14.0),
                          decoration: InputDecoration(
                            labelText: "Syllabus #${index + 1} Title",
                            labelStyle: const TextStyle(color: Color(0xFF4A1C6F), fontSize: 13.0),
                            prefixIcon: const Icon(Icons.format_list_bulleted_outlined, color: Color(0xFF4A1C6F)),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a title for Syllabus #${index + 1}.';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16.0),
                      Expanded(
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          controller: _syllabusTopics[index],
                          style: const TextStyle(fontSize: 14.0),
                          decoration: InputDecoration(
                            labelText: "Syllabus #${index + 1} Topic",
                            labelStyle: const TextStyle(color: Color(0xFF4A1C6F), fontSize: 13.0),
                            prefixIcon: const Icon(Icons.topic, color: Color(0xFF4A1C6F)),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a topic for Syllabus #${index + 1}.';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addCourse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A1C6F),
                ),
                child: const Text('Add Course', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
