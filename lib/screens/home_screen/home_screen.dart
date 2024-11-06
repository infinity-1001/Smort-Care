import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../nav_bar/user_profile_screen.dart';
import '../nav_bar/connect_smort_screen.dart';
import 'medication_list.dart';
import 'add_medication_screen.dart';
import '../notifications_screen.dart';
import 'package:flutter/services.dart';
import 'package:badges/badges.dart' as badges;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? smortId;
  List<Map<String, dynamic>> medications = [];
  bool isLoading = true;
  int _unreadNotificationsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _listenToNotifications();
  }

  void _listenToNotifications() {
    FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _unreadNotificationsCount = snapshot.docs.length;
      });
    });
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        setState(() {
          smortId = userData['smortId'];
        });
        if (smortId != null) {
          await _fetchMedications();
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchMedications() async {
    try {
      if (smortId != null) {
        final medicationsSnapshot = await FirebaseFirestore.instance
            .collection('smort')
            .doc(smortId)
            .collection('medications')
            .get();
        setState(() {
          medications = medicationsSnapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
      }
    } catch (e) {
      print('Error fetching medications: $e');
    }
  }

  Future<void> _disconnectSmort() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'smortId': null});
        setState(() {
          smortId = null;
          medications = [];
        });
      }
    } catch (e) {
      print('Error disconnecting Smort: $e');
    }
  }

  Future<void> _deleteMedication(String id) async {
    // Show confirmation dialog
    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Do you want to delete this medication?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    ) ?? false;

    // If user confirmed, proceed with deletion
    if (confirmDelete) {
      try {
        if (smortId != null && id.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('smort')
              .doc(smortId)
              .collection('medications')
              .doc(id)
              .delete();
          await _fetchMedications();
        } else {
          throw Exception('Invalid smortId or medication id');
        }
      } catch (e) {
        print('Error deleting medication: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete medication: $e')),
        );
      }
    }
  }

  Future<void> _signOut() async {
    // Show confirmation dialog
    bool confirmLogout = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Do you want to log out?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Logout'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    ) ?? false;

    // If user confirmed, proceed with logout
    if (confirmLogout) {
      try {
        await FirebaseAuth.instance.signOut();
        Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
      } catch (e) {
        print('Error signing out: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sign out: $e')),
        );
      }
    }
  }

  Future<bool> _onWillPop() async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Do you want to exit the app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => SystemNavigator.pop(),
            child: const Text('Yes'),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Text(
          'Smort Care',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.8),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          badges.Badge(
            position: badges.BadgePosition.topEnd(top: 0, end: 3),
            showBadge: _unreadNotificationsCount > 0,
            badgeContent: Text(
              _unreadNotificationsCount.toString(),
              style: const TextStyle(color: Colors.white),
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                );
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _signOut,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        if (smortId != null) ...[
                          MedicationList(
                            medications: medications,
                            onDelete: _deleteMedication,
                            smortId: smortId!,
                            onUpdate: _fetchMedications,
                            onDisconnect: _disconnectSmort,
                          ),
                        ] else
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'To view schedule and modify medications, connect your Smort device.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 16, color: Colors.black87),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).primaryColor,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const ConnectSmortScreen()),
                                    ).then((_) => _loadUserData());
                                  },
                                  child: const Text('Connect Smort', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (smortId != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                        ),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddMedicationScreen(smortId: smortId!),
                            ),
                          );
                          if (result == true) {
                            _fetchMedications();
                          }
                        },
                        child: const Text('Add Medication', style: TextStyle(fontSize: 18, color: Colors.white)),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
