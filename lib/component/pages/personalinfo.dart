import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  String _name = '';
  String _phoneNumber = '';
  String _emailAddress = '';
  String _password = '';
  String _profileImageUrl = '';
  String _role = '';
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    await Firebase.initializeApp();
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      try {
        final docSnapshot = await FirebaseFirestore.instance
            .collection('Users')
            .doc(firebaseUser.uid)
            .get();

        if (docSnapshot.exists) {
          final userData = docSnapshot.data()!;
          setState(() {
            _name = userData['username'] as String;
            _phoneNumber = userData['phone_number'] as String;
            _emailAddress = userData['email'] as String;
            _password = userData['password'] as String;
            _profileImageUrl = userData['profile_image_url'] as String? ?? '';
            _role = userData['role'] as String? ?? '';
          });
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

 Future<void> _changeProfileImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final File imageFile = File(pickedFile.path);
      final firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser != null) {
        try {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('profile_images/${firebaseUser.uid}');
          final uploadTask = storageRef.putFile(imageFile);

          // Show a progress indicator while uploading (optional)
           uploadTask.snapshotEvents;
          showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                  content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          value: uploadTask.snapshot.bytesTransferred /
                              uploadTask.snapshot.totalBytes,
                        ),
                        const Text('Uploading profile image...'),
                      ])));

          final downloadUrl = await (await uploadTask).ref.getDownloadURL();
          setState(() {
            _profileImageUrl = downloadUrl;
          });

          // Update user document in Firestore
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(firebaseUser.uid)
              .update({'profile_image_url': downloadUrl});

          Navigator.pop(context); // Hide progress dialog

          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile image updated successfully!')));
        } on FirebaseException catch (e) {
          // Handle Firebase errors
          Navigator.pop(context); // Hide progress dialog
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Error uploading profile image: $e')));
        }
      } else {
        // Handle case where no user is signed in
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please sign in to upload a profile image')));
      }
    }
  }


  Future<void> _changeData(String field, String value) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      try {
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(firebaseUser.uid)
            .update({field: value});
        setState(() {
          switch (field) {
            case 'username':
              _name = value;
              break;
            case 'phone_number':
              _phoneNumber = value;
              break;
            case 'email':
              _emailAddress = value;
              break;
            case 'password':
              _password = value;
              break;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data updated successfully!')),
        );
      } on FirebaseException catch (e) {
        print('Error updating data: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update data: $e')),
        );
      }
    }
  }

  void _showEditDialog(String field, String currentValue) {
    final TextEditingController controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Data'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: field),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _changeData(field, controller.text);
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Profil Details', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF4A1C6F),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _changeProfileImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _profileImageUrl.isNotEmpty
                        ? NetworkImage(_profileImageUrl)
                        : const AssetImage('assets/image/profile.png') as ImageProvider,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildInfoRow(
                icon: Icons.person,
                title: 'Your name',
                value: _name,
                onEdit: () => _showEditDialog('username', _name),
              ),
              _buildInfoRow(
                icon: Icons.phone,
                title: 'Phone Number',
                value: _phoneNumber,
                onEdit: () => _showEditDialog('phone_number', _phoneNumber),
              ),
              _buildInfoRow(
                icon: Icons.email,
                title: 'Email Address',
                value: _emailAddress,
                onEdit: () => _showEditDialog('email', _emailAddress),
              ),
              _buildInfoRow(
                icon: Icons.remove_red_eye_sharp,
                title: 'Your Password',
                value: _password,
                onEdit: () => _showEditDialog('passwor  d', _role),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onEdit,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF4A1C6F)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFF4A1C6F)),
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }
}
