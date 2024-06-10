import 'package:flutter/material.dart';

class NewCourseBanner extends StatelessWidget {


  const NewCourseBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color.fromARGB(255, 68, 24, 104), Color.fromARGB(255, 120, 9, 139)],
              begin: Alignment.topLeft,
              end: Alignment.bottomCenter,
            ),
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'New Course!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'UI-UX Research',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  ElevatedButton(
                    onPressed: (){},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 245, 91, 212),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('View Now', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
            Image.asset('assets/image/newcourse.png', height: 120, fit: BoxFit.contain),
          ],
        ),
      ),
    );
  }
}
