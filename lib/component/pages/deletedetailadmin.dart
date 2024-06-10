import 'package:flutter/material.dart';
import '../../Model/Owner.dart';
import 'package:intl/intl.dart';

class OwnerDetailsPage extends StatelessWidget {
  final Owner owner;

  const OwnerDetailsPage({required this.owner, super.key});

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Applicant Details', style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF4A1C6F),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              'Person information',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16.0),
            DetailItem(title: "User ID", value: owner.docId),
            DetailItem(title: "Username", value: owner.name),
            DetailItem(title: "Email", value: owner.email),

            const SizedBox(height: 16.0),
            const Text(
              'Courses information',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16.0),
            ...owner.courses.map((course) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DetailItem(title: "Course Name", value: course['course_name'] ?? ''),
                  DetailItem(title: "Course Type", value: course['course_Type'] ?? ''),
                  DetailItem(title: "Description", value: course['course_description'] ?? ''),
                  DetailItem(title: "Email", value: course['course_email'] ?? ''),
                  DetailItem(title: "Phone Number", value: course['course_phone_number'] ?? ''),
                  DetailItem(title: "Subdistrict", value: course['course_subdistrict'] ?? ''),
                
                ],
              );
            }).toList(),
            const SizedBox(height: 16.0),
            // Center(
            //   child: ElevatedButton(
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: Colors.red, // Background color
            //       padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(10),
            //       ),
            //     ),
            //     onPressed: () {
            //       // Call your function to downprivilage the owner
            //     },
            //     child: const Text(
            //       'Delete Privilege',
            //       style: TextStyle(
            //         color: Colors.white,
            //         fontSize: 16,
            //         fontWeight: FontWeight.bold,
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}

class DetailItem extends StatelessWidget {
  final String title;
  final String value;

  const DetailItem({required this.title, required this.value, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 4.0),
          Text(value, style: const TextStyle(fontSize: 16)),
          const Divider(color: Colors.grey),
        ],
      ),
    );
  }
}
