import 'package:event_manager/components/LoadingWidget.dart';
import 'package:event_manager/screens/admin.dart';
import 'package:event_manager/screens/editDeleteScreen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import 'package:progress_dialog_null_safe/progress_dialog_null_safe.dart';

class UpdateScreen extends StatefulWidget {
  final String userId;
  final String eventId;
  final String eventName;

  UpdateScreen(
      {required this.userId, required this.eventId, required this.eventName});

  @override
  _UpdateScreenState createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> {
  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _eventDateController = TextEditingController();
  final TextEditingController _eventDetailsController = TextEditingController();
  final TextEditingController _eventAddressController = TextEditingController();
  final TextEditingController _eventPriceController = TextEditingController();
  final TextEditingController _eventCapacity = TextEditingController();
  final TextEditingController _selectedFacilitiesController =
      TextEditingController();
  final TextEditingController _selectedTimeSlots = TextEditingController();
  final TextEditingController _selectedFoodItems = TextEditingController();
  @override
  void initState() {
    super.initState();
    // _eventNameController = TextEditingController();
    // _eventDateController = TextEditingController();
    // _eventDetailsController = TextEditingController();
    // _eventAddressController = TextEditingController();
    // _eventPriceController = TextEditingController();
    // _selectedFacilitiesController = TextEditingController();
    // _selectedFoodItems = TextEditingController();
    // _selectedTimeSlots = TextEditingController();
    // _eventCapacity = TextEditingController();

    // Load existing event data
    loadEventData();
    progressDialog = ProgressDialog(context);
  }

  LatLng? _selectedLocationLatLng;
  bool isLoading = false;
  ProgressDialog? progressDialog;
  @override
  void dispose() {
    _eventNameController.dispose();
    _eventDateController.dispose();
    _eventDetailsController.dispose();
    _eventAddressController.dispose();
    _eventPriceController.dispose();
    _selectedFacilitiesController.dispose();
    _selectedFoodItems.dispose();
    _selectedTimeSlots.dispose();
    _eventCapacity.dispose();
    super.dispose();
  }

  Future<void> uploadImagesAndSaveData() async {
    // Initialize the ProgressDialog
    if (selectedImages.isNotEmpty &&
        selectedImages.any((image) => image != null)) {
      try {
        setState(() {
          isLoading = true;
        });
        List<String> imageURLs = [];

        // Delete previous images from Firebase Storage
        String previousImagePath =
            'events/${widget.userId}/${widget.eventName}/';
        for (int i = 0; i < selectedImages.length; i++) {
          Reference ref = FirebaseStorage.instance
              .ref()
              .child(previousImagePath + '$i.jpg');
          await ref.delete().catchError((error) {
            print('Error deleting image $i: $error');
          });
        }

        // Upload new images to Firebase Storage and get their URLs
        for (int i = 0; i < selectedImages.length; i++) {
          if (selectedImages[i] != null) {
            String imagePath =
                'events/${widget.userId}/${widget.eventName}/$i.jpg';
            Reference ref = FirebaseStorage.instance.ref().child(imagePath);
            UploadTask uploadTask = ref.putFile(selectedImages[i]!);
            TaskSnapshot taskSnapshot = await uploadTask;
            String downloadURL = await taskSnapshot.ref.getDownloadURL();
            imageURLs.add(downloadURL);
          }
        }

        // Update the image URLs in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('events')
            .doc(widget.eventId)
            .update({'imageUrls': imageURLs});
        setState(() {
          isLoading = false;
        });
        // Optionally, you can update the UI or perform any other tasks here.
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        print('Error uploading images and saving data: $e');
      }
    }
  }

  Future<void> loadEventData() async {
    try {
      DocumentSnapshot eventSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('events')
          .doc(widget.eventId)
          .get();

      Map<String, dynamic> eventData =
          eventSnapshot.data() as Map<String, dynamic>;
      _eventNameController.text = eventData['eventName'] ?? '';
      _eventDateController.text = eventData['eventDate'] ?? '';
      _eventDetailsController.text = eventData['eventDetails'] ?? '';
      _eventAddressController.text = eventData['eventAddress'] ?? '';
      _eventPriceController.text = eventData['eventPrice'] ?? '';
      _eventCapacity.text = eventData['eventCapacity'] ?? '';
      _selectedFacilitiesController.text =
          eventData['selectedFacilities'] != null
              ? (eventData['selectedFacilities'] as List<dynamic>).join('\n')
              : '';
      _selectedTimeSlots.text = eventData['selectedTimeSlots'] != null
          ? (eventData['selectedTimeSlots'] as List<dynamic>).join('\n')
          : '';
      _selectedFoodItems.text = eventData['selectedFoodItems'] != null
          ? (eventData['selectedFoodItems'] as List<dynamic>).join('\n')
          : '';
    } catch (e) {
      print('Error loading event data: $e');
    }
  }

  Future<void> _pickDate() async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (selectedDate != null) {
      setState(() {
        _eventDateController.text =
            "${selectedDate.year}-${selectedDate.month}-${selectedDate.day}";
      });
    }
  }

  List<File?> selectedImages = [null, null, null];
  Future<File?> compressImage(File file) async {
    final String outputPath =
        '${file.path}_compressed.jpg'; // Define the output path
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      outputPath,
      quality: 50, // Adjust the quality as needed
    );
    return File(outputPath); // Convert the compressed image path to File
  }

  Future<void> _addImage(int index) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      File? compressedImage = await compressImage(File(image.path));
      setState(() {
        selectedImages[index] = compressedImage;
      });
    }
  }

  Future<void> updateEventData() async {
    try {
      setState(() {
        isLoading = true;
      });
      await uploadImagesAndSaveData();

      final eventRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('events')
          .doc(widget.eventId);

      // Upload new images to Firebase Storage

      // Update Firestore with new image paths
      await eventRef.update({
        'eventName': _eventNameController.text,
        'eventDate': _eventDateController.text,
        'eventDetails': _eventDetailsController.text,
        'eventAddress': _eventAddressController.text,
        'eventPrice': _eventPriceController.text,
        'eventCapacity': _eventPriceController.text,
        'selectedFacilities':
            _selectedFacilitiesController.text.split('\n').toList(),
        'selectedFoodItems': _selectedFoodItems.text.split('\n').toList(),
        'selectedTimeSlots': _selectedTimeSlots.text.split('\n').toList(),
        'latitude': _selectedLocationLatLng?.latitude,
        'longitude': _selectedLocationLatLng?.longitude,
      });
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update event: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String? _selectedLocation;
  List<File> _selectedImages = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: const Color.fromARGB(255, 22, 22, 22),
        title: const Text('Edit Event'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              if (_validateInputs(context)) {
                updateEventData();
              }
            },
          ),
        ],
      ),
      body: Stack(children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _eventNameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Event Name',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
              TextFormField(
                controller: _eventCapacity,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Complex Capacity',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
              TextFormField(
                readOnly: true,
                controller: _eventDetailsController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Event Details',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: TextFormField(
                  style: const TextStyle(color: Colors.white),
                  readOnly: true,
                  controller: _eventAddressController,
                  onTap: () async {
                    var result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SelectLocationScreen(),
                      ),
                    );

                    if (result != null) {
                      _eventAddressController.text = result['address'];
                      _selectedLocationLatLng = result['latLng'];
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Event Address',
                    labelStyle: const TextStyle(color: Colors.white),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                  ),
                ),
              ),
              TextFormField(
                keyboardType: TextInputType.number,
                controller: _eventPriceController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Event Price',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < 3; i++)
                      GestureDetector(
                        onTap: () => _addImage(i),
                        child: Container(
                          width: 100,
                          height: 100,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.grey[800],
                          ),
                          child: selectedImages[i] == null
                              ? const Icon(Icons.image,
                                  size: 50, color: Colors.white)
                              : Image.file(selectedImages[i]!,
                                  fit: BoxFit.cover),
                        ),
                      ),
                  ],
                ),
              ),
              TextFormField(
                controller: _selectedFacilitiesController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Facilities (Separate with new line)',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                maxLines: null,
              ),
              TextFormField(
                controller: _selectedFoodItems,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Food Menu (Separate with new line)',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                maxLines: null,
              ),
              TextFormField(
                controller: _selectedTimeSlots,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Time slots (Separate with new line)',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                maxLines: null,
              ),
            ],
          ),
        ),
        if (isLoading) const Center(child: loadingWidget())
      ]),
    );
  }

  bool _validateInputs(BuildContext context) {
    if (_eventNameController.text.isEmpty ||
        _eventCapacity.text.isEmpty ||
        _eventDetailsController.text.isEmpty ||
        _eventAddressController.text.isEmpty ||
        _eventPriceController.text.isEmpty ||
        _selectedFacilitiesController.text.isEmpty ||
        _selectedFoodItems.text.isEmpty ||
        _selectedTimeSlots.text.isEmpty ||
        selectedImages.isEmpty) {
      _showErrorDialog(context, 'All fields must be filled');
      return false;
    }
    return true;
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: const Text('Error', style: TextStyle(color: Colors.red)),
          content: Text(message, style: const TextStyle(color: Colors.white)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
