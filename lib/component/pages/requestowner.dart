import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/component/pages/profilepage.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:bottom_picker/bottom_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoding/geocoding.dart';

class RequestOwnerPage extends StatefulWidget {
  const RequestOwnerPage({super.key});
  @override
  RequestOwnerPageState createState() => RequestOwnerPageState();
}

class RequestOwnerPageState extends State<RequestOwnerPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _courseNameController = TextEditingController();
  final TextEditingController _courseEmailController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _lowestPriceController = TextEditingController();
  final TextEditingController _highestPriceController = TextEditingController();
  final TextEditingController _courseLatitudeController = TextEditingController();
  final TextEditingController _courseLongitudeController = TextEditingController();
  final TextEditingController _coursePhoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _subdistrictController = TextEditingController();
  final _syllabusCountController = TextEditingController();
  var _syllabusTitles = List<TextEditingController>.generate(0, (index) => TextEditingController());
  var _syllabusTopics = List<TextEditingController>.generate(0, (index) => TextEditingController());
  final _profileImageFile = ValueNotifier<File?>(null);
  final ImagePicker _picker = ImagePicker(); 
  String? _selectedCourseType;
  String imageUrl = '';
  String previousImageUrl = '';
  String? _currentLatitude;
  String? _currentLongitude;
  bool _useCurrentLocation = false; // track checkbox state

 

  final List<bool> _isOpenOn = List.filled(7, false); // inisial semuanya tutup

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
    final int index = _dayNameToIndex[dayName]!; // Get index from map
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

  Widget _buildTextField(TextEditingController controller, String labelText, String hintText, int maxLines,
      {TextInputType keyboardType = TextInputType.text, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            labelText,
            style: const TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A1C6F),
            ),
          ),
          const SizedBox(height: 8.0),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 12.0),
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
      case 'Name':
      case 'Course Name':
      case 'Owner Name':
        return Icons.person;
      case 'Email':
      case 'Course Email':
      case 'Owner Email':
        return Icons.email;
      case 'Phone Number':
      case 'Course Phone Number':
      case 'Owner Number':
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
            child: _buildTextField(_lowestPriceController, 'Lowest Price', "Enter lowest price", 1, keyboardType: TextInputType.number),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: _buildTextField(_highestPriceController, 'Highest Price', "Enter highest price", 1, keyboardType: TextInputType.number, validator: (value) {
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

  // Bottom picker for Course Type
  void _showCourseTypePicker(BuildContext context) {
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
        style: const TextStyle(fontSize: 21.0,), 
      )).toList(),
      itemExtent: 40.0, 
      onSubmit: (index) {
        setState(() {
          _selectedCourseType = courseTypes[index];
        });
      },
      displaySubmitButton: true,
    ).show(context);
  }

  Future<void> _getCurrentLocation() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      try {
        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        setState(() {
          _currentLatitude = position.latitude.toString();
          _currentLongitude = position.longitude.toString();
          _courseLatitudeController.text = _currentLatitude!;
          _courseLongitudeController.text = _currentLongitude!;
        });

        // Reverse geocoding to get the subdistrict
        List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        Placemark place = placemarks[0];
        String subdistrict = place.locality ?? 'Unknown';

        // Update the selected location with the subdistrict
        setState(() {
          _locationController.text = '${place.street}, ${place.subLocality}, ${place.locality}, ${place.subAdministrativeArea}, ${place.administrativeArea}, ${place.country}, ${place.postalCode}';
          _subdistrictController.text =subdistrict;
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

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final selectedCourseType = _selectedCourseType;
        final now = DateTime.now();
        final timestamp = Timestamp.fromDate(now);
        final userNow = FirebaseAuth.instance.currentUser!; // current user
        final userId = userNow.uid;

        // Create a list to store selected open days
        final List<String> selectedOpenDays = [];
        for (int i = 0; i < _isOpenOn.length; i++) {
          if (_isOpenOn[i]) {
            selectedOpenDays.add(_dayNameToIndex.keys.toList()[i]);
          }
        }

        // Gabungin Input pricing
        final String coursePricing = '${_lowestPriceController.text} - ${_highestPriceController.text}';

        // Convert latitude and longitude ke GeoPoint
        final double latitude = double.tryParse(_courseLatitudeController.text) ?? 0.0;
        final double longitude = double.tryParse(_courseLongitudeController.text) ?? 0.0;
        final GeoPoint courseLocation = GeoPoint(latitude, longitude);

        final courseData = {
          'course_name': _courseNameController.text,
          'course_email': _courseEmailController.text,
          'course_phone_number': _coursePhoneController.text,
          'course_pricing': coursePricing,
          'course_Type': selectedCourseType,
          'course_subdistrict': _subdistrictController.text,
          'course_location': courseLocation,
          'course_description': _descriptionController.text,
          'course_address': _locationController.text, // Save the detailed address
          'course_rating': 0.1,
          'last_updated': timestamp,
          'courseId': '', // Initially empty placeholder
          'ownerId': userId,
          'course_open_days': selectedOpenDays,
          'course_image_url': imageUrl,
          'syllabi': [], // Initialize syllabi as an empty array
        };

        // Create course in Firestore
        final courseRef = await FirebaseFirestore.instance.collection('Courses').add(courseData);
        final courseId = courseRef.id; // Get the generated ID

        // Update the course with courseId
        await FirebaseFirestore.instance.collection('Courses').doc(courseId).update({
          'courseId': courseId,
        });

        // Create Syllabus di Firestore
        final List<Map<String, dynamic>> syllabusData = [];
        for (int i = 0; i < _syllabusTitles.length; i++) {
          int syllabusMeetings = int.tryParse(_syllabusTopics[i].text) ?? 0; // pastiin syllabusMeetings is an integer
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

        // Update user role
        final user = FirebaseAuth.instance.currentUser!;

        await FirebaseFirestore.instance.collection('Users').doc(user.uid).update({
          'isRequestOwner': true,
          'requestbecomeowner': timestamp,
          'courses': FieldValue.arrayUnion([courseId]), // Add course ID to user's courses array
        });

        // Hilangkan field registrants 
        await FirebaseFirestore.instance.collection('Users').doc(user.uid).update({
          'registrants': FieldValue.delete(),
        }); 


        //  success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request submitted successfully!')),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        );
      } on FirebaseException catch (e) {
        // Handle potential Firebase errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: ${e.message}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color(0xFF4A1C6F),
        title: const Text('Register Owner', style: TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Personal Information',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 21.0),
              ),
              const SizedBox(height: 6),
              const Text('Fill this form with your personal information'),
              const SizedBox(height: 16),
              _buildTextField(_nameController, 'Owner Name', "dzakyrazi", 1),
              _buildTextField(_emailController, 'Owner Email', "dzakyrazi@gmail.com", 1, keyboardType: TextInputType.emailAddress, validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                  return 'Please enter a valid email address';
                }
                return null;
              }),
              _buildTextField(_phoneController, 'Owner Number', "087794780139", 1, keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              const Text(
                'Course Information',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 21.0),
              ),
              const SizedBox(height: 6),
              const Text('Fill this form with your Course information'),
              const SizedBox(height: 16),
              _buildTextField(_courseNameController, 'Course Name', "Insert Your Course name", 1),
              _buildTextField(_courseEmailController, 'Course Email', "Insert Your Course email", 1, keyboardType: TextInputType.emailAddress),
              _buildTextField(_coursePhoneController, 'Course Phone Number', "Insert Your Course number", 1, keyboardType: TextInputType.phone),
              _buildPriceRangeFields(),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Course Type",
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A1C6F),
                      ),
                    ),
                    SizedBox(height: 8.0),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _showCourseTypePicker(context),
                child: AbsorbPointer(
                  child: TextFormField(
                     style: const TextStyle(fontSize: 12.0),
                    controller: TextEditingController(text: _selectedCourseType),
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
              const SizedBox(height: 16),
              const Text(
                'Course Location',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 21.0),
              ),
              const SizedBox(height: 6),
              const Text('Provide the course location details'),
              const SizedBox(height: 16),
              _buildTextField(_locationController, 'Course Location', 'Insert Your Course location', 1),
              _buildTextField(_subdistrictController, 'Course Subdistrict', 'Insert Your Course subdistrict', 1),
              _buildTextField(_courseLatitudeController, 'Course Latitude', 'Insert Your Course latitude', 1),
              _buildTextField(_courseLongitudeController, 'Course Longitude', 'Insert Your Course longitude', 1),
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
              const SizedBox(height:8),
              const Text(
                'Course Additional',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 21.0),
              ),
              const SizedBox(height: 6),
              const Text('Additional information for the course'),
              const SizedBox(height: 16),
              _buildTextField(_descriptionController, 'Course Description', "", 4),
              const SizedBox(height: 16),
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
                      style: const TextStyle(fontSize: 14.0),
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
                            newSyllabusCount.clamp(0, 10), // Clamp between 0 and 10
                            (index) => TextEditingController(),
                          );
                          _syllabusTopics = List<TextEditingController>.generate(
                            newSyllabusCount.clamp(0, 10), // Clamp between 0 and 10
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
                          style: const TextStyle(fontSize: 14.0),
                          controller: _syllabusTopics[index],
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
              ElevatedButton(
                onPressed: _submitForm,
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(const Color(0xFF4A1C6F)),
                ),
                child: const Text('Confirm', style: TextStyle(color: Colors.white, fontSize: 16.0, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
  
