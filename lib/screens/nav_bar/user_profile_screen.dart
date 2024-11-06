import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  Future<Map<String, dynamic>?> _getUserDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('users') // Adjust the collection name as needed
          .doc(user.uid)
          .get();
      return snapshot.data() as Map<String, dynamic>?;
    }
    return null; // Return null if no user is signed in
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300], // Lighter background to match home screen
      appBar: AppBar(
        title: const Text(
          'User Profile',
          style: TextStyle(color: Colors.white), // White text in AppBar
        ),
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.8), // Matching home screen AppBar
        iconTheme: const IconThemeData(color: Colors.white), // White back button
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _getUserDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data != null) {
            final userDetails = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Name: ${userDetails['firstName']} ${userDetails['lastName']}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text('Email: ${userDetails['email']}', style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 10),
                  Text('Phone: ${userDetails['phone'] ?? 'N/A'}', style: const TextStyle(fontSize: 18)),
                  // Add more fields as necessary
                ],
              ),
            );
          } else {
            return const Center(child: Text('No user signed in.'));
          }
        },
      ),
    );
  }
}
