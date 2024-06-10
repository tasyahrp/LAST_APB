import 'package:firebase_auth/firebase_auth.dart';
class FirebaseAuthService {
  FirebaseAuth _Auth = FirebaseAuth.instance;

  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try{
      UserCredential  credential =await _Auth.signInWithEmailAndPassword(email: email, password: password);
      return credential.user;
    } catch (e) {
      print("Some error Happend");
    }

    return null;
  }
}