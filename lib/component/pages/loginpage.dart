import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/gestures.dart';
import 'signuppage.dart';
import 'homepage.dart';
import 'adminpage.dart';
import 'package:page_transition/page_transition.dart';
import '../../Controller/firebase_auth_services.dart';

class LoginRegisterScreen extends StatefulWidget {
  const LoginRegisterScreen({super.key});

  @override
  State<LoginRegisterScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginRegisterScreen> {
  final FirebaseAuthService _auth = FirebaseAuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Sign In', style: TextStyle(color: Color.fromARGB(218, 255, 255, 255))),
        backgroundColor: const Color(0xFF4A1C6F),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF4A1C6F),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0), // Add padding around the content
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - kToolbarHeight - MediaQuery.of(context).padding.top,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 1), // Add space before the content
                      Image.asset(
                        'assets/image/Login.png',
                        height: MediaQuery.of(context).size.height * 0.2, // 20% of screen height
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        'Sign In',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white, fontSize: 12.0),
                        decoration: InputDecoration(
                          labelText: 'Email',
                          hintText: 'Enter your email',
                          prefixIcon: Icon(Icons.email, color: Colors.white.withOpacity(0.4)),
                          hintStyle: TextStyle(fontSize: 14.0, color: Colors.white.withOpacity(0.6)),
                          labelStyle: const TextStyle(color: Colors.white30, fontSize: 12.0, fontWeight: FontWeight.w600),
                          border: const OutlineInputBorder(),
                          fillColor: const Color(0x406F1EAB).withOpacity(0.4),
                          filled: true,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        style: const TextStyle(color: Colors.white,fontSize: 12.0),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter your password',
                          prefixIcon: Icon(Icons.lock, color: Colors.white.withOpacity(0.4)),
                          hintStyle: TextStyle(fontSize: 14.0, color: Colors.white.withOpacity(0.6)),
                          labelStyle: const TextStyle(color: Colors.white30, fontSize: 12.0, fontWeight: FontWeight.w700),
                          border: const OutlineInputBorder(),
                          fillColor: const Color(0x406F1EAB).withOpacity(0.4),
                          filled: true,
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 60),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            _signIn();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                          ),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Or',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _signInWithGoogle();
                          },
                          icon: Image.asset('assets/image/google.png', height: 24), // Update this to your Google icon path
                          label: const Text('Sign in with Google', style: TextStyle(color: Colors.white)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white),
                            backgroundColor: const Color.fromARGB(0, 255, 255, 255),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              const TextSpan(
                                text: "Don't have an account? ",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 16.0,
                                ),
                              ),
                              TextSpan(
                                text: "Sign Up",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16.0,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.of(context).push(
                                      PageTransition(
                                        type: PageTransitionType.topToBottom,
                                        child: SignUpScreen(),
                                        duration: const Duration(milliseconds: 300), // Specify the duration here
                                      ),
                                    );
                                  },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(flex: 1), // Add space after the content
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signIn() async {
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      User? user = await _auth.signInWithEmailAndPassword(email, password);

      if (user != null) {
        if (!mounted) return; // Check if the widget is still mounted
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Center(child: CircularProgressIndicator());
          },
        );

        DocumentSnapshot<Map<String, dynamic>> userDoc =
            await _firestore.collection('Users').doc(user.uid).get();

        if (!mounted) return; // Check again if the widget is still mounted
        Navigator.of(context).pop();

        if (userDoc.exists) {
          String role = userDoc.data()?['role'] ?? 'regular';

          if (role == "admin") {
            if (!mounted) return; // Check again if the widget is still mounted
            Navigator.of(context).pushReplacement(
                PageTransition(type: PageTransitionType.rightToLeft, child: const AdminPage()));
          } else {
            if (!mounted) return; // Check again if the widget is still mounted
            Navigator.of(context).pushReplacement(
                PageTransition(type: PageTransitionType.rightToLeft, child: const Homepage()));
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User not found in the database.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error signing in'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showLoadingDialog() {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return const Center(child: CircularProgressIndicator());
    },
  );
}

void _hideLoadingDialog() {
  Navigator.of(context, rootNavigator: true).pop();
}


  Future<void> _signInWithGoogle() async {
    try {
      _showLoadingDialog();
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        // Check if user exists in Firestore
        DocumentSnapshot<Map<String, dynamic>> userDoc =
            await _firestore.collection('Users').doc(user.uid).get();

        if (!userDoc.exists) {
          // If user doesn't exist, create a new document
          await _firestore.collection('Users').doc(user.uid).set({
            'uid': user.email,
            'email': user.email,
            'username' : user.displayName ?? 'Unknown',
            'phone_number' : user.phoneNumber ?? "0",
            'isRequestOwner' : false,
            'role': 'Student', // Set default role as 'regular'
            // Add any additional fields you want to store
          });
        }

        String role = userDoc.data()?['role'] ?? 'Student';

          _hideLoadingDialog();

        if (role == "admin") {
          if (!mounted) return; // Check again if the widget is still mounted
          Navigator.of(context).pushReplacement(
              PageTransition(type: PageTransitionType.rightToLeft, child: const AdminPage()));
        } else {
          if (!mounted) return; // Check again if the widget is still mounted
          Navigator.of(context).pushReplacement(
              PageTransition(type: PageTransitionType.rightToLeft, child: const Homepage()));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
