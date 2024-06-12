import 'package:event_manager/components/LoadingWidget.dart';
import 'package:event_manager/components/components.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'updatescreen.dart';

class EditDeleteScreen extends StatefulWidget {
  final String userEmail;

  EditDeleteScreen({required this.userEmail});

  @override
  State<EditDeleteScreen> createState() => _EditDeleteScreenState();
}

class _EditDeleteScreenState extends State<EditDeleteScreen> {
  Future<void> editEvent(
      BuildContext context, String userId, String eventId, String eventName) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateScreen(
          userId: userId,
          eventId: eventId,
          eventName: eventName,
        ),
      ),
    );
  }

  bool isDeleting = false;
  Future<void> deleteEvent(BuildContext context, String userId, String eventId,
      String eventName, List<String> imageUrls) async {
    bool confirmDelete = await _showConfirmationDialog(context);
    if (!confirmDelete) return;

    try {
      setState(() {
        isDeleting = true;
      });
      ScaffoldMessengerState scaffoldMessenger = ScaffoldMessenger.of(context);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('events')
          .doc(eventId)
          .delete();

      for (int i = 0; i < imageUrls.length; i++) {
        String imagePath = 'events/$userId/$eventName/$i.jpg';
        Reference imageRef = FirebaseStorage.instance.ref().child(imagePath);
        await imageRef.delete();
      }
      setState(() {
        isDeleting = false;
      });
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Event deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        isDeleting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete event: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool> _showConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: Colors.black,
              title: const Text('Confirm Deletion',
                  style: TextStyle(color: Colors.red)),
              content: const Text('Are you sure you want to delete this event?',
                  style: TextStyle(color: Colors.white)),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child:
                      const Text('Cancel', style: TextStyle(color: Colors.red)),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child:
                      const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          foregroundColor: Colors.white,
          backgroundColor: const Color.fromARGB(255, 22, 22, 22),
          title: const Text('Edit or Delete Events'),
        ),
        body: Stack(children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: CustomTextField2(
                  controller: searchController,
                  hinttext: 'Search event by name',
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
              Expanded(
                child: FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .where('email', isEqualTo: widget.userEmail)
                      .where('isAdmin', isEqualTo: true)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: loadingWidget(),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }
                    if (snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                            'Access denied. User is not an admin or not found.'),
                      );
                    }

                    // User is an admin, get their events
                    String userId = snapshot.data!.docs.first.id;
                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .collection('events')
                          .snapshots(),
                      builder: (context, eventsSnapshot) {
                        if (eventsSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: loadingWidget2(),
                          );
                        }
                        if (eventsSnapshot.hasError) {
                          return Center(
                            child: Text('Error: ${eventsSnapshot.error}'),
                          );
                        }
                        if (eventsSnapshot.data!.docs.isEmpty) {
                          return const Center(
                            child: Text('No events found.'),
                          );
                        }

                        // Filter events based on search query
                        var filteredEvents =
                            eventsSnapshot.data!.docs.where((eventDoc) {
                          String eventName =
                              eventDoc['eventName'].toLowerCase();
                          return eventName.contains(searchQuery);
                        }).toList();

                        // Display events in cards
                        return ListView.builder(
                          itemCount: filteredEvents.length,
                          itemBuilder: (context, index) {
                            var eventDoc = filteredEvents[index];
                            return Card(
                              color: Colors.grey[900], // Dark grey background
                              elevation: 5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              margin: const EdgeInsets.all(10),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Stack(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          color: Colors.white,
                                          onPressed: () {
                                            editEvent(
                                                context,
                                                userId,
                                                eventDoc.id,
                                                eventDoc['eventName']);
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          color: Colors.white,
                                          onPressed: () {
                                            // Ensure eventDoc['imageUrls'] is parsed into a list of strings
                                            List<String> imageUrls =
                                                (eventDoc['imageUrls']
                                                        as List<dynamic>)
                                                    .cast<String>();
                                            deleteEvent(
                                              context,
                                              userId,
                                              eventDoc
                                                  .id, // Pass eventId as the third parameter
                                              eventDoc['eventName'],
                                              imageUrls,
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          eventDoc['eventName'],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        // Row(
                                        //   children: [
                                        //     const Icon(Icons.calendar_today,
                                        //         color: Colors.white),
                                        //     const SizedBox(width: 8),
                                        //     Text(
                                        //       '${eventDoc['eventDate']}',
                                        //       style: TextStyle(
                                        //           color: Colors.white),
                                        //     ),
                                        //   ],
                                        // ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Details',
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${eventDoc['eventDetails']}',
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(Icons.people,
                                                color: Colors.white),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Capacity: ${eventDoc['eventCapacity']}',
                                              style: const TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on,
                                                color: Colors.white),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${eventDoc['eventAddress']}',
                                              style: const TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(Icons.attach_money,
                                                color: Colors.white),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${eventDoc['eventPrice']} -/Rs only',
                                              style: const TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        // Display images
                                        if (eventDoc['imageUrls'] != null &&
                                            eventDoc['imageUrls'].length > 0)
                                          SizedBox(
                                            height: 200,
                                            child: ListView.builder(
                                              scrollDirection: Axis.horizontal,
                                              itemCount:
                                                  eventDoc['imageUrls'].length,
                                              itemBuilder: (context, imgIndex) {
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          right: 8.0),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    child: Image.network(
                                                      eventDoc['imageUrls']
                                                          [imgIndex],
                                                      height: 200,
                                                      width: 200,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Facilities',
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white),
                                        ),
                                        // Display selected facilities
                                        if (eventDoc['selectedFacilities'] !=
                                                null &&
                                            eventDoc['selectedFacilities']
                                                    .length >
                                                0)
                                          Wrap(
                                            spacing: 10,
                                            children:
                                                eventDoc['selectedFacilities']
                                                    .map<Widget>((facility) {
                                              return Chip(
                                                label: Text(
                                                  facility,
                                                  style: const TextStyle(
                                                      color: Colors.white),
                                                ),
                                                backgroundColor:
                                                    Colors.grey[700],
                                              );
                                            }).toList(),
                                          ),

                                        const SizedBox(height: 8),
                                        const Text(
                                          'Time Slots:',
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white),
                                        ),
                                        // Display selected time slots
                                        if (eventDoc['selectedTimeSlots'] !=
                                                null &&
                                            eventDoc['selectedTimeSlots']
                                                    .length >
                                                0)
                                          Wrap(
                                            spacing: 10,
                                            children:
                                                eventDoc['selectedTimeSlots']
                                                    .map<Widget>((timeSlot) {
                                              return Chip(
                                                label: Text(
                                                  timeSlot,
                                                  style: const TextStyle(
                                                      color: Colors.white),
                                                ),
                                                backgroundColor:
                                                    Colors.grey[700],
                                              );
                                            }).toList(),
                                          ),

                                        const SizedBox(height: 8),
                                        const Text(
                                          'Menu:',
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white),
                                        ),
                                        // Display selected food items
                                        if (eventDoc['selectedFoodItems'] !=
                                                null &&
                                            eventDoc['selectedFoodItems']
                                                    .length >
                                                0)
                                          Wrap(
                                            spacing: 10,
                                            children:
                                                eventDoc['selectedFoodItems']
                                                    .map<Widget>((foodItem) {
                                              return Chip(
                                                label: Text(
                                                  foodItem,
                                                  style: const TextStyle(
                                                      color: Colors.white),
                                                ),
                                                backgroundColor:
                                                    Colors.grey[700],
                                              );
                                            }).toList(),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          if (isDeleting) const Center(child: loadingWidget())
        ]),
      ),
    );
  }
}
