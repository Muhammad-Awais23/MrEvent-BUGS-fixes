import 'package:event_manager/components/LoadingWidget.dart';
import 'package:event_manager/components/constants.dart';
import 'package:event_manager/screens/login_screen.dart';
import 'package:event_manager/shared/routes.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({
    Key? key,
  }) : super(key: key);

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _contactController;
  late TextEditingController _accountNumberController;
  late TextEditingController _bankdetailsController;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _contactController = TextEditingController();
    _accountNumberController = TextEditingController();
    _bankdetailsController = TextEditingController();
    fetchUserDetails();
    _loadUserData();
  }

  late String username = "";
  late String email = "";
  late String userid = "";
  late String userdocid = "";
  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      email = prefs.getString('email') ?? "";

      username = prefs.getString('username') ?? "";
      userid = prefs.getString('userid') ?? "";
      userdocid = prefs.getString('userdocid') ?? "";
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _contactController.dispose();
    _accountNumberController.dispose();
    _bankdetailsController.dispose();
    super.dispose();
  }

  void fetchUserDetails() async {
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
          .instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (snapshot.docs.isNotEmpty) {
        Map<String, dynamic> data = snapshot.docs.first.data();
        setState(() {
          _usernameController.text = data['username'] ?? '';
          _contactController.text = data['contact'] ?? '';
          _accountNumberController.text = data['accountnumber'] ?? '';
          _bankdetailsController.text = data['bankdetails'] ?? '';
          isAdmin = data['isAdmin'] ?? false;
        });
      } else {
        print('No user found with email: ${email}');
      }
    } catch (e) {
      print('Error fetching user details: $e');
    }
  }

  void updateUserDetails() async {
    try {
      setState(() {
        deleteing = true;
      });
      QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
          .instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (snapshot.docs.isNotEmpty) {
        String docId = snapshot.docs.first.id;
        await FirebaseFirestore.instance.collection('users').doc(docId).update({
          'username': _usernameController.text,
          'contact': _contactController.text,
          'accountnumber': isAdmin ? null : _accountNumberController.text,
          'bankdetails': isAdmin ? null : _bankdetailsController.text
        });
        setState(() {
          deleteing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Details updated successfully')));
        Future.delayed(Duration(seconds: 2));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoginScreen(),
          ),
        );
      } else {
        setState(() {
          deleteing = false;
        });
        print('No user found with email: ${email}');
      }
    } catch (e) {
      setState(() {
        deleteing = false;
      });
      print('Error updating user details: $e');
    }
  }

  bool deleteing = false;
  void deleteUserAccount() async {
    try {
      setState(() {
        deleteing = true;
      });
      QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
          .instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (snapshot.docs.isNotEmpty) {
        String docId = snapshot.docs.first.id;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(docId)
            .delete();

        setState(() {
          deleteing = false;
        });
        Future.delayed(const Duration(seconds: 2));
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account deleted successfully')));
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      } else {
        setState(() {
          deleteing = false;
        });
        print('No user found with email: ${email}');
      }
    } catch (e) {
      setState(() {
        deleteing = false;
      });
      print('Error deleting user account: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final _formKey = GlobalKey<FormState>();

    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text('User Profile'),
        backgroundColor: const Color.fromARGB(255, 54, 54, 54),
      ),
      backgroundColor: Colors.grey[900],
      body: Stack(children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _usernameController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Username',
                    labelStyle: TextStyle(color: Colors.white),
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your username';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _contactController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Contact',
                    labelStyle: TextStyle(color: Colors.white),
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your contact';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                if (isAdmin)
                  TextFormField(
                    controller: _accountNumberController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Account Number',
                      labelStyle: TextStyle(color: Colors.white),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your account number';
                      }
                      return null;
                    },
                  ),
                if (isAdmin) SizedBox(height: 10),
                if (isAdmin)
                  TextFormField(
                    controller: _bankdetailsController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Payment method',
                      labelStyle: TextStyle(color: Colors.white),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your payment method';
                      }
                      return null;
                    },
                  ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      updateUserDetails();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kTextColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: const Text(
                    'Update Details',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    bool confirmDelete = await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          backgroundColor: Colors.grey[900],
                          title: const Text(
                            'Confirm Deletion',
                            style: TextStyle(color: Colors.white),
                          ),
                          content: const Text(
                            'Are you sure you want to delete your account? This action cannot be undone.',
                            style: TextStyle(color: Colors.white),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: Colors.black),
                              ),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.grey[300],
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.red[700],
                              ),
                            ),
                          ],
                        );
                      },
                    );

                    if (confirmDelete) {
                      deleteUserAccount();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kTextColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: const Text(
                    'Delete Account',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              ],
            ),
          ),
        ),
        if (deleteing) Center(child: loadingWidget())
      ]),
    );
  }
}
