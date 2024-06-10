import 'package:cloud_firestore/cloud_firestore.dart';

class FetchUserData {
  final CollectionReference userList = FirebaseFirestore.instance.collection('Users');

  Future<void> createUserData(
      String User_id, String username, String email, String password, String role) async {
    return await userList.doc(User_id).set({
      'username': username,
      'email': email,
      'password': password,
      'role': role,
    });
  }

  Future<List<Map<String, dynamic>>> getUserList() async {
    List<Map<String, dynamic>> itemList = [];
    try {
      await userList.get().then((QuerySnapshot querySnapshot) {
        querySnapshot.docs.forEach((element) {
          itemList.add(element.data() as Map<String, dynamic>);
        });
      });
    } catch (e) {
      print(e.toString());
      return [];
    }
    return itemList;
  }
}
