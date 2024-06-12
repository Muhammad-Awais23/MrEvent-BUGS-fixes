import 'package:event_manager/components/LoadingWidget.dart';
import 'package:event_manager/components/components.dart';
import 'package:event_manager/screens/eventDetailScreen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/constants.dart';

class ViewEvents extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 49, 49, 49),
        foregroundColor: Colors.white,
        title: const Text('Events'),
      ),
      body: EventList(),
    );
  }
}

class EventList extends StatefulWidget {
  @override
  State<EventList> createState() => _EventListState();
}

class _EventListState extends State<EventList> {
  TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String? bankDetails;
  String? accountNumber;
  String? contactNumber;
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
          child: CustomTextField2(
            controller: _searchController,
            hinttext: 'Search by name , facilities , menu',
            onChanged: (query) {
              setState(() {}); // Trigger rebuild on text change
            },
          ),
        ),
        Expanded(
          child: FutureBuilder(
            future: FirebaseFirestore.instance
                .collection('users')
                .where('isAdmin', isEqualTo: true)
                .get(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: loadingWidget2(),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text('No admin users available'),
                );
              }

              List<QueryDocumentSnapshot> adminUsers = snapshot.data!.docs;
              return ListView.builder(
                itemCount: adminUsers.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot user = adminUsers[index];
                  String bankDetails = user['bankdetails'] ?? '';
                  String accountNumber = user['accountnumber'] ?? '';
                  String contactNumber = user['contact'] ?? '';

                  print(bankDetails);
                  print(accountNumber);
                  print(contactNumber);
                  return FutureBuilder(
                    future: user.reference.collection('events').get(),
                    builder:
                        (context, AsyncSnapshot<QuerySnapshot> eventSnapshot) {
                      if (eventSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Center(
                          child: loadingWidget2(),
                        );
                      }
                      if (eventSnapshot.hasError) {
                        return Center(
                          child: Text('Error: ${eventSnapshot.error}'),
                        );
                      }
                      if (!eventSnapshot.hasData ||
                          eventSnapshot.data!.docs.isEmpty) {
                        return const SizedBox(); // No events for this admin user
                      }

                      List<DocumentSnapshot> events = eventSnapshot.data!.docs;
                      // Filter events based on search query
                      events = events.where((event) {
                        String eventName = event['eventName'].toLowerCase();
                        List<String> foodItems =
                            List<String>.from(event['selectedFoodItems'] ?? []);
                        List<String> facilities = List<String>.from(
                            event['selectedFacilities'] ?? []);
                        String query = _searchController.text.toLowerCase();
                        return eventName.contains(query) ||
                            foodItems.any((foodItem) =>
                                foodItem.toLowerCase().contains(query)) ||
                            facilities.any((facility) =>
                                facility.toLowerCase().contains(query));
                      }).toList();

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: events.length,
                        itemBuilder: (context, index) {
                          DocumentSnapshot event = events[index];
                          print('Event ID: ${event.id}');

                          return GestureDetector(
                            onTap: () async {
                              String adminId =
                                  await getAdminId(event.id.toString());
                              print('Admin id :$adminId');
                              print('event id :${event.id}');
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EventDetailsPage(
                                      eventId: event.id, adminId: adminId),
                                ),
                              );
                            },
                            child: EventCard(
                              event: event,
                              onEventBooked: (bookedEvent) {
                                // Remove the booked event from the list
                                // setState(() {
                                //   events.remove(bookedEvent);
                                // });
                              },
                              bankDetails: bankDetails,
                              accountNumber: accountNumber,
                              contactNumber: contactNumber,
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class EventCard extends StatefulWidget {
  final DocumentSnapshot event;
  final Function(DocumentSnapshot) onEventBooked;
  String? bankDetails;
  String? accountNumber;
  String? contactNumber;
  EventCard(
      {required this.event,
      required this.onEventBooked,
      required this.bankDetails,
      required this.accountNumber,
      required this.contactNumber});

  @override
  _EventCardState createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  List<String> selectedFacilities = [];
  String selectedTimeSlot = '';
  List<String> selectedFoodItems = [];
  List<String> bookedTimeSlots = [];
  @override
  void initState() {
    super.initState();
    _loadUserData();
    // Initialize bookedTimeSlots with existing booked time slots from Firestore
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<List<String>> getAdminUserIds() async {
    List<String> adminUserIds = [];
    // Query Firestore to find users with isAdmin=true
    QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore
        .instance
        .collection('users')
        .where('isAdmin', isEqualTo: true)
        .get();

    // Extract user IDs
    querySnapshot.docs.forEach((doc) {
      adminUserIds.add(doc.id);
    });

    return adminUserIds;
  }

  Future<List<String>> getEventsOwnedByAdmins() async {
    List<String> eventIds = [];
    List<String> adminUserIds = await getAdminUserIds();

    // Query Firestore to find events owned by admin users
    for (String userId in adminUserIds) {
      QuerySnapshot<Map<String, dynamic>> eventsQuerySnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('events')
              .get();

      // Extract event IDs
      eventsQuerySnapshot.docs.forEach((doc) {
        eventIds.add(doc.id);
      });
    }

    return eventIds;
  }

  Future<void> bookComplex() async {
    if (selectedTimeSlot.isNotEmpty) {
      // Check if the selected time slot is already booked
      if (bookedTimeSlots.contains(selectedTimeSlot)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This time slot is already booked!'),
          ),
        );
      } else {
        try {
          // Check if the user has already booked this event
          String userId = getCurrentUserId();
          QuerySnapshot<Map<String, dynamic>> bookingSnapshot =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('bookings')
                  .where('eventId', isEqualTo: widget.event.id)
                  .get();

          if (bookingSnapshot.docs.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('You have already booked this event!'),
              ),
            );
            return;
          }

          // Rest of your booking logic here...
          // Find admin user IDs
          QuerySnapshot<Map<String, dynamic>> adminQuerySnapshot =
              await FirebaseFirestore.instance
                  .collection('users')
                  .where('isAdmin', isEqualTo: true)
                  .get();

          // Iterate over admin users to find the event
          for (QueryDocumentSnapshot<Map<String, dynamic>> adminSnapshot
              in adminQuerySnapshot.docs) {
            String adminUserId = adminSnapshot.id;

            // Check if the admin user has the event
            DocumentSnapshot<Map<String, dynamic>> eventSnapshot =
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(adminUserId)
                    .collection('events')
                    .doc(widget.event.id)
                    .get();

            if (eventSnapshot.exists) {
              // Update Firestore document to indicate the time slot is booked
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(adminUserId)
                  .collection('events')
                  .doc(widget.event.id)
                  .update({
                'bookedTimeSlot': FieldValue.arrayUnion([selectedTimeSlot]),
              });

              // Delete the selected time slot from Firestore
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(adminUserId)
                  .collection('events')
                  .doc(widget.event.id)
                  .update({
                'selectedTimeSlots': FieldValue.arrayRemove([selectedTimeSlot]),
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Time slot booked successfully!'),
                ),
              );
              await bookComplex2();
              widget.onEventBooked(widget.event);
              return; // Exit the function after booking the time slot
            }
          }

          // If the event was not found
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Event not found!'),
            ),
          );
        } catch (e) {
          print('Error booking time slot: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to book time slot. Please try again.'),
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a time slot!'),
        ),
      );
    }
  }

  Future<void> bookComplex2() async {
    if (selectedTimeSlot.isNotEmpty) {
      try {
        // Get the current user's ID
        String userId = getCurrentUserId();

        // Check if the user ID is not null
        if (userId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User ID not found!'),
            ),
          );
          return;
        }

        // Create a reference to the current user's document
        DocumentReference userRef =
            FirebaseFirestore.instance.collection('users').doc(userId);

        // Add the booking information to the user's document
        await userRef.collection('bookings').add({
          'userId': userId,
          // Implement this method to get the user name
          'eventId': widget.event.id,
          'eventName': widget.event['eventName'],
          'eventDate': widget.event['eventDate'].toString(),
          'eventAddress': widget.event['eventAddress'],
          'eventPrice': widget.event['eventPrice'].toString(),
          'eventCapacity': widget.event['eventCapacity'].toString(),
          'eventDetails': widget.event['eventDetails'],
          'selectedFacilities': widget.event['selectedFacilities'],
          'selectedFoodItems': widget.event['selectedFoodItems'],
          'selectedTimeSlots': widget.event['selectedTimeSlots'],
          'bookedTimeSlot': selectedTimeSlot,
          'timestamp':
              FieldValue.serverTimestamp(), // Optionally, store a timestamp
        });
        // Update the booked time slot in the event document
        DocumentReference eventRef = FirebaseFirestore.instance
            .collection('events')
            .doc(widget.event.id);
        await eventRef.update({
          'bookedTimeSlots': FieldValue.arrayUnion([selectedTimeSlot]),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Time slot booked successfully!'),
          ),
        );
      } catch (e) {
        print('Error booking time slot: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to book time slot. Please try again.'),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a time slot!'),
        ),
      );
    }
  }

  late String userid = "";
  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userid = prefs.getString('userid') ?? "";
    });
  }

// Method to get the current user's ID (replace with your implementation)
  String getCurrentUserId() {
    // Implement your logic to get the current user's ID
    return userid; // Example: Return the user ID here
  }

  @override
  Widget build(BuildContext context) {
    // Extract data from the event DocumentSnapshot
    String eventName = widget.event['eventName'];

    String eventAddress = widget.event['eventAddress'];

    String imageUrls = (widget.event['imageUrls'][0] ?? []);
    String eventId = widget.event.id;

    print('Event ID$eventId');

    // Assume 'event' collection is where the event is stored
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 5,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.red.shade900, Colors.red.shade400],
              ),
            ),
            height: 250,
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    imageUrls,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (BuildContext context, Widget child,
                        ImageChunkEvent? loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      } else {
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      }
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 8.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eventName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              maxLines: 1,
                              eventAddress,
                              style: const TextStyle(
                                  overflow: TextOverflow.ellipsis,
                                  fontSize: 16,
                                  color: Colors.white),
                            ),
                          ),
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
    );
    // return Card(
    //   margin: const EdgeInsets.all(10),
    //   elevation: 4,
    //   child: Column(
    //     crossAxisAlignment: CrossAxisAlignment.start,
    //     children: <Widget>[
    //       ListTile(
    //         title: Text(
    //           eventName,
    //           style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
    //         ),
    //       ),
    //       ListTile(
    //         title: Column(
    //           crossAxisAlignment: CrossAxisAlignment.start,
    //           children: [
    //             GestureDetector(
    //               onTap: () {
    //                 // Implement your logic to show address on map
    //               },
    //               child: GestureDetector(
    //                 onTap: () async {
    //                   try {
    //                     List<Location> locations =
    //                         await locationFromAddress(eventAddress);
    //                     if (locations.isNotEmpty) {
    //                       Navigator.push(
    //                         context,
    //                         MaterialPageRoute(
    //                           builder: (context) => MapPage(
    //                             latitude: locations.first.latitude,
    //                             longitude: locations.first.longitude,
    //                           ),
    //                         ),
    //                       );
    //                     }
    //                   } on PlatformException catch (e) {
    //                     // Handle the exception
    //                     ScaffoldMessenger.of(context).showSnackBar(
    //                       SnackBar(content: Text('Error: ${e.message}')),
    //                     );
    //                   } catch (e) {
    //                     // Handle other types of exceptions
    //                     ScaffoldMessenger.of(context).showSnackBar(
    //                       SnackBar(content: Text('An error occurred')),
    //                     );
    //                   }
    //                 },
    //                 child: const Row(
    //                   children: <Widget>[
    //                     Icon(Icons.map, color: Colors.blue),
    //                     SizedBox(width: 8),
    //                     Text(
    //                       'Show on Map',
    //                       style: TextStyle(
    //                         color: Colors.blue,
    //                         fontSize: 16,
    //                       ),
    //                     ),
    //                   ],
    //                 ),
    //               ),
    //             ),
    //             const SizedBox(height: 4),
    //             Text(
    //               eventAddress,
    //               style: const TextStyle(fontSize: 16),
    //             ),
    //           ],
    //         ),
    //       ),
    //       if (imageUrls.isNotEmpty)
    //         SizedBox(
    //           height: 150,
    //           child: ListView.builder(
    //             scrollDirection: Axis.horizontal,
    //             itemCount: imageUrls.length,
    //             itemBuilder: (context, index) {
    //               return Padding(
    //                 padding: const EdgeInsets.all(8.0),
    //                 child: ClipRRect(
    //                   borderRadius: BorderRadius.circular(10),
    //                   child: Image.network(
    //                     imageUrls[index],
    //                     width: 200,
    //                     fit: BoxFit.cover,
    //                   ),
    //                 ),
    //               );
    //             },
    //           ),
    //         ),
    //     ],
    //   ),
    // );
  }
}

class MapPage extends StatelessWidget {
  final double latitude;
  final double longitude;

  MapPage({required this.latitude, required this.longitude});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Map'),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(latitude, longitude),
          zoom: 14.0,
        ),
        markers: {
          Marker(
            markerId: MarkerId('eventLocation'),
            position: LatLng(latitude, longitude),
          ),
        },
      ),
    );
  }
}
