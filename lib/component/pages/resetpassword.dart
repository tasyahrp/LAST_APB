import 'package:flutter/material.dart';
import 'loginpage.dart'; // Import the sign-in page

class ResetPasswordPage extends StatelessWidget {
  const ResetPasswordPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: const Text(
        //   'Reset Password',
        //   style: TextStyle(color: Color.fromARGB(218, 255, 255, 255)),
        // ),
        backgroundColor: const Color(0xFF4A1C6F),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF4A1C6F),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 30), // Adjust the space at the top
              const Text(
                'Enter New Password',
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                'Your new password should be different from your previous password',
                style: TextStyle(color: Color.fromARGB(183, 255, 255, 255)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'New password',
                  hintText: 'Enter new password',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                  labelStyle: const TextStyle(
                      color: Color.fromARGB(122, 255, 255, 255)),
                  border: const OutlineInputBorder(),
                  fillColor: const Color(0x406F1EAB).withOpacity(0.4),
                  filled: true,
                ),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Confirm new password', 
                  hintText: 'Enter new password again',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                  labelStyle: const TextStyle(
                      color: Color.fromARGB(122, 255, 255, 255)),
                  border: const OutlineInputBorder(),
                  fillColor: const Color(0x406F1EAB).withOpacity(0.4),
                  filled: true,
                ),
                obscureText: true,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginRegisterScreen()),
                      (Route<dynamic> route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6F1EAB), // Button color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  child: const Text(
                    'Send',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
