// lib/screens/issue_reporting_flow_screen.dart
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fixmyooru/services/user_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

enum ReportStep { askPresence, pinpointOnMap, confirmImage }

class IssueReportingFlowScreen extends StatefulWidget {
  final String issueType;
  const IssueReportingFlowScreen({super.key, required this.issueType});
  @override
  State<IssueReportingFlowScreen> createState() => _IssueReportingFlowScreenState();
}

class _IssueReportingFlowScreenState extends State<IssueReportingFlowScreen> {
  ReportStep _currentStep = ReportStep.askPresence;
  LatLng? _pinpointedLocation;
  XFile? _capturedImage;
  bool _isLoading = false;
  GoogleMapController? _mapController;
  String? _darkMapStyle;

  @override
  void initState() {
    super.initState();
    rootBundle.loadString('assets/map_style.json').then((string) => _darkMapStyle = string);
  }

// In _IssueReportingFlowScreenState class inside issue_reporting_flow_screen.dart

  Future<void> _submitReport() async {
    if (_capturedImage == null || _pinpointedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Missing data to submit.')));
      return;
    }
    setState(() { _isLoading = true; });

    try {
      // ** THIS IS THE FIX: Refresh the anonymous session to ensure it's valid **
      await FirebaseAuth.instance.signInAnonymously();

      final userData = UserSessionService().currentUser.value;
      if (userData == null) throw Exception('User data not found in session. Please log in again.');

      final issueId = const Uuid().v4();
      final imageFile = File(_capturedImage!.path);
      final storageRef = FirebaseStorage.instance.ref().child('issue_images').child('$issueId.jpg');

      // 1. Upload image to Firebase Storage
      await storageRef.putFile(imageFile);
      final imageUrl = await storageRef.getDownloadURL();

      // 2. Determine the issue zone
      final issueZone = _getIssueZone(_pinpointedLocation!);

      // 3. Prepare the data for Firestore
      final issueData = {
        'issueId': issueId,
        'issueType': widget.issueType,
        'imageUrl': imageUrl,
        'location': GeoPoint(_pinpointedLocation!.latitude, _pinpointedLocation!.longitude),
        'issueZone': issueZone,
        'severity': 'Low',
        'status': 'Submitted',
        'timestamp': FieldValue.serverTimestamp(),
        'userId': userData['uid'],
        'userName': userData['name'],
        'userPhone': userData['phone'],
      };

      // 4. Save the report to Firestore
      await FirebaseFirestore.instance.collection('issues').doc(issueId).set(issueData);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report submitted successfully!'), backgroundColor: Colors.green,));
      Navigator.of(context).popUntil((route) => route.isFirst);

    } catch (e) {
      print('Error submitting report: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit report: $e')));
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  String _getIssueZone(LatLng point) {
    if (point.latitude > 13.05 && point.longitude < 77.6) return 'BLRN';  // North
    if (point.latitude < 12.90 && point.longitude < 77.6) return 'BLRS';  // South
    if (point.latitude > 12.95 && point.longitude > 77.65) return 'BLRE';  // East
    if (point.latitude < 13.05 && point.longitude < 77.5) return 'BLRW';  // West
    if (point.latitude > 13.05 && point.longitude > 77.65) return 'BLRNE'; // North-East
    if (point.latitude < 12.95 && point.longitude > 77.65) return 'BLRSE'; // South-East
    return 'BLRC'; // Default to Central
  }

  Future<void> _getCurrentLocationAndProceed() async {
    setState(() { _isLoading = true; });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services are disabled.');
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw Exception('Location permissions are denied.');
      }
      if (permission == LocationPermission.deniedForever) throw Exception('Location permissions are permanently denied.');

      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _pinpointedLocation = LatLng(position.latitude, position.longitude);

      setState(() {
        _currentStep = ReportStep.pinpointOnMap;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        setState(() { _isLoading = false; });
      }
    }
  }

  Future<void> _takePicture() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
      if (image != null) {
        setState(() {
          _capturedImage = image;
          _currentStep = ReportStep.confirmImage;
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to access camera.')));
    }
  }

  void _showRelaunchDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Location Issue'),
        content: const Text('If the pin is not pointing correctly, please close the app, turn your device location off and on, then relaunch to try again.'),
        actions: <Widget>[
          TextButton(child: const Text('OK'), onPressed: () => SystemNavigator.pop()),
        ],
      ),
    );
  }

  void _applyMapStyle() {
    if (Theme.of(context).brightness == Brightness.dark && _darkMapStyle != null) {
      _mapController?.setMapStyle(_darkMapStyle);
    } else {
      _mapController?.setMapStyle(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Report: ${widget.issueType}')),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildCurrentStepWidget(),
      ),
    );
  }

  Widget _buildCurrentStepWidget() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    switch (_currentStep) {
      case ReportStep.askPresence: return _buildPresenceQuestion();
      case ReportStep.pinpointOnMap: return _buildPinpointMap();
      case ReportStep.confirmImage: return _buildImageConfirmer();
    }
  }

  Widget _buildPresenceQuestion() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on_outlined, size: 60, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text('Are you at the location of the issue right now?', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You must be at the location to report an issue.'))), child: const Text('No')),
              ElevatedButton(onPressed: _getCurrentLocationAndProceed, child: const Text('Yes, I am here')),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPinpointMap() {
    final Set<Marker> markers = {
      Marker(
        markerId: const MarkerId('issue_location_pin'),
        position: _pinpointedLocation!,
        draggable: true,
        onDragEnd: (newPosition) => setState(() => _pinpointedLocation = newPosition),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      )
    };
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(target: _pinpointedLocation!, zoom: 18.0),
                markers: markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                onMapCreated: (controller) {
                  _mapController = controller;
                  _applyMapStyle();
                },
              ),
              Positioned(
                bottom: 16,
                left: 16,
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Lat: ${_pinpointedLocation?.latitude.toStringAsFixed(6)}\nLng: ${_pinpointedLocation?.longitude.toStringAsFixed(6)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16.0),
          color: Theme.of(context).cardColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Is the pin pointing to the correct issue location?', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: _showRelaunchDialog, child: const Text('Pin is not correct'))),
                  const SizedBox(width: 16),
                  Expanded(child: ElevatedButton(onPressed: _takePicture, child: const Text('Confirm & Proceed'))),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageConfirmer() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Confirm Image', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(File(_capturedImage!.path), fit: BoxFit.cover))),
          const SizedBox(height: 16),
          Text('Is this image clear and correct?', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _submitReport, child: const Text('Submit')),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: _takePicture, child: const Text('Take Again')),
        ],
      ),
    );
  }
}