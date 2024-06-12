import 'dart:math';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:custom_rating_bar/custom_rating_bar.dart';
import 'package:event_manager/components/constants.dart';
import 'package:event_manager/screens/adminPanel.dart';
import 'package:event_manager/screens/eventDetailScreen.dart';
import 'package:event_manager/screens/historyscreen.dart';
import 'package:event_manager/screens/models/modle.dart';
import 'package:event_manager/screens/models/popularmodel.dart';
import 'package:event_manager/shared/functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:location/location.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../components/LoadingWidget.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  // final String email;

  const HomeScreen({
    super.key,
  });

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  LocationData? _currentLocation;
  bool _locationDenied = false;
  String tokentosave = "";
  @override
  void initState() {
    _firebaseMessaging.getToken().then((token) {
      tokentosave = token!;

      print("FCM Token: $token");
    });
    super.initState();
    _loadUserData();
    _getCurrentLocation();
    _fetchCarouselData();
    _fetchUsername();
  }

  Future<void> updateDeviceId(String userId, String newDeviceId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({'deviceId': newDeviceId});
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString('devicdeid', tokentosave);
  }

  Future<void> _getCurrentLocation() async {
    Location location = Location();
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        setState(() {
          _locationDenied = true;
        });
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        setState(() {
          _locationDenied = true;
        });
        return;
      }
    }

    _currentLocation = await location.getLocation();
    setState(() {});
  }

  double _calculateDistance(num lat1, num lon1, num lat2, num lon2) {
    const p = 0.017453292519943295;
    const c = cos;
    final a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  Future<List<CarouselItem>> _fetchCarouselData() async {
    List<CarouselItem> carouselItems = [];

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('carousel')
          .orderBy('order')
          .get();

      snapshot.docs.forEach((doc) {
        carouselItems.add(CarouselItem.fromJson(doc.data()));
      });
    } catch (e) {
      print('Error fetching carousel data: $e');
    }

    return carouselItems;
  }

  late String username = "";
  late String email = "";
  late String userid = "";
  late String userdocid = "";
  late String devicdeid = '';
  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      email = prefs.getString('email') ?? "";
      username = prefs.getString('username') ?? "";
      userid = prefs.getString('userid') ?? "";
      userdocid = prefs.getString('userdocid') ?? "";
      devicdeid = prefs.getString('devicdeid') ?? "";
      getEventsAndScheduleReminders(userdocid);
    });
  }

  Future<String?> getDeviceId(String userId) async {
    try {
      print('Fetching document for userId: $userId');
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      print('Document fetched: ${userDoc.exists}');
      if (userDoc.exists) {
        String deviceId = userDoc['deviceId'];
        print('Device ID: $deviceId');
        return deviceId;
      } else {
        print('Document does not exist for userId: $userId');
        return null;
      }
    } catch (e) {
      print('Error getting deviceId: $e');
      return null;
    }
  }

  Future<void> _fetchUsername() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final userData = snapshot.docs.first.data();
        setState(() {
          username = userData['username'];
        });
      }
    } catch (e) {
      print('Error fetching username: $e');
    }
  }

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  // Future<void> getEventsAndScheduleReminders(String userId) async {
  //   tz.initializeTimeZones();
  //   tz.setLocalLocation(tz.getLocation(
  //       'Asia/Karachi')); // Set local time zone to Pakistan Standard Time

  //   // Query Firestore to get events for the user
  //   QuerySnapshot eventsQuery =
  //       await _db.collection('users').doc(userId).collection('bookings').get();

  //   List<QueryDocumentSnapshot> events = eventsQuery.docs;

  //   for (var event in events) {
  //     // Get event details
  //     String eventName = event['eventName'];
  //     String eventDateString = event['eventDate'];

  //     // Parse event date from string to DateTime
  //     DateTime eventDate = _parseDate(eventDateString);

  //     if (eventDate == null) {
  //       print('Invalid date format for event: $eventName');
  //       continue;
  //     }

  //     // Calculate reminder dates (1 day before event date) at 9:30 AM and 3:00 PM
  //     // DateTime reminderDateMorning = eventDate
  //     //     .subtract(Duration(days: 1))
  //     //     .add(Duration(hours: 10, minutes: 3));
  //     // DateTime reminderDateEvening = eventDate
  //     //     .subtract(Duration(days: 1))
  //     //     .add(Duration(hours: 15, minutes: 0));
  //     DateTime now = DateTime.now();
  //     DateTime testReminderDate = now.add(Duration(seconds: 5));
  //     // Convert DateTime to TZDateTime in Pakistan time zone
  //     tz.TZDateTime scheduledDateMorning = tz.TZDateTime(
  //         tz.getLocation('Asia/Karachi'),
  //         now.year,
  //         now.month,
  //         now.day,
  //         now.second + 30);
  //     tz.TZDateTime scheduledDateEvening = tz.TZDateTime(
  //         tz.getLocation('Asia/Karachi'),
  //         now.year,
  //         now.month,
  //         now.day,
  //         now.minute + 1);

  //     // Schedule notifications
  //     await scheduleNotification(eventName, eventDate, scheduledDateMorning);
  //     await scheduleNotification(eventName, eventDate, scheduledDateEvening);
  //   }
  // }

  Future<void> getEventsAndScheduleReminders(String userId) async {
    await Firebase.initializeApp();

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Karachi'));

    QuerySnapshot eventsQuery = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('bookings')
        .get();

    List<QueryDocumentSnapshot> events = eventsQuery.docs;
    int notificationId = 0;

    for (var event in events) {
      String eventName = event['eventName'];
      String eventDateString = event['eventDate'];

      DateTime eventDate = _parseDate(eventDateString);

      if (eventDate == null) {
        print('Invalid date format for event: $eventName');
        continue;
      }

      if (eventDate.isBefore(DateTime.now())) {
        print('Event date has passed for event: $eventName');
        continue;
      }

      DateTime reminderDateMidnight = eventDate
          .subtract(Duration(days: 1))
          .add(Duration(hours: 12, minutes: 00));
      DateTime reminderDateMorning = eventDate
          .subtract(Duration(days: 1))
          .add(Duration(hours: 10, minutes: 00));

      DateTime reminderdate2 = eventDate
          .subtract(Duration(days: 1))
          .add(Duration(hours: 14, minutes: 52));

      DateTime reminderdate3 = eventDate
          .subtract(Duration(days: 1))
          .add(Duration(hours: 16, minutes: 52));
      tz.TZDateTime scheduledDateMidnight =
          tz.TZDateTime.from(reminderDateMidnight, tz.local);
      tz.TZDateTime scheduledDateMorning =
          tz.TZDateTime.from(reminderDateMorning, tz.local);

      print('Scheduling notifications for event: $eventName');
      print('Scheduled date midnight: $scheduledDateMidnight');
      print('Scheduled date morning: $scheduledDateMorning');

      await scheduleNotification(
          eventName, eventDate, scheduledDateMidnight, notificationId++);
      await scheduleNotification(
          eventName, eventDate, scheduledDateMorning, notificationId++);
    }
  }

  DateTime _parseDate(String dateString) {
    try {
      List<String> parts = dateString.split('/');
      if (parts.length != 3) throw FormatException('Invalid date format');
      int day = int.parse(parts[0]);
      int month = int.parse(parts[1]);
      int year = int.parse(parts[2]);
      return DateTime(year, month, day);
    } catch (e) {
      print('Error parsing date: $dateString, Error: $e');
      return DateTime.now();
    }
  }

  Future<void> scheduleNotification(String eventName, DateTime eventDate,
      tz.TZDateTime reminderDate, int notificationId) async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'your channel id',
      'your channel name',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
    );

    var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    String formattedEventDate = DateFormat('d MMMM yyyy').format(eventDate);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId, // Unique notification id
      'Reminder for $eventName', // Title
      'Event is on $formattedEventDate', // Body
      reminderDate, // Scheduled date and time
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _handleLogout() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final GoogleSignIn googleSignIn = GoogleSignIn();

    try {
      await auth.signOut();
      await googleSignIn.signOut();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      await prefs.setBool('isAdmin', false);
      await prefs.setBool('isUser', false);
      await prefs.clear();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      print('Error logging out: $e');
    }
  }

  Future<List<DocumentSnapshot>> _getFilteredEvents(
      List<DocumentSnapshot> users) async {
    List<DocumentSnapshot> filteredEvents = [];

    for (var user in users) {
      var eventsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .collection('events')
          .get();

      var events = eventsSnapshot.docs;

      for (var event in events) {
        var data = event.data() as Map<String, dynamic>;
        num eventLat = data['latitude'];
        num eventLon = data['longitude'];

        double distance = _calculateDistance(
          _currentLocation!.latitude!,
          _currentLocation!.longitude!,
          eventLat,
          eventLon,
        );

        if (distance <= 50.0) {
          filteredEvents.add(event);
        }
      }
    }

    return filteredEvents;
  }

  Future<String> getAdminId(String eventId) async {
    String adminId = '';

    // Query Firestore to find the admin ID whose event you tapped
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('isAdmin', isEqualTo: true)
        .get();

    for (QueryDocumentSnapshot doc in querySnapshot.docs) {
      QuerySnapshot eventSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(doc.id)
          .collection('events')
          .where(FieldPath.documentId, isEqualTo: eventId)
          .get();

      if (eventSnapshot.docs.isNotEmpty) {
        adminId = doc.id; // This is the admin's user ID
        break;
      }
    }

    print('Admin ID: $adminId');
    return adminId;
  }

  @override
  Widget build(BuildContext context) {
    if (userdocid.isNotEmpty) {
      updateDeviceId(userdocid, tokentosave);
      print(tokentosave);
    }
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 51, 51, 51),
        foregroundColor: Colors.white,
        title: const Text('Mr Event'),
      ),
      drawer: Drawer(
        backgroundColor: Colors.black,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
                color: kTextColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (email.isNotEmpty)
                    Text(
                      email!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  if (username.isNotEmpty)
                    Text(
                      username!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.account_box),
              title: const Text(
                'Account',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              onTap: () {
                // Navigate to feedback page
              },
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text(
                'App Language',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              onTap: () {
                // Navigate to feedback page
              },
            ),
            ListTile(
              leading: const Icon(Icons.support),
              title: const Text(
                'Support',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              onTap: () {
                // Navigate to feedback page
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text(
                'Invite a Friend',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              onTap: () {
                // Navigate to feedback page
              },
            ),
            ListTile(
              leading: const Icon(Icons.update),
              title: const Text(
                'App Updates',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              onTap: () {
                // Navigate to contact us page
              },
            ),
            ListTile(
              leading: Icon(Icons.more),
              title: Text(
                'Check More',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              onTap: () async {},
            ),
            ListTile(
                leading: const Icon(Icons.logout),
                title: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                onTap: _handleLogout),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Carousel slider
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: FutureBuilder<List<CarouselItem>>(
                future: _fetchCarouselData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: loadingWidget2());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CarouselSlider(
                          items: snapshot.data!.map((item) {
                            return Builder(
                              builder: (BuildContext context) {
                                return Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15.0),
                                    image: DecorationImage(
                                      image: NetworkImage(item.imageUrl),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 5.0),
                                );
                              },
                            );
                          }).toList(),
                          options: CarouselOptions(
                            aspectRatio: 16 / 9,
                            autoPlay: true,
                            enlargeCenterPage: true,
                          ),
                        ),

                        const SizedBox(height: 20),
                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        //   children: [
                        //     AdminPanelCard(
                        //       title: 'Book Complex',
                        //       onTap: () {
                        //         Navigator.push(
                        //           context,
                        //           MaterialPageRoute(
                        //             builder: (context) => ViewEvents(),
                        //           ),
                        //         );

                        //         // Handle Add Events tap
                        //       },
                        //       imageUrl: 'assets/images/bookevent.png',
                        //     ),
                        //     AdminPanelCard(
                        //       title: 'Manage Profile',
                        //       onTap: () {
                        //         Navigator.push(
                        //           context,
                        //           MaterialPageRoute(
                        //             builder: (context) => UserProfileScreen(
                        //               userEmail: email,
                        //             ),
                        //           ),
                        //         );

                        //         // Handle Add Events tap
                        //       },
                        //       imageUrl: 'assets/images/profile.png',
                        //     ),
                        //     AdminPanelCard(
                        //       title: 'History',
                        //       imageUrl: 'assets/images/history.png',
                        //       onTap: () {
                        //         Navigator.push(
                        //           context,
                        //           MaterialPageRoute(
                        //             builder: (context) =>
                        //                 HistoryScreen(userDocId: userdocid),
                        //           ),
                        //         );
                        //       },
                        //     ),
                        //   ],
                        // ),

                        // Horizontal scrollable cards for different sections/
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Divider(
                            color: Color.fromARGB(255, 82, 82, 82),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(15.0),
                          child: Text(
                            'Popular',
                            style: TextStyle(
                                color: kTextColor,
                                fontSize: 24,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15.0),
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .where('isAdmin', isEqualTo: true)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const loadingWidget2();
                              }
                              var users = snapshot.data!.docs;
                              return SizedBox(
                                width: 300,
                                height: 180,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: users.length,
                                  itemBuilder: (context, index) {
                                    var user = users[index];
                                    return StreamBuilder<QuerySnapshot>(
                                      stream: FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(user.id)
                                          .collection('events')
                                          .orderBy('averageRating',
                                              descending: true)
                                          .snapshots(),
                                      builder: (context, snapshot) {
                                        if (!snapshot.hasData) {
                                          return const loadingWidget2();
                                        }
                                        var events = snapshot.data!.docs;
                                        events.retainWhere((event) => (event
                                                .data() as Map<String, dynamic>)
                                            .containsKey('averageRating'));

                                        if (events.isEmpty) {
                                          return Center(
                                            child: Text(
                                              'no popular event found',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          );
                                        }
                                        return SizedBox(
                                          height: 600,
                                          width: 600,
                                          child: ListView.builder(
                                            shrinkWrap: true,
                                            scrollDirection: Axis.horizontal,
                                            itemCount: events.length,
                                            itemBuilder: (context, index) {
                                              var event = events[index];
                                              var eventData = event.data()
                                                  as Map<String, dynamic>;
                                              if (!eventData.containsKey('imageUrls') ||
                                                  !eventData.containsKey(
                                                      'eventName') ||
                                                  eventData['averageRating'] ==
                                                      null) {
                                                return Container();
                                              }

                                              double rating = 0.0;
                                              if (eventData['averageRating']
                                                  is double) {
                                                rating =
                                                    eventData['averageRating'];
                                              } else if (eventData[
                                                  'averageRating'] is String) {
                                                rating = double.tryParse(
                                                        eventData[
                                                            'averageRating']) ??
                                                    0.0;
                                              }
                                              return GestureDetector(
                                                onTap: () async {
                                                  String adminId =
                                                      await getAdminId(
                                                          event.id.toString());
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          EventDetailsPage(
                                                        eventId: event.id,
                                                        adminId: adminId,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          right: 18.0),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    children: [
                                                      Container(
                                                        height: 170,
                                                        width: 250,
                                                        child: Card(
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        15),
                                                          ),
                                                          elevation: 5,
                                                          child: ClipRRect(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        15),
                                                            child: Container(
                                                              decoration:
                                                                  BoxDecoration(
                                                                gradient:
                                                                    LinearGradient(
                                                                  begin: Alignment
                                                                      .topLeft,
                                                                  end: Alignment
                                                                      .bottomRight,
                                                                  colors: [
                                                                    Colors.red
                                                                        .shade900,
                                                                    Colors.red
                                                                        .shade400
                                                                  ],
                                                                ),
                                                              ),
                                                              child: Column(
                                                                children: [
                                                                  Image.network(
                                                                    eventData[
                                                                        'imageUrls'][0],
                                                                    fit: BoxFit
                                                                        .cover,
                                                                    height: 100,
                                                                    width: 250,
                                                                  ),
                                                                  Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .symmetric(
                                                                      vertical:
                                                                          8.0,
                                                                      horizontal:
                                                                          8.0,
                                                                    ),
                                                                    child:
                                                                        Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .start,
                                                                      children: [
                                                                        Text(
                                                                          eventData[
                                                                              'eventName'],
                                                                          style:
                                                                              const TextStyle(
                                                                            color:
                                                                                Colors.white,
                                                                            fontSize:
                                                                                16,
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                          ),
                                                                        ),
                                                                        Row(
                                                                          children: [
                                                                            RatingBar.readOnly(
                                                                              isHalfAllowed: true,
                                                                              size: 20,
                                                                              filledIcon: Icons.star,
                                                                              emptyIcon: Icons.star_border,
                                                                              halfFilledIcon: Icons.star_half,
                                                                              initialRating: rating,
                                                                              maxRating: 5,
                                                                            ),
                                                                            const SizedBox(width: 4),
                                                                            Text(
                                                                              '${eventData['averageRating']}  ',
                                                                              style: const TextStyle(
                                                                                color: Colors.white,
                                                                                fontSize: 12,
                                                                              ),
                                                                            ),
                                                                            Text(
                                                                              '(${eventData['ratingCount']})',
                                                                              style: const TextStyle(
                                                                                color: Colors.white,
                                                                                fontSize: 12,
                                                                              ),
                                                                            )
                                                                          ],
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 15.0, vertical: 10),
                          child: Text(
                            'Recomended',
                            style: TextStyle(
                                color: kTextColor,
                                fontSize: 24,
                                fontWeight: FontWeight.bold),
                          ),
                        ),

//more widgets
                        _locationDenied
                            ? const Padding(
                                padding: EdgeInsets.only(left: 15.0),
                                child: Text(
                                  'Please Turn on Location to See nearby venues',
                                  style: TextStyle(color: Colors.white),
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 15.0),
                                child: StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('users')
                                      .where('isAdmin', isEqualTo: true)
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return const loadingWidget2();
                                    }
                                    if (_locationDenied) {
                                      return const Center(
                                        child: Text(
                                          'Please turn on location',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      );
                                    }
                                    if (_currentLocation == null) {
                                      return const loadingWidget2();
                                    }

                                    var users = snapshot.data!.docs;

                                    return SizedBox(
                                      width: 300,
                                      height: 300,
                                      child:
                                          FutureBuilder<List<DocumentSnapshot>>(
                                        future: _getFilteredEvents(users),
                                        builder: (context, snapshot) {
                                          if (!snapshot.hasData) {
                                            return const loadingWidget2();
                                          }

                                          var events = snapshot.data!;
                                          if (events.isEmpty) {
                                            return const Center(
                                                child: Text(
                                              'No Recomended Events found',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ));
                                          }
                                          return ListView.builder(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: events.length,
                                            itemBuilder: (context, index) {
                                              var event = events[index];
                                              var eventData = event.data()
                                                  as Map<String, dynamic>;

                                              return GestureDetector(
                                                onTap: () async {
                                                  String adminId =
                                                      await getAdminId(
                                                          event.id.toString());
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          EventDetailsPage(
                                                        eventId: event.id,
                                                        adminId: adminId,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          right: 18.0),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Container(
                                                        height: 170,
                                                        width: 250,
                                                        child: Card(
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        15),
                                                          ),
                                                          elevation: 5,
                                                          child: ClipRRect(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        15),
                                                            child: Container(
                                                              decoration:
                                                                  BoxDecoration(
                                                                gradient:
                                                                    LinearGradient(
                                                                  begin: Alignment
                                                                      .topLeft,
                                                                  end: Alignment
                                                                      .bottomRight,
                                                                  colors: [
                                                                    Colors.red
                                                                        .shade900,
                                                                    Colors.red
                                                                        .shade400
                                                                  ],
                                                                ),
                                                              ),
                                                              child: Column(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .start,
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Image.network(
                                                                    eventData[
                                                                        'imageUrls'][0],
                                                                    fit: BoxFit
                                                                        .cover,
                                                                    height: 100,
                                                                    width: 250,
                                                                  ),
                                                                  Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .symmetric(
                                                                      vertical:
                                                                          8.0,
                                                                      horizontal:
                                                                          8.0,
                                                                    ),
                                                                    child:
                                                                        Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .start,
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .start,
                                                                      children: [
                                                                        Text(
                                                                          eventData[
                                                                              'eventName'],
                                                                          style:
                                                                              const TextStyle(
                                                                            color:
                                                                                Colors.white,
                                                                            fontSize:
                                                                                16,
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                          ),
                                                                        ),
                                                                        Text(
                                                                          eventData[
                                                                              'eventAddress'],
                                                                          maxLines:
                                                                              1,
                                                                          style:
                                                                              const TextStyle(
                                                                            overflow:
                                                                                TextOverflow.ellipsis,
                                                                            color:
                                                                                Colors.white,
                                                                            fontSize:
                                                                                12,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                              )
                      ],
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildHorizontalScrollableCards(List<PopularItems> items) {
    return SizedBox(
      height: 250,
      child: ListView.builder(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Container(
            width: 150,
            margin: const EdgeInsets.symmetric(
                horizontal: 8.0), // Add some margin between cards
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(item.imageUrl),
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  item.title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class EventDetailsScreen extends StatelessWidget {
  final String eventId;

  EventDetailsScreen({required this.eventId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
      ),
      body: FutureBuilder<DocumentSnapshot?>(
        future: _findEvent(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: loadingWidget2());
          }
          var event = snapshot.data;
          if (event == null) {
            return const Center(child: Text('Event not found'));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.network(event['imgUrl'], fit: BoxFit.cover),
                const SizedBox(height: 16),
                Text(event['eventName'],
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Rating: ${event['rating']}'),
                const SizedBox(height: 16),
                Text('Comments: ${event['comment']}'),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<DocumentSnapshot?> _findEvent() async {
    var adminsQuerySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('isAdmin', isEqualTo: true)
        .get();

    for (var adminDoc in adminsQuerySnapshot.docs) {
      var eventDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(adminDoc.id)
          .collection('events')
          .doc(eventId)
          .get();
      if (eventDoc.exists) {
        return eventDoc;
      }
    }
    return null;
  }
}
