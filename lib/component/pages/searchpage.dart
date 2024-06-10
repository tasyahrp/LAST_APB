import 'package:flutter/material.dart';
import '../../Model/Course.dart';
import 'coursedetail.dart';

class SearchResultsPage extends StatefulWidget {
  final String query;
  final List<Course> searchResults;

  const SearchResultsPage({required this.query, required this.searchResults, super.key});

  @override
  _SearchResultsPageState createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  String _selectedCourseType = 'All';
  List<Course> _filteredResults = [];

  @override
  void initState() {
    super.initState();
    _filterResults();
  }

  void _filterResults() {
    setState(() {
      if (_selectedCourseType == 'All') {
        _filteredResults = widget.searchResults;
      } else {
        _filteredResults = widget.searchResults.where((course) => course.courseType == _selectedCourseType).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Search Results', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF4A1C6F),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Results for "${widget.query}"',
              style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildFilterBox(),
            const SizedBox(height: 10),
            Expanded(
              child: _filteredResults.isEmpty
                  ? Center(child: Text('No courses found for "${widget.query}"'))
                  : ListView.builder(
                      itemCount: _filteredResults.length,
                      itemBuilder: (context, index) {
                        final course = _filteredResults[index];
                        return _buildCourseCard(context, course);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBox() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          const Text(
            'Filter by: ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: .5,
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCourseType,
                  items: <String>['All', 'Programming', 'English'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedCourseType = newValue!;
                      _filterResults();
                    });
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, Course course) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourseDetailPage(course: course),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        elevation: 5,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  course.courseImageUrl ?? 'assets/image/profile.png',
                  height: 80,
                  width: 80,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.courseName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                 
                    Text(
                      course.courseSubdistrict,
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getFormattedOpenDays(course.courseOpenDays),
                      style: const TextStyle(fontSize: 12, color: Colors.black54, overflow: TextOverflow.visible),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 60,
                      child: Text(
                        course.courseDescription,
                        style: const TextStyle(fontSize: 14, color: Colors.black),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getFormattedOpenDays(List<String> openDays) {
    if (openDays.isEmpty) return "Closed";
    List<String> formattedDays = [];
    String previousDay = "";
    for (String day in openDays) {
      if (previousDay.isEmpty) {
        previousDay = day;
        formattedDays.add(day);
      } else if (dayDifference(previousDay, day) == 1) {
        if (formattedDays.last.contains(" - ")) {
          formattedDays.last = formattedDays.last.split(" - ")[0] + " - " + day;
        } else {
          formattedDays.last += " - " + day;
        }
      } else {
        formattedDays.add(day);
      }
      previousDay = day;
    }
    return formattedDays.join(", ");
  }

  int dayDifference(String start, String end) {
    List<String> days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
    int startIndex = days.indexOf(start);
    int endIndex = days.indexOf(end);
    return endIndex - startIndex;
  }
}
