// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_manager/components/LoadingWidget.dart';
import 'package:event_manager/components/bottomNav.dart';
import 'package:event_manager/components/components.dart';
import 'package:event_manager/components/constants.dart';
import 'package:event_manager/components/provider.dart';
import 'package:event_manager/screens/admin.dart';
import 'package:event_manager/screens/adminPanel.dart';
import 'package:event_manager/screens/mainscreen.dart';
import 'package:event_manager/screens/signup_screen.dart';
import 'package:event_manager/shared/functions.dart';

import 'package:event_manager/shared/routes.dart';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:loading_overlay/loading_overlay.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  static String id = 'login_screen';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Future<bool> checkAdmin(String email) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final isAdmin = snapshot.docs.first.data()['isAdmin'] ?? false;
        return isAdmin;
      }
    } catch (e) {
      print('Error checking admin status: $e');
    }
    return false;
  }

  void _navigateToMainScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BottomTabsPage(),
      ),
    );
  }

  Future<String> _fetchUserIdFromFirestore(String email) async {
    String userId = '';
    try {
      // Query Firestore to find the user document with the given email
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: email)
              .get();

      // If there is exactly one user document with the given email, extract the user ID
      if (querySnapshot.docs.length == 1) {
        userId = querySnapshot.docs.first.id;
      } else {
        // Handle the case where there are multiple or no user documents with the given email
        // You can log an error or handle it according to your application's logic
        print(
            'Error: Found ${querySnapshot.docs.length} user documents with email $email');
      }
    } catch (e) {
      // Handle any errors that occur during the Firestore query
      print('Error fetching user ID from Firestore: $e');
    }
    return userId;
  }

  Future<String?> getDeviceId(String userId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        return userDoc['deviceId'];
      } else {
        return null;
      }
    } catch (e) {
      print('Error getting deviceId: $e');
      return null;
    }
  }

  bool isUserLoggedIn = false;
  Future<String?> _fetchUserdocIdFromFirestore(String email) async {
    String? userId;
    try {
      // Query Firestore to find the user document with the given email
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: email)
              .get();

      // If there is exactly one user document with the given email, extract the user ID
      if (querySnapshot.docs.length == 1) {
        userId = querySnapshot.docs.first.id;
      } else if (querySnapshot.docs.isEmpty) {
        // Handle the case where there is no user document with the given email
        print('No user found with email $email');
      } else {
        // Handle the case where there are multiple user documents with the given email
        print('Found multiple user documents with email $email');
      }
    } catch (e) {
      // Handle any errors that occur during the Firestore query
      print('Error fetching user ID from Firestore: $e');
    }
    return userId;
  }

  Future<String?> _fetchUsernameFromFirestore(String email) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final userData = snapshot.docs.first.data();
        return userData['username'];
      }
    } catch (e) {
      print('Error fetching username from Firestore: $e');
    }
    return null;
  }

  void _navigateToAdminScreen(BuildContext context) async {
    // Fetch user data from Firestore based on _email
    QuerySnapshot<Map<String, dynamic>> querySnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: _email)
            .limit(1) // Limit to 1 document
            .get();
    setState(() {
      isUserLoggedIn = true;
    });

    // Check if there's a document with the specified email
    if (querySnapshot.docs.isNotEmpty) {
      DocumentSnapshot<Map<String, dynamic>> snapshot =
          querySnapshot.docs.first;

      // Extract email and username from the snapshot
      String? email = snapshot.data()?['email'] as String?;
      String? username = snapshot.data()?['username'] as String?;
      String? deviceid = snapshot.data()?['deviceId'] as String?;
      String userdocid = snapshot.id;
      // Save email and username to SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('email', email!);
      await prefs.setString('username', username!);
      await prefs.setString('userdocidforadmin', userdocid!);
      await prefs.setString('devicdeid', deviceid!);

      await prefs.setBool('isAdminLoggedIn', true);
      // Log in the user using FirebaseAuth
      try {
        UserCredential userCredential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email!,
          password: _password, // Provide the user's password here
        );

        // Set the login state
        await prefs.setBool('isLoggedIn', true);

        // Navigate to the AdminPanelScreen with fetched data
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AdminPanelScreen(),
          ),
        );
      } on FirebaseAuthException catch (e) {
        // Handle authentication errors
        print('Error signing in: $e');
        _setSavingState(false);
        _showSnackBar('Error signing in: ${e.message}');
      }
    } else {
      // Handle case where no user document is found for the given email
      _setSavingState(false);
      _showSnackBar('No user found with the specified email.');
    }
  }

  void _showErrorDialog() {
    _setSavingState(false);
    signUpAlert(
      context: context,
      onPressed: () => _setSavingState(false),
      title: 'WRONG PASSWORD OR EMAIL',
      desc: 'Confirm your email and password and try again',
      btnText: 'Try Again',
    ).show();
  }

  void _setSavingState(bool value) {
    if (context.mounted) {
      setState(() {
        _saving = value;
      });
    }
  }

  final _auth = FirebaseAuth.instance;
  late String _email = '';
  late String _password = '';
  late String _username = '';
  late String _deviceid = '';
  bool _saving = false;
  bool isAdminCheckButton = false;
  final userCredential = ValueNotifier<UserCredential?>(null);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Stack(children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  //  const TopScreenImage(screenImageName: 'logo.png'),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const ScreenTitle(title: 'Login'),
                        const Text(
                          'Login to your account',
                          style: TextStyle(fontSize: 14, color: Colors.white),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: CustomTextField(
                            icon: const Icon(Icons.person),
                            textField: TextField(
                                onChanged: (value) {
                                  _email = value;
                                },
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                                decoration: kTextInputDecoration.copyWith(
                                    hintText: 'Email')),
                          ),
                        ),
                        CustomTextField(
                          icon: const Icon(Icons.password),
                          textField: TextField(
                            obscureText: true,
                            onChanged: (value) {
                              _password = value;
                            },
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            decoration: kTextInputDecoration.copyWith(
                                hintText: 'Password'),
                          ),
                        ),
                        Row(
                          children: [
                            Checkbox(
                              activeColor: Colors.red,
                              checkColor: Colors.white,
                              value: isAdminCheckButton,
                              onChanged: (bool? value) {
                                setState(() {
                                  isAdminCheckButton = value ?? false;
                                });
                              },
                            ),
                            const Text(
                              'Log in as Admin',
                              style:
                                  TextStyle(fontSize: 14, color: Colors.white),
                            ),
                            Expanded(child: Container()),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10.0),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SignUpScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  "Sign up",
                                  style: TextStyle(
                                    color: kTextColor,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10.0,
                              ),
                              child: CustomBottomScreen(
                                textButton: 'Login',
                                heroTag: 'login_btn',
                                buttonPressed: () async {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  setState(() {
                                    _saving = true;
                                  });

                                  if (_email.isEmpty || _password.isEmpty) {
                                    _setSavingState(false);
                                    _showSnackBar(
                                        'Email and password cannot be empty.');
                                    return;
                                  }
                                  if (isAdminCheckButton) {
                                    final bool isAdmin =
                                        await checkAdmin(_email);
                                    if (isAdmin) {
                                      SharedPreferences prefs =
                                          await SharedPreferences.getInstance();
                                      await prefs.setBool('isLoggedIn', true);
                                      await prefs.setBool('isAdmin', true);
                                      await prefs.setBool('isUser', false);

                                      _navigateToAdminScreen(context);
                                    } else {
                                      _setSavingState(false);
                                      _showSnackBar(
                                          'You are not authorized to log in as admin.');
                                    }
                                  } else {
                                    try {
                                      final UserCredential userCredential =
                                          await _auth
                                              .signInWithEmailAndPassword(
                                        email: _email,
                                        password: _password,
                                      );

                                      final User? user = userCredential.user;

                                      if (user != null) {
                                        final username =
                                            await _fetchUsernameFromFirestore(
                                                _email);
                                        String userId =
                                            await _fetchUserIdFromFirestore(
                                                _email);
                                        String? userId2 =
                                            await _fetchUserdocIdFromFirestore(
                                                _email);
                                        String? deviceid =
                                            await _fetchUserdocIdFromFirestore(
                                                _deviceid);
                                        SharedPreferences prefs =
                                            await SharedPreferences
                                                .getInstance();
                                        await prefs.clear();
                                        await prefs.setString('email', _email);
                                        await prefs.setString(
                                            'username', username!);
                                        await prefs.setString(
                                            'userid', userId!);
                                        await prefs.setString(
                                            'userdocid', userId2!);
                                        await prefs.setBool(
                                            'isUserLoggedIn', true);

                                        await prefs.setBool('isLoggedIn', true);
                                        await prefs.setBool('isAdmin', false);
                                        await prefs.setBool('isUser', true);
                                        await prefs.setString(
                                            'devicdid', username!);
                                        print('object');
                                        print(userId2);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const BottomTabsPage(),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      _showErrorDialog();
                                    } finally {
                                      _setSavingState(false);
                                    }
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () async {
                                try {
                                  await FirebaseAuth.instance
                                      .sendPasswordResetEmail(email: _email);
                                  _showSnackBar('Password reset email sent.');
                                } catch (e) {
                                  _showErrorDialog();
                                }
                              },
                              child: const SizedBox(
                                height: 50,
                                child: Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(
                          color: Colors.red,
                        ),
                        // Padding(
                        //   padding: const EdgeInsets.symmetric(vertical: 8.0),
                        //   child: const Row(
                        //     mainAxisAlignment: MainAxisAlignment.center,
                        //     crossAxisAlignment: CrossAxisAlignment.center,
                        //     children: [
                        //       Text(
                        //         'Or Sign in using',
                        //         style: TextStyle(
                        //           color: Colors.white,
                        //           fontSize: 16,
                        //         ),
                        //       )
                        //     ],
                        //   ),
                        // ),
                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.center,
                        //   children: [
                        //     ValueListenableBuilder(
                        //         valueListenable: userCredential,
                        //         builder: (BuildContext context, value,
                        //             Widget? child) {
                        //           return IconButton(
                        //             onPressed: () async {
                        //               userCredential.value =
                        //                   await SignIn().signInWithGoogle();

                        //               if (userCredential.value != null) {
                        //                 print(
                        //                     userCredential.value!.user!.email);
                        //                 _navigateToMainScreen();
                        //               }
                        //             },
                        //             icon: CircleAvatar(
                        //               radius: 25,
                        //               backgroundColor: Colors.transparent,
                        //               child: Image.asset(
                        //                   'assets/images/icons/google.png'),
                        //             ),
                        //           );
                        //         }),
                        //   ],
                        // ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_saving) Center(child: loadingWidget())
            ]),
          ),
        ]),
      ),
    );
  }
}
