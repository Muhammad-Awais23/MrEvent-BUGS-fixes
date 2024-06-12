import 'package:custom_rating_bar/custom_rating_bar.dart';
import 'package:event_manager/components/LoadingWidget.dart';
import 'package:event_manager/components/components.dart';
import 'package:event_manager/components/constants.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    Key? key,
  }) : super(key: key);

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Future<void> makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    await launchUrl(launchUri);
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
  void initState() {
    super.initState();

    _loadUserData();
  }

  String _searchQuery = '';
  TextEditingController _searchController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Bookings'),
        backgroundColor: const Color.fromARGB(255, 43, 43, 43),
        foregroundColor: Colors.white, // Red app bar
      ),
      body: userdocid.isEmpty
          ? const Center(
              child: Text(
                'No user ID provided',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            )
          : FutureBuilder(
              future: _fetchBookings(userdocid),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: loadingWidget2());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No bookings available',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  );
                }

                List<DocumentSnapshot> bookings = snapshot.data!.docs;

                // Filter bookings by event name
                List<DocumentSnapshot> filteredBookings =
                    bookings.where((booking) {
                  String eventName =
                      booking['eventName'].toString().toLowerCase();
                  return eventName.contains(_searchQuery.toLowerCase());
                }).toList();

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CustomTextField2(
                        controller: _searchController,
                        hinttext: 'Search event by name',
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredBookings.length,
                        itemBuilder: (context, index) {
                          DocumentSnapshot booking = filteredBookings[index];
                          DateTime dateTime =
                              (booking['bookingDate'] as Timestamp).toDate();
                          String formattedDate =
                              '${dateTime.day}-${dateTime.month}-${dateTime.year}';
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Card(
                              color: Color.fromARGB(255, 36, 36, 36),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 5,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      booking['eventName'],
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Booked On:',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: const Color.fromARGB(
                                            255, 157, 157, 157),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      formattedDate,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: const Color.fromARGB(
                                            255, 157, 157, 157),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      booking['eventDetails'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            contactOnWhatsapp(
                                                booking['contactNumber'],
                                                booking['eventName']);
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
                                                children: [
                                                  Padding(
                                                    padding: EdgeInsets.only(
                                                        right: 5.0),
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
                                            makePhoneCall(
                                                booking['contactNumber']);
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                left: 5.0),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 5.0,
                                                      horizontal: 10),
                                              decoration: BoxDecoration(
                                                  color: Colors.red,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10)),
                                              child: const Center(
                                                child: Row(
                                                  children: [
                                                    Padding(
                                                      padding: EdgeInsets.only(
                                                          right: 5.0),
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
                                    SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          TextButton(
                                            onPressed: () {
                                              _navigateToBookingDetails(
                                                  booking);
                                            },
                                            child: const Text(
                                              'View Details',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              _showRatingDialog(booking);
                                            },
                                            child: const Text(
                                              'Rate This Event',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _fetchBookings(String userDocId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userDocId)
        .collection('bookings')
        .get();
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

  void _navigateToBookingDetails(DocumentSnapshot booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingDetailsScreen(booking: booking),
      ),
    );
  }

  void _showRatingDialog(DocumentSnapshot booking) {
    showDialog(
      context: context,
      builder: (context) {
        double rating = 0;
        TextEditingController commentController = TextEditingController();
        return AlertDialog(
          backgroundColor: Colors.black, // Dark background dialog
          title: const Text(
            'Rate This Event',
            style: TextStyle(color: Colors.red), // Red title
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Give a rating',
                style: TextStyle(color: Colors.white), // White text
              ),
              RatingBar(
                filledIcon: Icons.star,
                emptyIcon: Icons.star_border,
                initialRating: 3,
                maxRating: 5,
                onRatingChanged: (newRating) {
                  rating = newRating;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white), // White text
              ),
            ),
            TextButton(
              onPressed: () {
                _submitRating(booking, rating, commentController.text);
                Navigator.of(context).pop();
              },
              child: const Text(
                'Submit',
                style: TextStyle(color: Colors.white), // White text
              ),
            ),
          ],
        );
      },
    );
  }

  void _submitRating(
      DocumentSnapshot booking, double rating, String comment) async {
    DocumentReference eventRef = FirebaseFirestore.instance
        .collection('users')
        .doc(booking['adminId'])
        .collection('events')
        .doc(booking['eventId']);

    FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot eventSnapshot = await transaction.get(eventRef);

      if (!eventSnapshot.exists) {
        throw Exception("Event does not exist!");
      }

      Map<String, dynamic> eventData =
          eventSnapshot.data() as Map<String, dynamic>;

      int ratingCount = eventData['ratingCount'] ?? 0;
      double totalRating = (eventData['totalRating'] ?? 0.0) as double;

      ratingCount += 1;
      totalRating += rating;

      double averageRating = totalRating / ratingCount;

      transaction.update(eventRef, {
        'ratingCount': ratingCount,
        'totalRating': totalRating,
        'averageRating': averageRating.toStringAsFixed(1),
        'comment': comment,
      });
    });
  }
}

class BookingDetailsScreen extends StatelessWidget {
  final DocumentSnapshot booking;

  const BookingDetailsScreen({Key? key, required this.booking})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    DateTime dateTime = (booking['bookingDate'] as Timestamp).toDate();
    String formattedBookingDate =
        '${dateTime.day}-${dateTime.month}-${dateTime.year}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: const Color.fromARGB(255, 44, 44, 44),
        foregroundColor: Colors.white, // Dark background color for app bar
      ),
      backgroundColor: Colors.black, // Dark background color for scaffold body
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildDetailRow('Event Name', booking['eventName']),
            _buildDetailRow('Event Price', booking['eventPrice'].toString()),
            _buildDetailRow(
                'Event Capacity', booking['eventCapacity'].toString()),
            _buildDetailRow('Event Address', booking['eventAddress']),
            _buildDetailRow(
                'Contact Number', booking['contactNumber'].toString()),
            _buildDetailRow('Booking Date', formattedBookingDate),
            _buildDetailRow('Payment Method', booking['paymentMethod']),
            _buildDetailRow('Bank Details', booking['bankDetails']),
            _buildDetailRow(
                'Advance Payment', booking['advancePayment'].toString()),
            const SizedBox(height: 12),
            _buildDetailRow('Selected Time Slots', booking['selectedTimeSlot']),
            _buildDetailRow(
                'Selected Food Items', booking['selectedFoodItems']),
            _buildDetailRow(
                'Selected Facilities', booking['selectedFacilities']),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white, // White text color
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white, // White text color
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
