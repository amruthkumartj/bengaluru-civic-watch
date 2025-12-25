import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fixmyooru/services/user_session.dart';
import 'package:flutter/material.dart';
import 'issue_detail_screen.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _myReports = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchMyReports();
  }

  Future<void> _fetchMyReports() async {
    final currentUser = UserSessionService().currentUser.value;
    if (currentUser == null) {
      setState(() {
        _isLoading = false;
        _error = "You must be logged in to see your reports.";
      });
      return;
    }

    final userId = currentUser['uid'];

    try {
      // Create two separate queries
      final activeIssuesQuery = FirebaseFirestore.instance
          .collection('issues')
          .where('userId', isEqualTo: userId);

      final resolvedIssuesQuery = FirebaseFirestore.instance
          .collection('resolved_issues')
          .where('userId', isEqualTo: userId);

      // Fetch the data from both queries at the same time
      final results = await Future.wait([
        activeIssuesQuery.get(),
        resolvedIssuesQuery.get(),
      ]);

      final activeIssues = results[0].docs.map((doc) => doc.data()).toList();
      final resolvedIssues = results[1].docs.map((doc) => doc.data()).toList();

      // Combine the two lists into one
      final allReports = [...activeIssues, ...resolvedIssues];

      // Sort the combined list by timestamp, newest first
      allReports.sort((a, b) {
        final timestampA = a['timestamp'] as Timestamp?;
        final timestampB = b['timestamp'] as Timestamp?;
        return (timestampB?.millisecondsSinceEpoch ?? 0)
            .compareTo(timestampA?.millisecondsSinceEpoch ?? 0);
      });

      if (mounted) {
        setState(() {
          _myReports = allReports;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = "Failed to load reports: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reports'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_myReports.isEmpty) {
      return const Center(child: Text('You have not reported any issues yet.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _myReports.length,
      itemBuilder: (context, index) {
        final report = _myReports[index];
        return _buildReportTile(report);
      },
    );
  }

  Widget _buildReportTile(Map<String, dynamic> report) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IssueDetailScreen(issueData: report),
            ),
          );
        },
        child: Row(
          children: [
            if (report['imageUrl'] != null)
              Image.network(
                report['imageUrl'],
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report['issueType'] ?? 'Unknown Issue',
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(report['status'] ?? 'N/A', style: const TextStyle(fontSize: 12)),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}