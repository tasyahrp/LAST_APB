import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'component/pages/loginpage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const EduLocalApp());
}

class EduLocalApp extends StatelessWidget {
  const EduLocalApp({super.key});
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'EduLocal',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins', // Set default font to Poppins
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w300),
          displayMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w300),
          displaySmall: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400),
          headlineMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400),
          headlineSmall: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400),
          titleLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500),
          titleMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400),
          titleSmall: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400),
          bodyMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400),
          labelLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500),
          bodySmall: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400),
          labelSmall: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400),
        ),
      ),
      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void navigateToLogin() {
    Get.to(() => const LoginRegisterScreen(), transition: Transition.rightToLeft, duration: const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4A1C6F),
      body: Container(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 10),
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 24,
                  fontFamily: 'Poppins',
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: 'Welcome to\n',
                    style: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 20.0,
                      color: Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
                  TextSpan(
                    text: 'EduLocal',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 45.0,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Image.asset(
              'assets/image/image2.png',
              height: 360,
            ),
            const Text(
              "Find and join classes that ignite your passion and fit your pace. Explore. Learn. Grow!",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color.fromARGB(191, 255, 255, 255)),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: IconButton(
                icon: const Icon(Icons.arrow_forward, color: Colors.white),
                onPressed: navigateToLogin,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
