import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FormDaftar extends StatefulWidget {
  final String courseId;
  final String courseType;
  final String courseName;

  const FormDaftar({
    required this.courseId,
    required this.courseType,
    required this.courseName,
    super.key,
  });

  @override
  FormDaftarState createState() => FormDaftarState();
}

class FormDaftarState extends State<FormDaftar> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emergencyContactController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  bool _isAgreed = false;
  bool _registerYourself = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _emergencyContactController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser!;
    final docSnapshot = await FirebaseFirestore.instance.collection('Users').doc(user.uid).get();

    if (docSnapshot.exists) {
      final userData = docSnapshot.data()!;
      setState(() {
        _nameController.text = userData['username'] ?? '';
        _emailController.text = userData['email'] ?? '';
        _phoneController.text = userData['phone_number'] ?? '';
      });
    }
  }

  Future<void> _submitForm() async {
  if (_formKey.currentState!.validate() && _isAgreed) {
    final user = FirebaseAuth.instance.currentUser!;
    final registrantData = {
      'name': _nameController.text,
      'email': _emailController.text,
      'phone_number': _phoneController.text,
      'emergency_contact': _emergencyContactController.text,
      'last_education': _selectedEducation,
      'date_of_entry': _dateController.text,
      'registered_by': user.uid,
      'course_id': widget.courseId, 
    };

    try {
      // Add registrant to the Registrants collection
      final registrantRef = await FirebaseFirestore.instance.collection('Registrants').add(registrantData);

      // Get the newly added document ID
      final registrantId = registrantRef.id;

      // Update the registrant with its own ID
      await registrantRef.update({'registrant_id': registrantId});

      // Update the course document with the new registrant ID
      await FirebaseFirestore.instance.collection('Courses').doc(widget.courseId).update({
        'registrants': FieldValue.arrayUnion([registrantId])
      });

      // Update the user's document with the new registrant ID
      await FirebaseFirestore.instance.collection('Users').doc(user.uid).update({
        'registrants': FieldValue.arrayUnion([registrantId])
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda telah terdaftar di Course ini!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to register: $e')),
      );
    }
  } else if (!_isAgreed) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please agree to the terms and conditions')),
    );
  }
}


  String? _selectedEducation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Form Pendaftaran'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  '${widget.courseType} > ${widget.courseName}',
                  style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(fontSize: 12.0),
                  decoration: const InputDecoration(
                    labelText: 'Insert Your Name',
                    labelStyle:TextStyle(fontSize: 14.0),
                    prefixIcon: Icon(Icons.person, color: Color(0xFF4A1C6F)),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  keyboardType: TextInputType.emailAddress,
                  controller: _emailController,
                  style: const TextStyle(fontSize: 12.0),
                  decoration: const InputDecoration(
                    labelStyle:TextStyle(fontSize: 14.0),
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email, color: Color(0xFF4A1C6F)),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  keyboardType: TextInputType.phone,
                  controller: _phoneController,
                  style: const TextStyle(fontSize: 12.0),
                  decoration: const InputDecoration(
                    labelStyle:TextStyle(fontSize: 14.0),
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone, color: Color(0xFF4A1C6F)),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontSize: 12.0),
                  controller: _emergencyContactController,
                  decoration: const InputDecoration(
                    labelStyle:TextStyle(fontSize: 14.0),
                    labelText: 'Emergency Call',
                    prefixIcon: Icon(Icons.phone, color: Color(0xFF4A1C6F)),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty && value == _phoneController.text) {
                      return 'Emergency contact cannot be the same as phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelStyle:TextStyle(fontSize: 14.0),
                    labelText: 'Last Education',
                    prefixIcon: Icon(Icons.school, color: Color(0xFF4A1C6F)),
                    border: OutlineInputBorder(),
                  ),
                  items: <String>['SD', 'SMP', 'SMA', 'Diploma', 'Sarjana'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedEducation = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select your last education';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  
                  keyboardType: TextInputType.datetime,
                  controller: _dateController,
                  decoration: const InputDecoration(
                    labelStyle:TextStyle(fontSize: 14.0),
                    labelText: 'Tanggal Masuk',
                    prefixIcon: Icon(Icons.calendar_today, color: Color(0xFF4A1C6F)),
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null) {
                      String formattedDate = DateFormat('dd-MM-yyyy').format(pickedDate);
                      setState(() {
                        _dateController.text = formattedDate;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16.0),
                Row(
                  children: [
                    Checkbox(
                      value: _isAgreed,
                      onChanged: (bool? value) {
                        setState(() {
                          _isAgreed = value!;
                        });
                      },
                    ),
                    const Expanded(
                      child: Text(
                        'Dengan ini, anda telah menyetujui Peraturan & Ketentuan yang berlaku',
                        style: TextStyle(fontSize: 14.0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                Row(
                  children: [
                    Checkbox(
                      value: _registerYourself,
                      onChanged: (bool? value) {
                        setState(() {
                          _registerYourself = value!;
                          if (_registerYourself) {
                            _fetchUserData();
                          } else {
                            _nameController.clear();
                            _emailController.clear();
                            _phoneController.clear();
                          }
                        });
                      },
                    ),
                    const Expanded(
                      child: Text(
                        'Register Yourself',
                        style: TextStyle(fontSize: 14.0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A1C6F),
                  ),
                  child: const Text(
                    'Submit',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
