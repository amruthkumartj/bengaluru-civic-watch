import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fixmyooru/screens/issue_detail_screen.dart';
import 'package:fixmyooru/screens/login_register_screen.dart';
import 'package:fixmyooru/services/user_session.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class NearbyIssuesScreen extends StatefulWidget {
  const NearbyIssuesScreen({super.key});

  @override
  State<NearbyIssuesScreen> createState() => _NearbyIssuesScreenState();
}

class _NearbyIssuesScreenState extends State<NearbyIssuesScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  final List<DocumentSnapshot> _issues = [];
  StreamSubscription<List<DocumentSnapshot>>? _issueStreamSubscription;
  bool _isListView = true;
  Position? _userPosition;

  @override
  void initState() {
    super.initState();
    _fetchNearbyIssues();
  }

  @override
  void dispose() {
    _issueStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchNearbyIssues() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services are disabled.');
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw Exception('Location permissions are denied.');
      }
      if (permission == LocationPermission.deniedForever) throw Exception('Location permissions are permanently denied.');
      setState(() { _isLoading = true; _errorMessage = ''; });
      Position position = await Geolocator.getCurrentPosition();
      _userPosition = position;
      final userLocation = GeoPoint(position.latitude, position.longitude);
      final geoCollection = GeoCollectionReference(FirebaseFirestore.instance.collection('issues'));
      const radiusInKm = 5.0;
      final center = GeoFirePoint(userLocation);
      _issueStreamSubscription = geoCollection.subscribeWithin(
        center: center,
        radiusInKm: radiusInKm,
        field: 'position',
        strictMode: true,
        geopointFrom: (data) {
          final position = data['position'] as Map<String, dynamic>;
          return position['geopoint'] as GeoPoint;
        },
        queryBuilder: (query) {
          return query.where('status', whereIn: ['Approved', 'InProgress']);
        },
      ).listen((docs) {
        if (mounted) setState(() { _issues.clear(); _issues.addAll(docs); _isLoading = false; });
      }, onError: (error) {
        if (mounted) setState(() { _errorMessage = 'Failed to load issues: $error'; _isLoading = false; });
      });
    } catch (e) {
      if (mounted) setState(() { _errorMessage = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Issues Near You'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ToggleButtons(
              isSelected: [_isListView, !_isListView],
              onPressed: (index) => setState(() => _isListView = index == 0),
              borderRadius: BorderRadius.circular(8),
              selectedBorderColor: Theme.of(context).colorScheme.primary,
              selectedColor: Theme.of(context).colorScheme.primary,
              children: const [ Icon(Icons.view_list_outlined), Icon(Icons.map_outlined) ],
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage.isNotEmpty) return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text('Error: $_errorMessage', textAlign: TextAlign.center)));
    if (_issues.isEmpty) return const Center(child: Text('No issues found within a 5km radius.'));
    return _isListView ? _buildListView() : _buildMapView();
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _issues.length,
      itemBuilder: (context, index) {
        final data = _issues[index].data() as Map<String, dynamic>;
        return IssueCard(issueData: data);
      },
    );
  }

  Widget _buildMapView() {
    if (_userPosition == null) return const Center(child: Text('Fetching user location...'));
    final markers = _issues.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final location = data['location'] as GeoPoint;
      return Marker(
        markerId: MarkerId(doc.id),
        position: LatLng(location.latitude, location.longitude),
        infoWindow: InfoWindow(title: data['issueType'] ?? 'Issue', snippet: 'Status: ${data['status']}'),
      );
    }).toSet();
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: LatLng(_userPosition!.latitude, _userPosition!.longitude), zoom: 14),
      markers: markers,
      myLocationEnabled: true,
    );
  }
}
// PASTE THIS NEW WIDGET AT THE BOTTOM OF nearby_issues_screen.dart

class IssueCard extends StatefulWidget {
  final Map<String, dynamic> issueData;
  const IssueCard({super.key, required this.issueData});

  @override
  State<IssueCard> createState() => _IssueCardState();
}

class _IssueCardState extends State<IssueCard> {
  late int _upvoteCount;
  bool _isUpvoted = false;

  @override
  void initState() {
    super.initState();
    _upvoteCount = widget.issueData['upvotes'] ?? 0;
    _checkIfUpvoted();
  }

  void _checkIfUpvoted() {
    final currentUser = UserSessionService().currentUser.value;
    if (currentUser != null) {
      final upvotedBy = widget.issueData['upvotedBy'] as List<dynamic>;
      if (upvotedBy.contains(currentUser['uid'])) {
        setState(() => _isUpvoted = true);
      }
    }
  }

  Future<void> _handleUpvote() async {
    final user = UserSessionService().currentUser.value;
    if (user == null) {
      await Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginOrRegisterScreen()));
      return;
    }
    final userId = user['uid'];
    final issueId = widget.issueData['issueId'];
    final issueRef = FirebaseFirestore.instance.collection('issues').doc(issueId);

    FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(issueRef);
      if (!snapshot.exists) throw Exception("Issue does not exist!");
      final List<dynamic> upvotedBy = List.from(snapshot.data()?['upvotedBy'] ?? []);
      if (upvotedBy.contains(userId)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You have already upvoted this issue.')));
        return;
      }
      final currentUpvotes = snapshot.data()?['upvotes'] ?? 0;
      final newUpvoteCount = currentUpvotes + 1;
      upvotedBy.add(userId);
      transaction.update(issueRef, {'upvotes': newUpvoteCount, 'upvotedBy': upvotedBy});
      if (mounted) {
        setState(() { _upvoteCount = newUpvoteCount; _isUpvoted = true; });
      }
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upvote: $error')));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell( // Makes the whole card tappable for navigation
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => IssueDetailScreen(issueData: widget.issueData)),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.issueData['imageUrl'] != null)
              Image.network(
                widget.issueData['imageUrl'],
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) => progress == null ? child : const Center(heightFactor: 4, child: CircularProgressIndicator()),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.issueData['issueType'] ?? 'Unknown Issue', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Chip(label: Text(widget.issueData['status'] ?? 'N/A')),
                      ],
                    ),
                  ),
                  // The small upvote button
                  TextButton.icon(
                    onPressed: _isUpvoted ? null : _handleUpvote,
                    icon: Icon(_isUpvoted ? Icons.thumb_up : Icons.thumb_up_outlined),
                    label: Text('$_upvoteCount'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

