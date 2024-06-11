import 'package:flutter/material.dart';

class NotificationDialog extends StatelessWidget {
  final String message;

  const NotificationDialog({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Center(child:  Text('Notification !')),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}
