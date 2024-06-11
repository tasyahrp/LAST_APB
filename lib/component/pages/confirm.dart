import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Model/User.dart';
import 'package:intl/intl.dart';
import 'seedetailsadmin.dart';

class Confirm extends StatefulWidget {
  const Confirm({super.key});

  @override
  State<Confirm> createState() => _ConfirmState();
}

class _ConfirmState extends State<Confirm> {
  List<User> applicants = [];

  void _fetchApplicants() async {
    final applicantsDocs = await FirebaseFirestore.instance
        .collection('Users')
        .where('isRequestOwner', isEqualTo: true)
        .where('role', isEqualTo: 'Student')
        .get();

    setState(() {
      applicants = applicantsDocs.docs.map((doc) => User.fromMap(doc.data() as Map<String, dynamic>)).toList();
    });
  }

  void _approveApplicant(String docId) async {
    final docSnapshot = await FirebaseFirestore.instance.collection('Users').doc(docId).get();
    if (docSnapshot.exists) {
      final userData = docSnapshot.data();
      if (userData != null && userData['isDownPrivilage'] == true) {
        _showDownPrivilegeDialog(docId);
      } else {
        _showApprovalConfirmationDialog(docId);
      }
    }
  }

  void _showApprovalConfirmationDialog(String docId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Approval Confirmation'),
          content: const Text('Are you sure you want to approve this applicant?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Deny it!'),
              onPressed: () async {
                await _revertUserToStudent(docId);
                Navigator.of(context).pop();
                _fetchApplicants();
              },
            ),
            TextButton(
              child: const Text('Yes, Admit it'),
              onPressed: () async {
                await FirebaseFirestore.instance.collection('Users').doc(docId).update({
                  'isRequestOwner': false,
                  'role': 'Owner Course',
                  'registrants': FieldValue.delete(),
                });
                Navigator.of(context).pop();
                _fetchApplicants();
              },
            ),
          ],
        );
      },
    );
  }

  void _showDownPrivilegeDialog(String docId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Down Privilege Warning'),
          content: const Text('This user has been down privileged. Are you sure you want to approve?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Deny it!'),
              onPressed: () async {
                await _revertUserToStudent(docId);
                Navigator.of(context).pop();
                _fetchApplicants();
              },
            ),
            TextButton(
              child: const Text('Yes, Admit it'),
              onPressed: () async {
                await FirebaseFirestore.instance.collection('Users').doc(docId).update({
                  'isRequestOwner': false,
                  'role': 'Owner Course',
                  'registrants': FieldValue.delete(),
                });
                Navigator.of(context).pop();
                _fetchApplicants();
              },
            ),
          ],
        );
      },
    );
  }

  

  Future<void> _revertUserToStudent(String docId) async {
    final userDoc = await FirebaseFirestore.instance.collection('Users').doc(docId).get();
    if (userDoc.exists) {
      final userData = userDoc.data();
      if (userData != null) {
        List<String> courses = List<String>.from(userData['courses']);
        for (String courseId in courses) {
          await FirebaseFirestore.instance.collection('Courses').doc(courseId).delete();
        }
      }
      await FirebaseFirestore.instance.collection('Users').doc(docId).update({
        'isRequestOwner': false,
        'role': 'Student',
        'courses': FieldValue.delete(),
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchApplicants();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Applicant Info',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF4A1C6F),
      ),
      body: applicants.isEmpty
          ? const Center(
              child: Text(
                'Tidak ada user yang mendaftar',
                style: TextStyle(fontSize: 18.0, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: applicants.length,
              itemBuilder: (context, index) {
                final applicant = applicants[index];
                return ApplicantCard(
                  name: applicant.username,
                  course: applicant.courses.join(', '),
                  date: DateFormat('dd-MM-yyyy').format(applicant.requestBecomeOwner),
                  onApprove: () => _approveApplicant(applicant.uid),
                  onSeeDetails: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SeeDetailsPage(applicant: applicant),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class ApplicantCard extends StatelessWidget {
  final String name;
  final String course;
  final String date;
  final VoidCallback onApprove;
  final VoidCallback onSeeDetails;

  const ApplicantCard({
    required this.name,
    required this.course,
    required this.date,
    required this.onApprove,
    required this.onSeeDetails,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: const BorderSide(color: Colors.grey, width: .4),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 21.0)),
            const SizedBox(height: 8.0),
            Text(course, style: const TextStyle(fontSize: 16.0)),
            const SizedBox(height: 8.0),
            Text(date, style: const TextStyle(fontSize: 14.0, color: Colors.grey)),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onApprove,
                  child: const Text('Approve', style: TextStyle(color: Colors.green)),
                ),
                const SizedBox(width: 8.0),
                TextButton(
                  onPressed: onSeeDetails,
                  child: const Text('See Details', style: TextStyle(color: Colors.blue)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
