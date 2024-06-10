import 'package:flutter/material.dart';

Widget _buildTextField(TextEditingController controller, String labelText, String hintText, {TextInputType keyboardType = TextInputType.text, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            labelText,
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A1C6F),
            ),
          ),
          const SizedBox(height: 8.0),
          TextFormField(
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