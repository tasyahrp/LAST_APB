class Syllabus {
  final String courseId;
  final String syllabusId;
  final int syllabusMeetings;
  final String syllabusTitles;

  Syllabus({
    required this.courseId,
    required this.syllabusId,
    required this.syllabusMeetings,
    required this.syllabusTitles,
  });

  factory Syllabus.fromMap(Map<String, dynamic> data) {
    return Syllabus(
      courseId: data['courseId'] as String? ?? '',
      syllabusId: data['syllabusId'] as String? ?? '',
      syllabusMeetings: data['syllabusMeetings'] as int? ?? 0,
      syllabusTitles: data['syllabusTitles'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'syllabusId': syllabusId,
      'syllabusMeetings': syllabusMeetings,
      'syllabusTitles': syllabusTitles,
    };
  }
}
