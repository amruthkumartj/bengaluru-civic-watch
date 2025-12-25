import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:fixmyooru/widgets/fullscreen_image_viewer.dart';
import 'package:fixmyooru/services/user_session.dart';
class IssueDetailScreen extends StatelessWidget {
  final Map<String, dynamic> issueData;

  const IssueDetailScreen({super.key, required this.issueData});

  @override
  Widget build(BuildContext context) {
    final location = issueData['location'] as GeoPoint;
    final issuePosition = LatLng(location.latitude, location.longitude);
    return Scaffold(
      appBar: AppBar(
        title: Text(issueData['issueType'] ?? 'Issue Detail'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Top Section ---
              Text(
                issueData['issueType'] ?? 'Unknown Issue',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Chip(
                    label: Text('Status: ${issueData['status'] ?? 'N/A'}'),
                    avatar: const Icon(Icons.flag_outlined, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text('Upvotes: ${issueData['upvotes'] ?? 0}'),
                    avatar: const Icon(Icons.thumb_up_outlined, size: 16),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- Image Section ---
              if (issueData['imageUrl'] != null)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FullScreenImageViewer(imageUrl: issueData['imageUrl']),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Image.network(
                      issueData['imageUrl'],
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // --- Map Button Section ---
              ElevatedButton.icon(
                onPressed: () {
                  // 1. Set the location to focus on using our service
                  UserSessionService().locationToFocus.value = issuePosition;

                  // 2. Navigate all the way back to the main map screen
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                icon: const Icon(Icons.location_on_outlined),
                label: const Text('View on Main Map'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}