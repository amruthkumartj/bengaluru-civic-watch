import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fixmyooru/screens/login_register_screen.dart';
import 'package:fixmyooru/services/user_session.dart';
import 'package:flutter/material.dart';
import 'package:fixmyooru/screens/issue_detail_screen.dart';

class IssueDetailSheet extends StatefulWidget {
  final Map<String, dynamic> issueData;

  const IssueDetailSheet({super.key, required this.issueData});

  @override
  State<IssueDetailSheet> createState() => _IssueDetailSheetState();
}

class _IssueDetailSheetState extends State<IssueDetailSheet> {
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
        setState(() {
          _isUpvoted = true;
        });
      }
    }
  }

  Future<void> _handleUpvote() async {
    final user = UserSessionService().currentUser.value;
    if (user == null) {
      Navigator.pop(context);
      await Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginOrRegisterScreen()));
      return;
    }

    final userId = user['uid'];
    final issueId = widget.issueData['issueId'];
    final issueRef = FirebaseFirestore.instance.collection('issues').doc(issueId);

    FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(issueRef);
      if (!snapshot.exists) {
        throw Exception("Issue does not exist!");
      }
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
        setState(() {
          _upvoteCount = newUpvoteCount;
          _isUpvoted = true;
        });
      }
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upvote: $error')));
    });
  }

  // FIX: The build method was moved here, to be a direct member of the State class.
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.issueData['issueType'] ?? 'Issue Details',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Chip(
            label: Text('Status: ${widget.issueData['status'] ?? 'N/A'}'),
            avatar: const Icon(Icons.flag_outlined),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isUpvoted ? null : _handleUpvote,
                  icon: Icon(_isUpvoted ? Icons.thumb_up : Icons.thumb_up_outlined),
                  label: Text('Upvote ($_upvoteCount)'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.info_outline),
                tooltip: 'View Details',
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => IssueDetailScreen(issueData: widget.issueData),
                    ),
                  );
                },
              ),
            ],
          )
        ],
      ),
    );
  }
}