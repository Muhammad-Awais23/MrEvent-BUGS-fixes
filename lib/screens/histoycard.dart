import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HistoryCard extends StatelessWidget {
  final DocumentSnapshot booking;

  const HistoryCard({Key? key, required this.booking}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBookingDetail(
                'Booked Time Slot', booking['selectedTimeSlot']),
            _buildBookingDetail('Event Address', booking['eventAddress']),
            _buildBookingDetail('Event Capacity', booking['eventCapacity']),
            _buildBookingDetail('Event Date', booking['eventDate']),
            _buildBookingDetail('Event Details', booking['eventDetails']),
            _buildBookingDetail('Event Name', booking['eventName']),
            _buildBookingDetail('Event Price', booking['eventPrice']),
            _buildBookingDetail('Selected Facilities',
                booking['selectedFacilities'].join(', ')),
            _buildBookingDetail(
                'Selected Food Items', booking['selectedFoodItems'].join(', ')),
            _buildBookingDetail(
                'Booked On:', _formatTimestamp(booking['bookingDate'])),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingDetail(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: const TextStyle(
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat.yMMMMd()
        .add_jms()
        .format(dateTime); // Format timestamp as human-readable date and time
  }
}
