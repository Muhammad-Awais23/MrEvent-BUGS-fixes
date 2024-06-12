import 'dart:convert';

import 'package:event_manager/components/LoadingWidget.dart';
import 'package:event_manager/components/components.dart';
import 'package:event_manager/shared/functions.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class AdminBookedEventsScreen extends StatefulWidget {
  const AdminBookedEventsScreen({
    Key? key,
  }) : super(key: key);

  @override
  _AdminBookedEventsScreenState createState() =>
      _AdminBookedEventsScreenState();
}

class _AdminBookedEventsScreenState extends State<AdminBookedEventsScreen> {
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  late String username = "";
  late String email = "";
  late String userid = "";
  late String userdocid = "";
  String useridTosendNotification = "";
  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      email = prefs.getString('email') ?? "";
      username = prefs.getString('username') ?? "";
      userid = prefs.getString('userid') ?? "";
      userdocid = prefs.getString('userdocidforadmin') ?? "";
    });
  }

  TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text('Booked Events'),
        backgroundColor: Colors.grey[900],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CustomTextField2(
              controller: searchController,
              hinttext: 'Search event by name',
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userdocid)
                  .collection('bookedEventsByUsers')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Error: ${snapshot.error}',
                          style: TextStyle(color: Colors.white)));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: loadingWidget2());
                }

                if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text('No booked events found.',
                          style: TextStyle(color: Colors.white)));
                }

                var filteredDocs = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  return data['eventName']
                      .toString()
                      .toLowerCase()
                      .contains(searchQuery.toLowerCase());
                }).toList();

                return ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: filteredDocs.map((DocumentSnapshot document) {
                    Map<String, dynamic> data =
                        document.data() as Map<String, dynamic>;

                    DateTime eventDateTime =
                        DateFormat('dd/MM/yyyy').parse(data['eventDate']);
                    return Card(
                      color: Colors.grey[850],
                      elevation: 3.0,
                      margin: const EdgeInsets.symmetric(
                          vertical: 10.0, horizontal: 8.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              data['eventName'],
                              style: const TextStyle(
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Row(
                              children: [
                                const Icon(Icons.date_range, color: Colors.red),
                                const SizedBox(width: 8.0),
                                Text('Event Date: ${data['eventDate']}',
                                    style: TextStyle(color: Colors.white)),
                              ],
                            ),
                            const SizedBox(height: 5.0),
                            Row(
                              children: [
                                const Icon(Icons.access_time,
                                    color: Colors.red),
                                const SizedBox(width: 8.0),
                                Text('Time Slot: ${data['selectedTimeSlot']}',
                                    style: TextStyle(color: Colors.white)),
                              ],
                            ),
                            const SizedBox(height: 5.0),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    color: Colors.red),
                                const SizedBox(width: 8.0),
                                Text(
                                    'Booking Date: ${_formatTimestamp(data['bookingDate'])}',
                                    style: TextStyle(color: Colors.white)),
                              ],
                            ),
                            const SizedBox(height: 5.0),
                            Row(
                              children: [
                                const Icon(Icons.person, color: Colors.red),
                                const SizedBox(width: 8.0),
                                Text('Booked By: ${data['userName']}',
                                    style: TextStyle(color: Colors.white)),
                              ],
                            ),
                            const SizedBox(height: 5.0),
                            Row(children: [
                              GestureDetector(
                                onTap: () {
                                  contactOnWhatsapp(data['userContact']);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 5.0, horizontal: 10),
                                  decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(10)),
                                  child: const Center(
                                    child: Row(
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.only(right: 5.0),
                                          child: Image(
                                              height: 20,
                                              image: AssetImage(
                                                  'assets/images/whatsapp.png')),
                                        ),
                                        Text(
                                          'Whatsapp',
                                          style: TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  makePhoneCall(data['userContact']);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 5.0),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 5.0, horizontal: 10),
                                    decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    child: const Center(
                                      child: Row(
                                        children: [
                                          Padding(
                                            padding:
                                                EdgeInsets.only(right: 5.0),
                                            child: Image(
                                                height: 20,
                                                image: AssetImage(
                                                    'assets/images/telephone.png')),
                                          ),
                                          Text(
                                            'Call',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ]),
                            eventDateTime.isAfter(DateTime.now())
                                ? data['ConfirmStatus'] == true
                                    ? Padding(
                                        padding: const EdgeInsets.only(
                                            left: 5.0, top: 15),
                                        child: GestureDetector(
                                          onTap: () async {
                                            useridTosendNotification =
                                                (await getDeviceId(
                                                    data['userId']))!;
                                            await FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(userdocid)
                                                .collection(
                                                    'bookedEventsByUsers')
                                                .doc(document.id)
                                                .update(
                                                    {'ConfirmStatus': false});
                                            if (useridTosendNotification
                                                .isNotEmpty) {
                                              SignIn.sendNotification(
                                                  useridTosendNotification,
                                                  "${data['eventName']} has been cancelled ",
                                                  "Sorry for any inconvenience");
                                              await FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc(data['userId'])
                                                  .collection('notifications')
                                                  .add({
                                                'userId': data['userId'],
                                                'eventName': data['eventName'],
                                                'message':
                                                    "${data['eventName']} has been CANCELLED. Sorry for any inconvenience",
                                                'admin name': username,
                                                'timeslot':
                                                    data['selectedTimeSlot'],
                                                'eventdate': data['eventDate'],
                                                'timestamp': FieldValue
                                                    .serverTimestamp(),
                                              });
                                            }
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 5.0, horizontal: 10),
                                            decoration: BoxDecoration(
                                                color: Colors.red,
                                                borderRadius:
                                                    BorderRadius.circular(10)),
                                            child: const Center(
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Padding(
                                                    padding: EdgeInsets.only(
                                                        right: 5.0),
                                                    child: Image(
                                                        height: 20,
                                                        image: AssetImage(
                                                            'assets/images/ticket.png')),
                                                  ),
                                                  Text(
                                                    'Cancel Booking',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    : Padding(
                                        padding: const EdgeInsets.only(
                                            left: 5.0, top: 15),
                                        child: GestureDetector(
                                          onTap: () async {
                                            useridTosendNotification =
                                                (await getDeviceId(
                                                    data['userId']))!;
                                            await FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(userdocid)
                                                .collection(
                                                    'bookedEventsByUsers')
                                                .doc(document.id)
                                                .update(
                                                    {'ConfirmStatus': true});

                                            if (useridTosendNotification
                                                .isNotEmpty) {
                                              SignIn.sendNotification(
                                                  useridTosendNotification,
                                                  "${data['eventName']} has been confirmed. ",
                                                  "Thank you for your patience");
                                              await FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc(data['userId'])
                                                  .collection('notifications')
                                                  .add({
                                                'userId': data['userId'],
                                                'eventName': data['eventName'],
                                                'message':
                                                    "${data['eventName']} has been CONFIRMED. Thank you for your patience",
                                                'admin name': username,
                                                'timeslot':
                                                    data['selectedTimeSlot'],
                                                'eventdate': data['eventDate'],
                                                'timestamp': FieldValue
                                                    .serverTimestamp(),
                                              });
                                            }
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 5.0, horizontal: 10),
                                            decoration: BoxDecoration(
                                                color: Colors.green,
                                                borderRadius:
                                                    BorderRadius.circular(10)),
                                            child: const Center(
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Padding(
                                                    padding: EdgeInsets.only(
                                                        right: 5.0),
                                                    child: Image(
                                                        height: 20,
                                                        image: AssetImage(
                                                            'assets/images/ticket.png')),
                                                  ),
                                                  Text(
                                                    'Confirm Booking',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                : Center(
                                    child: Padding(
                                    padding: const EdgeInsets.only(top: 15.0),
                                    child: Text(
                                      'Event Expired',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ))
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> getDeviceId(String userId) async {
    DocumentSnapshot snapshot =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (snapshot.exists) {
      return snapshot['deviceId'];
    } else {
      return null;
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}

Future<void> contactOnWhatsapp(String phoneNumber) async {
  var whatsappUrl = Uri.parse("whatsapp://send?phone=${'+92' + phoneNumber}"
      "&text=${Uri.encodeComponent("Hello")}");
  try {
    launchUrl(whatsappUrl);
  } catch (e) {
    debugPrint(e.toString());
  }
}

Future<void> makePhoneCall(String phoneNumber) async {
  final Uri launchUri = Uri(
    scheme: 'tel',
    path: phoneNumber,
  );
  await launchUrl(launchUri);
}

Future<void> sendNotification(String token, String title, String body) async {
  const String serverToken = 'YOUR_SERVER_KEY_HERE';
  final response = await http.post(
    Uri.parse('https://fcm.googleapis.com/fcm/send'),
    headers: <String, String>{
      'Content-Type': 'application/json',
      'Authorization':
          'key=AAAA-UXIxow:APA91bHESfrLElnP7fG5ehh-I3EskGELjGrvkcMPSdCch4kxa0iApvqMGN8eB0AmdexhYuJTavCWtxY4H76o8MbL53TEvLGkLNHaU3E6wlYtfSHX2ldiX9NRfkUFL4Lyh7DoO3mCAvcC',
    },
    body: jsonEncode(
      <String, dynamic>{
        'notification': <String, dynamic>{'title': title, 'body': body},
        'priority': 'high',
        'data': <String, dynamic>{'click_action': 'FLUTTER_NOTIFICATION_CLICK'},
        'to': token,
      },
    ),
  );

  if (response.statusCode == 200) {
    print('Notification sent successfully');
  } else {
    print('Failed to send notification');
  }
}

void listenForNewBookings(String adminId) {
  FirebaseFirestore.instance
      .collection('users')
      .doc(adminId)
      .collection('bookedEventsByUsers')
      .snapshots()
      .listen((snapshot) async {
    for (var change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.added) {
        var data = change.doc.data() as Map<String, dynamic>;
        String eventName = data['eventName'];
        String userId = data['userId'];
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        String deviceToken = userSnapshot['deviceId'];
        sendNotification(deviceToken, 'New Event Booked', 'Event: $eventName');
      }
    }
  });
}
