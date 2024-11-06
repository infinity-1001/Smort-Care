import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConnectSmortScreen extends StatefulWidget {
  const ConnectSmortScreen({super.key});

  @override
  _ConnectSmortScreenState createState() => _ConnectSmortScreenState();
}

class _ConnectSmortScreenState extends State<ConnectSmortScreen> {
  final _formKey = GlobalKey<FormState>();
  final _smortIdController = TextEditingController();
  bool _isLoading = false;

  Future<void> _connectSmort() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception('User not logged in');
        }
        final smortId = _smortIdController.text.trim();
        final smortDoc = await FirebaseFirestore.instance.collection('smort').doc(smortId).get();
        if (!smortDoc.exists) {
          throw Exception('Invalid Smort ID');
        }
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'smortId': smortId});
        Navigator.of(context).pop(true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300], // Lighter background to match home screen
      appBar: AppBar(
        title: const Text(
          'Connect Smort',
          style: TextStyle(color: Colors.white), // White text in AppBar
        ),
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.8), // Matching home screen AppBar
        iconTheme: const IconThemeData(color: Colors.white), // White back button
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: Colors.grey[700], // Darker card background
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _smortIdController,
                        decoration: const InputDecoration(
                          labelText: 'Smort ID',
                          labelStyle: TextStyle(color: Colors.white70),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                        ),
                        style: const TextStyle(color: Colors.white),
                        validator: (value) => value!.isEmpty ? 'Please enter a Smort ID' : null,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _connectSmort,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50), // full width button
                        ),
                        child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Connect', style: TextStyle(fontSize: 18)),
                      ),
                    ],
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
