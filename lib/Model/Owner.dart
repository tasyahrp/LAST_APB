class Owner {
  final String name;
  final String email;
  final List<Map<String, dynamic>> courses;
  final String docId;

  Owner({
    required this.name,
    required this.email,
    required this.courses,
    required this.docId,
  });
}
