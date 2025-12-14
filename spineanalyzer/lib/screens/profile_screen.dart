import 'package:flutter/material.dart';
import 'package:spineanalyzer/resources/strings.dart';

class ProfileScreen extends StatelessWidget {
  final String name;
  final String email;
  const ProfileScreen({Key? key, required this.name, required this.email}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(ProfileStrings.title)),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${ProfileStrings.nameLabel}: $name', style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 16),
            Text('${ProfileStrings.emailLabel}: $email', style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
