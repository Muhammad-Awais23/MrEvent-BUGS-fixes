import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:custom_rating_bar/custom_rating_bar.dart';
import 'package:event_manager/components/LoadingWidget.dart';
import 'package:event_manager/components/components.dart';
import 'package:event_manager/components/constants.dart';
import 'package:event_manager/screens/historyscreen.dart';
import 'package:event_manager/shared/functions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class EventDetailsPage extends StatefulWidget {
  final String eventId;
  final String adminId;

  EventDetailsPage({required this.eventId, required this.adminId});

  @override
  _EventDetailsPageState createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  late String userdocid;
  String? _selectedTimeSlot;
  String? _selectedPaymentMetod;
  String? _selectedAdanvcedPay;
  String? _selectedDate;

  List<String> _selectedFacilities = [];
  List<String> _selectedFoodItems = [];
  Future<void> _showBookingNotification(String eventName) async {
    var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
      'default_notification_channel_id',
      'channel_name',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    var platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      'Event Booked',
      '$eventName was successfully Booked!',
      platformChannelSpecifics,
      payload: 'item x',
    );
  }

  Future<void> makePayment(int amount) async {
    try {
      setState(() {
        _isBooking = true;
      });
      print('Creating payment intent...');
      // STEP 1: Create Payment Intent
      var paymentIntent = await createPaymentIntent(amount.toString(), 'PKR');
      print('Payment intent created: $paymentIntent');

      // STEP 2: Initialize Payment Sheet
      print('Initializing payment sheet...');
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret:
              paymentIntent['client_secret'], // Gotten from payment intent
          style: ThemeMode.light,
          merchantDisplayName: 'Ikay',
        ),
      );
      print('Payment sheet initialized');

      // STEP 3: Display Payment sheet
      print('Displaying payment sheet...');
      await displayPaymentSheet();
      print('Payment sheet displayed');
      setState(() {
        _isBooking = false;
      });
    } catch (err) {
      setState(() {
        _isBooking = false;
      });
      print('Error in makePayment: $err');
      throw Exception(err);
    }
  }

  late String devicdeid = '';
  late String usernamefornot = '';
  Map<String, dynamic>? paymentIntent;
  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userdocid = prefs.getString('userdocid') ?? "";
      devicdeid = prefs.getString('devicdeid') ?? "";
      usernamefornot = prefs.getString('username') ?? "";
    });
  }

  createPaymentIntent(String amount, String currency) async {
    try {
      //Request body
      Map<String, dynamic> body = {
        'amount': amount,
        'currency': currency,
      };

      //Make post request to Stripe
      var response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer ${dotenv.env['STRIPE_SECRET']}',
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: body,
      );
      return json.decode(response.body);
    } catch (err) {
      throw Exception(err.toString());
    }
  }

  bool _isBooking = false;
  bool isPaid = false;
  displayPaymentSheet() async {
    try {
      setState(() {
        _isBooking = true;
      });
      await Stripe.instance.presentPaymentSheet().then((value) {
        setState(() {
          isPaid = true;
        });
        showDialog(
            context: context,
            builder: (_) => const AlertDialog(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 100.0,
                      ),
                      SizedBox(height: 10.0),
                      Text("Payment Successful!"),
                    ],
                  ),
                ));
        setState(() {
          _isBooking = false;
        });
        paymentIntent = null;
      }).onError((error, stackTrace) {
        setState(() {
          _isBooking = true;
          isPaid = false;
        });
        throw Exception(error);
      });
    } on StripeException catch (e) {
      setState(() {
        isPaid = false;
        _isBooking = true;
      });
      print('Error is:---> $e');
      const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.cancel,
                  color: Colors.red,
                ),
                Text("Payment Failed"),
              ],
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        isPaid = false;
        _isBooking = true;
      });
      print('$e');
    }
  }

  bool confirmStatus = false;
  String deviceIdofAdmin = "";
  Future<void> _bookEvent() async {
    if (_selectedTimeSlot != null && !_isBooking) {
      setState(() {
        _isBooking = true;
      });

      // Check if user has already booked this event
      // var bookingSnapshot = await FirebaseFirestore.instance
      //     .collection('users')
      //     .doc(userdocid)
      //     .collection('bookings')
      //     .where('eventId', isEqualTo: widget.eventId)
      //     .get();

      // if (bookingSnapshot.docs.isNotEmpty) {
      //   setState(() {
      //     _isBooking = false;
      //   });
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(
      //       content: Text('You have already booked this event.'),
      //       duration: Duration(seconds: 2),
      //     ),
      //   );
      //   return;
      // }

      DocumentSnapshot adminSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.adminId)
          .get();
      if (!adminSnapshot.exists) {
        setState(() {
          _isBooking = false;
        });
        return;
      }

      var adminData = adminSnapshot.data() as Map<String, dynamic>;
      String accountNumber = adminData['accountnumber'] ?? '';
      String bankDetails = adminData['bankdetails'] ?? '';
      String contactNumber = adminData['contact'];

      DocumentSnapshot eventSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.adminId)
          .collection('events')
          .doc(widget.eventId)
          .get();

      if (!eventSnapshot.exists) {
        setState(() {
          _isBooking = false;
        });
        return;
      }

      var eventData = eventSnapshot.data() as Map<String, dynamic>;
      String eventName = eventData['eventName'] ?? '';
      String eventAddress = eventData['eventAddress'] ?? '';
      String eventCapacity = eventData['eventCapacity'] ?? '';
      String eventDate = eventData['eventDate'] ?? '';
      String eventDetails = eventData['eventDetails'] ?? '';
      String eventPrice = eventData['eventPrice'] ?? '';
      List<String> imageUrls = List<String>.from(eventData['imageUrls'] ?? []);
      List<Map<String, dynamic>> datesWithSlots =
          List<Map<String, dynamic>>.from(eventData['datesWithSlots'] ?? []);

      // Update datesWithSlots to remove the selected time slot for the selected date

      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userdocid)
          .get();
      if (!userSnapshot.exists) {
        setState(() {
          _isBooking = false;
        });
        return;
      }

      var userData = userSnapshot.data() as Map<String, dynamic>;
      String userName = userData['username'] ?? '';
      String userEmail = userData['email'] ?? '';
      String userContact = userData['contact'] ?? '';

      setState(() {
        _isBooking = false;
      });

      // Show capacity selection dialog
      int selectedCapacity = 1; // Default capacity

      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return AlertDialog(
                backgroundColor: Color.fromARGB(255, 38, 38, 38),
                title: const Text(
                  'Select Capacity',
                  style: TextStyle(color: Colors.white),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Event Capacity: $eventCapacity',
                        style: TextStyle(color: Colors.white)),
                    SizedBox(height: 10),
                    Text('Enter Desired Persons:',
                        style: TextStyle(color: Colors.white)),
                    TextField(
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: Colors.white),
                      onChanged: (value) {
                        setState(() {
                          selectedCapacity = int.tryParse(value) ?? 1;
                          if (selectedCapacity > int.parse(eventCapacity)) {
                            selectedCapacity = int.parse(eventCapacity);
                          }
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter capacity',
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      if (selectedCapacity > int.parse(eventCapacity)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Selected capacity cannot be more than event capacity.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      } else {
                        Navigator.of(context)
                            .pop(selectedCapacity); // OK, confirm capacity
                      }
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        },
      ).then((selectedCapacity) async {
        if (selectedCapacity == null) {
          return; // Cancelled
        }

        // Calculate total price and advance payment based on selected capacity
        num totalCapacityPrice = int.parse(eventPrice) * selectedCapacity;
        double advancePaymentPercentage = 0.3; // Default to 30%
        if (_selectedAdanvcedPay == '20%') {
          advancePaymentPercentage = 0.2;
        } else if (_selectedAdanvcedPay == '50%') {
          advancePaymentPercentage = 0.5;
        } else if (_selectedAdanvcedPay == '10%') {
          advancePaymentPercentage = 0.1;
        } else if (_selectedAdanvcedPay == '40%') {
          advancePaymentPercentage = 0.4;
        } else if (_selectedAdanvcedPay == '60%') {
          advancePaymentPercentage = 0.6;
        } else if (_selectedAdanvcedPay == '70%') {
          advancePaymentPercentage = 0.7;
        } else if (_selectedAdanvcedPay == '80%') {
          advancePaymentPercentage = 0.8;
        } else if (_selectedAdanvcedPay == '90%') {
          advancePaymentPercentage = 0.9;
        }
        double advancePayment = totalCapacityPrice * advancePaymentPercentage;
        int advanceIntPayment = advancePayment.toInt();
        advancePayment =
            advancePayment.roundToDouble(); // Round to nearest integer

        // Show confirmation dialog
        bool confirmBooking = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.black,
              title: const Text(
                'Confirm Booking?',
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Event: $eventName',
                      style: TextStyle(color: Colors.white)),
                  Text('Total Price: $totalCapacityPrice',
                      style: TextStyle(color: Colors.white)),
                  Text(
                      'Advance Payment ($_selectedAdanvcedPay): $advanceIntPayment',
                      style: TextStyle(color: Colors.white)),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false); // No, cancel booking
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true); // Yes, confirm booking
                  },
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );

        if (confirmBooking != null && confirmBooking) {
          await makePayment(advanceIntPayment);
          if (isPaid) {
            for (var dateSlot in datesWithSlots) {
              if (dateSlot['date'] == _selectedDate) {
                List<String> timeSlots =
                    List<String>.from(dateSlot['timeSlots'] ?? []);
                timeSlots.remove(_selectedTimeSlot);
                dateSlot['timeSlots'] = timeSlots;
                break;
              }
            }

            // Update event document with updated datesWithSlots
            await FirebaseFirestore.instance
                .collection('users')
                .doc(widget.adminId)
                .collection('events')
                .doc(widget.eventId)
                .update({
              'datesWithSlots': datesWithSlots,
            });

            // Proceed with booking
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userdocid)
                .collection('bookings')
                .add({
              'eventId': widget.eventId,
              'eventName': eventName,
              'eventAddress': eventAddress,
              'eventCapacity': eventCapacity,
              'eventDate': _selectedDate,
              'eventDetails': eventDetails,
              'eventPrice': eventPrice,
              'imageUrls': imageUrls,
              'selectedTimeSlot': _selectedTimeSlot,
              'selectedFacilities': _selectedFacilities,
              'selectedFoodItems': _selectedFoodItems,
              'bookingDate': Timestamp.now(),
              'accountNumber': accountNumber,
              'bankDetails': bankDetails,
              'contactNumber': contactNumber,
              'paymentMethod': _selectedPaymentMetod,
              'advancePayment': _selectedAdanvcedPay,
              'adminId': widget.adminId,
              'capacity': selectedCapacity,
            });

            await FirebaseFirestore.instance
                .collection('users')
                .doc(widget.adminId)
                .collection('bookedEvents')
                .add({
              'eventId': widget.eventId,
              'userId': userdocid,
              'userName': userName,
              'userEmail': userEmail,
              'userContact': userContact,
              'eventName': eventName,
              'eventAddress': eventAddress,
              'eventDate': _selectedDate,
              'selectedTimeSlot': _selectedTimeSlot,
              'capacity': selectedCapacity,
              'bookingDate': Timestamp.now(),
            });

            // Add booking details to admin's bookedEventsByUsers collection
            await FirebaseFirestore.instance
                .collection('users')
                .doc(widget.adminId)
                .collection('bookedEventsByUsers')
                .add({
              'eventId': widget.eventId,
              'userId': userdocid,
              'userName': userName,
              'userEmail': userEmail,
              'userContact': userContact,
              'eventName': eventName,
              'eventAddress': eventAddress,
              'eventDate': _selectedDate,
              'selectedTimeSlot': _selectedTimeSlot,
              'ConfirmStatus': confirmStatus,
              'capacity': selectedCapacity,
              'bookingDate': Timestamp.now(),
            });

            // Send notification to admin
            SignIn.sendNotification(
                deviceIdofAdmin,
                "$eventName successfully booked",
                "$advancePayment payment successful by $usernamefornot, check history now!");

            // Show success dialog
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Thank You!'),
                  content: Text('Thank you for choosing $eventName.'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('OK'),
                    ),
                  ],
                );
              },
            );

            // Show success snackbar
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Event booked successfully.'),
                duration: Duration(seconds: 2),
              ),
            );
          } else {
            // Show payment unsuccessful snackbar
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment unsuccessful'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      });
    }
  }

  late Future<DocumentSnapshot> _adminFuture;
  late Stream<DocumentSnapshot> _eventStream;
  @override
  void initState() {
    super.initState();
    var initializationSettingsAndroid =
        const AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );

    _loadUserData();

    _adminFuture = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.adminId)
        .get();

    _eventStream = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.adminId)
        .collection('events')
        .doc(widget.eventId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black, // Changed to black
        foregroundColor: Colors.white,
        title: const Text('Event Details'),
      ),
      backgroundColor: Colors.black, // Added to change background to black
      body: Stack(
        children: [
          FutureBuilder(
            future: _adminFuture,
            builder: (context, AsyncSnapshot<DocumentSnapshot> adminSnapshot) {
              if (adminSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (adminSnapshot.hasError) {
                return Center(child: Text('Error: ${adminSnapshot.error}'));
              }
              if (!adminSnapshot.hasData || !adminSnapshot.data!.exists) {
                return const Center(child: Text('Admin user not found.'));
              }

              var adminData = adminSnapshot.data!;
              String accountNumber = adminData['accountnumber'] ?? '';
              String bankDetails = adminData['bankdetails'] ?? '';
              String contactNumber = adminData['contact'] ?? '';
              deviceIdofAdmin = adminData['deviceId'] ?? '';
              return StreamBuilder(
                stream: _eventStream,
                builder:
                    (context, AsyncSnapshot<DocumentSnapshot> eventSnapshot) {
                  if (eventSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (eventSnapshot.hasError) {
                    return Center(child: Text('Error: ${eventSnapshot.error}'));
                  }
                  if (!eventSnapshot.hasData || !eventSnapshot.data!.exists) {
                    return const Center(child: Text('Event not found.'));
                  }

                  var eventData = eventSnapshot.data!;
                  String eventName = eventData['eventName'] ?? '';
                  String eventAddress = eventData['eventAddress'] ?? '';
                  String eventCapacity = eventData['eventCapacity'] ?? '';
                  String eventDetails = eventData['eventDetails'] ?? '';

                  double? rating;
                  var data = eventData.data() as Map<String, dynamic>;
                  if (data.containsKey('averageRating')) {
                    if (data['averageRating'] is double) {
                      rating = data['averageRating'] ?? 0;
                    } else if (data['averageRating'] is String) {
                      rating = double.tryParse(data['averageRating']) ?? 0;
                    }
                  }
                  num latitude = eventData['latitude'];
                  num longitude = eventData['longitude'];
                  String eventPrice = eventData['eventPrice'] ?? '';
                  List<String> imageUrls =
                      List<String>.from(eventData['imageUrls'] ?? []);
                  List<String> availableFacilities =
                      List<String>.from(eventData['selectedFacilities'] ?? []);
                  List<String> availableFoodItems =
                      List<String>.from(eventData['selectedFoodItems'] ?? []);
                  List<String> availableTimeSlots =
                      List<String>.from(eventData['selectedTimeSlots'] ?? []);
                  List<String> paymentMethod = List<String>.from(
                      eventData['selectedpaymentmethod'] ?? []);
                  List<String> advancePayment =
                      List<String>.from(eventData['advancepayment'] ?? []);

                  // Correctly parse datesWithSlots
                  Map<String, List<String>> datesWithSlots = {};
                  if (eventData['datesWithSlots'] != null) {
                    (eventData['datesWithSlots'] as List<dynamic>)
                        .forEach((element) {
                      datesWithSlots[element['date']] =
                          List<String>.from(element['timeSlots']);
                    });
                  }
                  return SingleChildScrollView(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eventName,
                        style: const TextStyle(
                            fontSize: 25,
                            color: kTextColor,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            Icons.map_rounded,
                            color: kTextColor,
                          ),
                          const SizedBox(width: 10), // Adjust spacing as needed
                          Expanded(
                            child: Text(
                              eventAddress,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2, // Adjust as needed
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      // Row(
                      //   children: [
                      //     const Icon(
                      //       Icons.calendar_today_rounded,
                      //       color: kTextColor,
                      //     ),
                      //     const SizedBox(width: 8),
                      //     Text(
                      //       eventDate,
                      //       style: const TextStyle(
                      //           fontSize: 16,
                      //           color: Colors.white,
                      //           fontWeight: FontWeight.bold),
                      //     ),
                      //   ],
                      // ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.attach_money_rounded,
                            color: kTextColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$eventPrice   per person',
                            style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          Expanded(child: Container()),
                          GestureDetector(
                              onTap: () {
                                if (latitude != null && longitude != null) {
                                  _launchMaps(latitude, longitude);
                                } else {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Error'),
                                      content: const Text(
                                          'Location coordinates not available.'),
                                      actions: <Widget>[
                                        TextButton(
                                          child: const Text('OK'),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 5.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(10)),
                                  child: const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      'show on map',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              )),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.phone_iphone_rounded,
                            color: kTextColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            contactNumber,
                            style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          Expanded(child: Container()),
                          GestureDetector(
                            onTap: () {
                              contactOnWhatsapp(contactNumber, eventName);
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
                              makePhoneCall(contactNumber);
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(left: 5.0),
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
                        ],
                      ),
                      Text(
                        'Capicity : $eventCapacity',
                        style: const TextStyle(
                            fontSize: 20,
                            color: kTextColor,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16.0),
                      _buildSectionTitle('Available Time Slots'),

                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: DropdownButton<String>(
                          value: _selectedDate,
                          hint: const Text(
                            'Select Date',
                            style: TextStyle(color: Colors.white),
                          ),
                          dropdownColor: Colors.black,
                          items: datesWithSlots.keys.map((String date) {
                            return DropdownMenuItem<String>(
                              value: date,
                              child: Text(
                                date,
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedDate = newValue;
                              _selectedTimeSlot = null;
                            });
                          },
                        ),
                      ),
                      if (_selectedDate != null)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: datesWithSlots[_selectedDate]!.isEmpty
                                ? [
                                    const Text(
                                      'No slots available for this Date',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ]
                                : datesWithSlots[_selectedDate]!
                                    .map(
                                      (timeSlot) => RadioListTile<String>(
                                        title: Text(
                                          timeSlot,
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                        value: timeSlot,
                                        groupValue: _selectedTimeSlot,
                                        onChanged: (String? value) {
                                          setState(() {
                                            _selectedTimeSlot = value;
                                          });
                                        },
                                      ),
                                    )
                                    .toList(),
                          ),
                        ),
                      const SizedBox(height: 10),

                      // Column(
                      //   crossAxisAlignment: CrossAxisAlignment.start,
                      //   children: datesWithSlots[_selectedDate]!
                      //       .map(
                      //         (timeSlot) => RadioListTile<String>(
                      //           title: Text(
                      //             timeSlot,
                      //             style: const TextStyle(color: Colors.white),
                      //           ),
                      //           value: timeSlot,
                      //           groupValue: _selectedTimeSlot,
                      //           onChanged: (String? value) {
                      //             setState(() {
                      //               _selectedTimeSlot = value;
                      //             });
                      //           },
                      //         ),
                      //       )
                      //       .toList(),
                      // ),
                      const SizedBox(height: 16.0),
                      _buildSectionTitle('Details'),
                      ExpansionTile(
                        title: const Text('Show Details',
                            style: TextStyle(color: Colors.white)),
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Images',
                                style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 200,
                                width: double.infinity,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: List.generate(
                                    imageUrls.length,
                                    (index) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16.0),
                                      child: SizedBox(
                                        height: 200,
                                        width: 180,
                                        child: Stack(
                                          alignment: Alignment.bottomCenter,
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                image: DecorationImage(
                                                  image: NetworkImage(
                                                      imageUrls[index]),
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              _buildSectionContent(eventDetails),
                              _buildSectionTitle('Rating'),
                              if (rating != null)
                                _buildSectionContent(rating.toString()),
                              RatingBar.readOnly(
                                isHalfAllowed: true,
                                size: 20,
                                filledIcon: Icons.star,
                                emptyIcon: Icons.star_border,
                                halfFilledIcon: Icons.star_half,
                                initialRating: rating != null ? rating : 0.0,
                                maxRating: 5,
                              ),
                              const SizedBox(height: 12.0),
                              _buildSectionTitle('Facilities'),
                              Wrap(
                                spacing: 8.0,
                                children: availableFacilities
                                    .map(
                                      (facility) => CheckboxListTile(
                                        title: Text(
                                          facility,
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                        value: _selectedFacilities
                                            .contains(facility),
                                        onChanged: (bool? value) {
                                          setState(() {
                                            if (value != null && value) {
                                              _selectedFacilities.add(facility);
                                            } else {
                                              _selectedFacilities
                                                  .remove(facility);
                                            }
                                          });
                                        },
                                      ),
                                    )
                                    .toList(),
                              ),
                              const SizedBox(height: 12.0),
                              _buildSectionTitle('Food Menu'),
                              Wrap(
                                spacing: 8.0,
                                children: availableFoodItems
                                    .map(
                                      (foodItem) => CheckboxListTile(
                                        title: Text(
                                          foodItem,
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                        value: _selectedFoodItems
                                            .contains(foodItem),
                                        onChanged: (bool? value) {
                                          setState(() {
                                            if (value != null && value) {
                                              _selectedFoodItems.add(foodItem);
                                            } else {
                                              _selectedFoodItems
                                                  .remove(foodItem);
                                            }
                                          });
                                        },
                                      ),
                                    )
                                    .toList(),
                              ),
                              const SizedBox(height: 12.0),
                              _buildSectionTitle('Payment Method'),
                              Column(
                                children: paymentMethod.isEmpty
                                    ? [
                                        const Text(
                                            'No payment methods available.'),
                                      ]
                                    : paymentMethod
                                        .map(
                                          (method) => RadioListTile<String>(
                                            title: Text(
                                              method,
                                              style: const TextStyle(
                                                  color: Colors.white),
                                            ),
                                            value: method,
                                            groupValue: _selectedPaymentMetod,
                                            onChanged: (String? value) {
                                              setState(() {
                                                _selectedPaymentMetod = value;
                                              });
                                            },
                                          ),
                                        )
                                        .toList(),
                              ),
                              const SizedBox(height: 12.0),
                              _buildSectionTitle('Advance Payment'),
                              Column(
                                children: advancePayment.isEmpty
                                    ? [
                                        const Text(
                                            'No advance payment options available.'),
                                      ]
                                    : advancePayment
                                        .map(
                                          (option) => RadioListTile<String>(
                                            title: Text(
                                              option,
                                              style: const TextStyle(
                                                  color: Colors.white),
                                            ),
                                            value: option,
                                            groupValue: _selectedAdanvcedPay,
                                            onChanged: (String? value) {
                                              setState(() {
                                                _selectedAdanvcedPay = value;
                                              });
                                            },
                                          ),
                                        )
                                        .toList(),
                              ),
                              const SizedBox(height: 12.0),
                              _buildSectionTitle('Account Number'),
                              _buildSectionContent(accountNumber),
                              const SizedBox(height: 12.0),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16.0),
                      if (_selectedDate != null)
                        datesWithSlots[_selectedDate]!.isEmpty
                            ? const Center(
                                child: Text(
                                'No Slots Available',
                                style: TextStyle(color: Colors.white),
                              ))
                            : Center(
                                child: CustomButton(
                                  buttonText: 'Book Event',
                                  onPressed: () {
                                    _bookEvent();
                                  },
                                ),
                              ),
                    ],
                  ));
                },
              );
            },
          ),
          if (_isBooking) const Center(child: loadingWidget())
        ],
      ),
    );
  }

  void _launchMaps(num latitude, num longitude) async {
    final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    await launchUrl(launchUri);
  }

  Future<void> contactOnWhatsapp(String phoneNumber, String eventName) async {
    var whatsappUrl = Uri.parse("whatsapp://send?phone=${'+92' + phoneNumber}"
        "&text=${Uri.encodeComponent("Hello , I would like to get details on $eventName")}");
    try {
      launchUrl(whatsappUrl);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
          fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
    );
  }

  Widget _buildSectionContent(String content) {
    return Text(
      content,
      style: const TextStyle(fontSize: 18, color: Colors.white),
    );
  }
}
