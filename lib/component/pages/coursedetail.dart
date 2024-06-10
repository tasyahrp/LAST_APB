import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'formdaftar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../Model/Course.dart';
import '../../Model/Syllabus.dart';
import '../../Model/Comment.dart';
import 'package:timeago/timeago.dart' as timeago;

class CourseDetailPage extends StatefulWidget {
  final Course course;

  const CourseDetailPage({
    required this.course,
    super.key,
  });

  @override
  CourseDetailPageState createState() => CourseDetailPageState();
}

class CourseDetailPageState extends State<CourseDetailPage> {
  bool isDescriptionSelected = true;
  bool isLoved = false;
  String userRole = '';
  double rating = 2.5;
  List<Syllabus> syllabi = [];
  List<Comment> comments = [];
  String Username = '';
  @override
  void initState() {
    super.initState();
    _fetchUserRole();
    _fetchRating();
    fetchSyllabi(widget.course.courseId);
    fetchComments(widget.course.courseId);
    
  }

  

  Future<void> _fetchUserRole() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      try {
        final docSnapshot = await FirebaseFirestore.instance
            .collection('Users')
            .doc(firebaseUser.uid)
            .get();
        if (docSnapshot.exists) {
          setState(() {
            userRole = docSnapshot.data()!['role'] as String;
          });
        } else {
          Text('User document not found');
        }
      } on FirebaseException catch (e) {
        Text('Error fetching user data: $e');
      }
    } else {
      const Text('No signed-in user found');
    }
  }

  Future<void> _fetchRating() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('Courses')
          .doc(widget.course.courseId)
          .get();
      if (docSnapshot.exists) {
        setState(() {
          rating = (docSnapshot.data()!['course_rating'] ?? 0).toDouble();
        });
      } else {
        Text('Course document not found');
      }
    } on FirebaseException catch (e) {
      Text('Error fetching course rating: $e');
    }
  }

  Future<void> fetchSyllabi(String courseId) async {
    try {
      final syllabusQuerySnapshot = await FirebaseFirestore.instance
          .collection('Syllabus')
          .where('courseId', isEqualTo: courseId)
          .get();

      setState(() {
        syllabi = syllabusQuerySnapshot.docs.map((doc) => Syllabus.fromMap(doc.data())).toList();
      });
    } catch (e) {
      
    }
  }

  Future<void> _toggleLove() async {
    setState(() {
      if (isLoved) {
        rating -= 0.3;
        if (rating < 0) {
          rating = 0;
        }
      } else if (rating < 5.0) {
        rating += 0.3;
        if (rating > 5.0) {
          rating = 5.0;
        }
      }
      isLoved = !isLoved;
    });

    try {
      await FirebaseFirestore.instance
          .collection('Courses')
          .doc(widget.course.courseId)
          .update({'course_rating': rating});
    } on FirebaseException catch (e) {
      Text('Error updating course rating: $e');
    }
  }

Future<void> fetchComments(String courseId) async {
  try {
    final commentQuerySnapshot = await FirebaseFirestore.instance
        .collection('Comments')
        .where('courseId', isEqualTo: courseId)
        .get();

    final List<Comment> tempComments = [];
    for (var doc in commentQuerySnapshot.docs) {
      final comment = Comment.fromMap(doc.data());
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(comment.userId)
          .get();

      if (userDoc.exists) {
        comment.username = userDoc.data()!['username'] as String?;
        comment.profileImageUrl = userDoc.data()!['profile_image_url'] as String?;
        print('Fetched username: ${comment.username}');
        print('Fetched profileImageUrl: ${comment.profileImageUrl}');
      }
      tempComments.add(comment);
    }

    setState(() {
      comments = tempComments;
    });
  } catch (e) {
    print('Error fetching comments: $e');
  }
}



  Widget _buildDayWidget(String day, bool isOpen) {
    return Text(
      day.substring(0, 3).toUpperCase(),
      style: TextStyle(
        color: isOpen ? Colors.red : Colors.white,
        fontWeight: isOpen ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  void _showCommentDialog() {
  final TextEditingController commentController = TextEditingController();
  double ratingValue = 1.0;
  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add Comment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: commentController,
                  decoration: const InputDecoration(labelText: 'Comment'),
                ),
                const SizedBox(height: 20),
                const Text('Rating'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      onPressed: () {
                        setState(() {
                          ratingValue = index + 0.2;
                        });
                      },
                      icon: Icon(
                        (ratingValue > index) ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                      ),
                    );
                  }),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (commentController.text.isNotEmpty) {
                    _submitComment(commentController.text, ratingValue);
                    Navigator.of(context).pop();
                  } else {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Error',),
                          content: const Text('Comment cannot be empty.'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        );
                      },
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A1C6F),
                ),
                child: const Text('Submit', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );
    },
  );
}


Future<void> _submitComment(String commentText, double ratingValue) async {
  final firebaseUser = FirebaseAuth.instance.currentUser;
  if (firebaseUser != null) {
    // Check if the comment text exceeds 20 characters
    if (commentText.length > 50) {
      _showCommentTooLongAlert();
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false, // Prevent dismissing the dialog by tapping outside
        builder: (BuildContext context) {
           return AlertDialog(
            content:   Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text("Uploading comment..."),
              ],
            ),
          );
        },
      );

      final commentId = FirebaseFirestore.instance.collection('Comments').doc().id;
      final commentData = {
        'commentId': commentId,
        'userId': firebaseUser.uid,
        'comment': commentText,
        'rating': ratingValue,
        'courseId': widget.course.courseId,
        'timeComment': Timestamp.now(),
      };

      // Add the comment to the 'Comments' collection
      await FirebaseFirestore.instance.collection('Comments').doc(commentId).set(commentData);

      // Update the 'Users' collection by adding the comment ID to the 'comments' array
      final userDocRef = FirebaseFirestore.instance.collection('Users').doc(firebaseUser.uid);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userDoc = await transaction.get(userDocRef);
        if (userDoc.exists) {
          final commentsList = List<String>.from(userDoc.data()!['comments'] ?? []);
          commentsList.add(commentId);
          transaction.update(userDocRef, {'comments': commentsList});
        }
      });

      // Update the 'Courses' collection by adding the comment ID to the 'comments' array and updating the rating
      final courseDocRef = FirebaseFirestore.instance.collection('Courses').doc(widget.course.courseId);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final courseDoc = await transaction.get(courseDocRef);
        if (courseDoc.exists) {
          final commentsList = List<String>.from(courseDoc.data()!['comments'] ?? []);
          commentsList.add(commentId);
          transaction.update(courseDocRef, {'comments': commentsList});

          // Update the course rating based on the new conditions
          double currentRating = courseDoc.data()!['course_rating'] ?? 0.0;
          if (currentRating >= 5.0) {
            currentRating -= 0.2; // Decrease rating by 0.2 if it's equal to or greater than 5.0
          } else {
            currentRating += 0.1; // Increase rating by 0.1 if it's less than 5.0
          }
          currentRating = double.parse(currentRating.toStringAsFixed(1)); // Round to one decimal place
          transaction.update(courseDocRef, {'course_rating': currentRating});
        }
      });

      // Hide the loading indicator
      Navigator.pop(context);

      // Show success alert
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Success"),
            content: Text("Comment uploaded successfully!"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );

      setState(() {
        comments.add(Comment.fromMap(commentData));
      });
    } on FirebaseException catch (e) {
      // Handle error if there is an issue during the comment submission process
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title:  const Text("Error"),
            content: const Text("An error occurred while uploading the comment. Please try again later."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child:const Text("OK"),
              ),
            ],
          );
        },
      );
    }
  }
}

Future<void> _showCommentTooLongAlert() async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Error'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text('Your comment should not exceed 20 characters.'),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    List<String> days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    Map<String, String> dayMap = {
      'Monday': 'MON',
      'Tuesday': 'TUE',
      'Wednesday': 'WED',
      'Thursday': 'THU',
      'Friday': 'FRI',
      'Saturday': 'SAT',
      'Sunday': 'SUN',
    };

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Course detail', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF4A1C6F),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(widget.course.courseImageUrl),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isDescriptionSelected = true;
                          });
                        },
                        child: Text(
                          'DESCRIPTION',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDescriptionSelected ? Colors.purple : Colors.grey,
                          ),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isDescriptionSelected = false;
                          });
                        },
                        child: Text(
                          'SYLLABUS',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: !isDescriptionSelected ? Colors.purple : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.course.courseName,
                              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            if (isDescriptionSelected)
                              Text(
                                widget.course.courseSubdistrict,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isLoved ? Icons.favorite : Icons.favorite_border,
                          color: isLoved ? Colors.red : Colors.grey,
                        ),
                        onPressed: _toggleLove,
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  const SizedBox(height: 25),
                  if (isDescriptionSelected) ...[
                    const Text(
                      'DESCRIPTION',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.course.courseDescription,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'COURSE SCHEDULE',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1B33),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: days.map((day) {
                          return _buildDayWidget(
                            day,
                            widget.course.courseOpenDays.contains(dayMap.entries.firstWhere((element) => element.value == day).key),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'COMMENTS (${comments.length})',
                              style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w800),
                            ),
                            if (userRole != 'Owner Course') // Tambahkan kondisi untuk menampilkan tombol hanya jika bukan pemilik kursus
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: _showCommentDialog,
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    comments.isEmpty ?
                    const Padding(
                      padding:  EdgeInsets.symmetric(vertical:16.0),
                      child:  Center(
                        child: Text(
                          'Jadilah orang pertama yang berkomentar',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ),
                    )
                    :
                    Container(
                      height: 190, // Atur tinggi container sesuai kebutuhan Anda
                      child: ListView.builder(
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          return CommentWidget(
                            name: comments[index].username ?? "Unknown",
                            comment: comments[index].comment,
                            timeComment: comments[index].timeComment,
                            profileImageUrl: comments[index].profileImageUrl,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'OVERALL RATING',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Padding(
                    padding: const EdgeInsets.fromLTRB(0, 20.0, 0, 50.0),
                    child: Center(
                      child: Column(
                        children: [
                          Text(
                            rating.toStringAsFixed(1), // Menggunakan nilai rating yang sebenarnya
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              // Menampilkan bintang sesuai dengan nilai rating
                              return Icon(
                                index < rating ? Icons.star : Icons.star_border,
                                color: index < rating ? Colors.amber : Colors.grey,
                              );
                            }),
                          ),
                          Text(
                            'Based on ${comments.length} Reviews', // Menggunakan jumlah komentar yang sebenarnya
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ] else ...[
                    SyllabusSection(syllabi: syllabi),
                  ],
                  if (userRole != 'Owner Course')
                    Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 20),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => FormDaftar(
                                  courseType: widget.course.courseType,
                                  courseName: widget.course.courseName,
                                  courseId: widget.course.courseId,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A1C6F), // Warna latar belakang ungu
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(40),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                            minimumSize: const Size(double.infinity, 50), // Tombol menjadi lebih lebar
                          ),
                          child: const Text(
                            'DAFTAR',
                            style: TextStyle(color: Colors.white, fontSize: 16.0), // Warna teks menjadi putih
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String url) {
    return ClipRRect(
      child: url.isEmpty || Uri.tryParse(url)?.hasAbsolutePath != true
          ? Image.asset(
              'assets/image/adminprofile.png',
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
            )
          : Image.network(
              url,
              height: 300,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  'assets/image/adminprofile.png',
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                );
              },
            ),
    );
  }
}

class CommentWidget extends StatelessWidget {
  final String name;
  final String comment;
  final DateTime timeComment;
  final String? profileImageUrl;

  const CommentWidget({
    required this.name,
    required this.comment,
    required this.timeComment,
    this.profileImageUrl,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    String timeAgo = timeago.format(timeComment, locale: 'en_short');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: profileImageUrl != null
                ? NetworkImage(profileImageUrl!)
                : AssetImage('assets/image/person_icon.png') as ImageProvider,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Text(
                  comment,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 3),
                Text(
                  'Post sent | $timeAgo ago',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class SyllabusSection extends StatelessWidget {
  final List<Syllabus> syllabi;

  const SyllabusSection({required this.syllabi, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(syllabi.length, (index) => _buildSyllabusItem(syllabi[index], index + 1)),
    );
  }

  Widget _buildSyllabusItem(Syllabus syllabus, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent), // Hide the line
        child: ExpansionTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF4A1C6F),
            child: Text('$index', style: const TextStyle(color: Colors.white)),
          ),
          title: Text(syllabus.syllabusTitles),
          subtitle: Text('${syllabus.syllabusMeetings} Topics'),
          children: const [
            ListTile(title: Text('Topic Details Will be here Soon')),
          ],
        ),
      ),
    );
  }
}
