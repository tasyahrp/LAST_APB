import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'coursedetailadmn.dart';

class SendNotifPage extends StatefulWidget {
  const SendNotifPage({super.key});

  @override
  _SendNotifPageState createState() => _SendNotifPageState();
}

class _SendNotifPageState extends State<SendNotifPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF4A1C6F),
          centerTitle: true,
          title: const Text('Send Notification', style: TextStyle(color: Colors.white)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          bottom: const TabBar(
            tabs:  [
              Tab(text: 'Programmer'),
              Tab(text: 'English'),
            ],
            labelStyle:  TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            unselectedLabelStyle:  TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.normal,
              color: Colors.white,
           
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.black54,
            indicator: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white,
                  width: 3.0,
                ),
              ),
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Find by location, name',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildCourseList('Programming'),
                    _buildCourseList('English'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseList(String courseType) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Courses')
          .where('course_Type', isEqualTo: courseType)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final courses = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'courseId': data['courseId'] as String? ?? '',
            'title': data['course_name'] as String? ?? '',
            'location': data['course_subdistrict'] as String? ?? '',
            'schedule': data['course_open_days']?.join(', ') as String? ?? 'No open days available',
            'description': data['course_description'] as String? ?? '',
            'number': data['course_phone_number'] as String? ?? '',
            'ownerId': data['ownerId'] as String? ?? '',
            'pricing': data['course_pricing'] as String? ?? '',
            'image': data['course_image_url'] as String? ?? 'assets/image/adminprofile.png',
            'email': data['course_email'] as String? ?? '', // Assuming owner email is stored in course document
            'type': data['course_Type'] as String? ?? '',
          };
        }).toList();

        // Filter courses based on search query
        final filteredCourses = courses.where((course) {
          final title = course['title']!.toLowerCase();
          final location = course['location']!.toLowerCase();
          return title.contains(_searchQuery) || location.contains(_searchQuery);
        }).toList();

        if (filteredCourses.isEmpty) {
          return Center(
            child: Text(
              'No courses found',
              style: TextStyle(fontSize: 18.0, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredCourses.length,
          itemBuilder: (context, index) {
            final course = filteredCourses[index];
            return CourseCard(course: course);
          },
        );
      },
    );
  }
}

class CourseCard extends StatelessWidget {
  final Map<String, String> course;

  const CourseCard({required this.course, super.key});

  Future<String> _fetchOwnerName(String ownerId) async {
    final docSnapshot = await FirebaseFirestore.instance.collection('Users').doc(ownerId).get();
    if (docSnapshot.exists) {
      return docSnapshot.data()?['username'] as String? ?? 'Unknown Owner';
    } else {
      return 'Unknown Owner';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4.0),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: ListTile(
        leading: Image.network(
          course["image"]!,
          fit: BoxFit.cover,
          width: 60,
          height: 60,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              'assets/image/adminprofile.png', // Add a placeholder image in your assets
              fit: BoxFit.cover,
              width: 60,
              height: 60,
            );
          },
        ),
        title: Text(course["title"]!, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(course["location"]!),
            Text(course["schedule"]!),
            Text(
              course["description"]!,
              style: const TextStyle(
                overflow: TextOverflow.ellipsis,
                fontSize: 12.0,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 4),
            FutureBuilder<String>(
              future: _fetchOwnerName(course["ownerId"]!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text('Loading owner name...');
                } else if (snapshot.hasError) {
                  return const Text('Error loading owner name');
                } else {
                  return Text('by ${snapshot.data}', style: const TextStyle(fontWeight: FontWeight.bold));
                }
              },
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CourseAdminDetailPage(course: course),
            ),
          );
        },
      ),
    );
  }
}
