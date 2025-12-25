import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fixmyooru/screens/issue_reporting_flow_screen.dart';
import 'package:fixmyooru/services/user_session.dart';
import 'package:fixmyooru/screens/login_register_screen.dart';
import 'package:flutter/material.dart';

class DuplicateSuggestionScreen extends StatelessWidget {
  final List<DocumentSnapshot> nearbyIssues;
  final String issueType;

  const DuplicateSuggestionScreen({
    super.key,
    required this.nearbyIssues,
    required this.issueType,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Existing Report Found'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'An issue like this has already been reported nearby. Are you trying to report one of these?',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: nearbyIssues.length,
                itemBuilder: (context, index) {
                  final data = nearbyIssues[index].data() as Map<String, dynamic>;
                  return SuggestionIssueCard(
                    issueData: data,
                    onUpvoted: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Thank you! Your upvote has increased this issue\'s priority.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('None of these, report a new issue'),
            ),
          ],
        ),
      ),
    );
  }
}

class SuggestionIssueCard extends StatefulWidget {
  final Map<String, dynamic> issueData;
  final VoidCallback? onUpvoted;

  // FIX 1: Constructor name now correctly matches the class name.
  const SuggestionIssueCard({super.key, required this.issueData, this.onUpvoted});

  @override
  // FIX 2: State type now correctly matches the widget.
  State<SuggestionIssueCard> createState() => _SuggestionIssueCardState();
}

// FIX 3: State class now correctly extends the State of its widget.
class _SuggestionIssueCardState extends State<SuggestionIssueCard> {
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thanks for confirming! We\'ve noted your input.')));
        widget.onUpvoted?.call();
        return;
      }

      final currentUpvotes = snapshot.data()?['upvotes'] ?? 0;
      final newUpvoteCount = currentUpvotes + 1;
      upvotedBy.add(userId);
      transaction.update(issueRef, {'upvotes': newUpvoteCount, 'upvotedBy': upvotedBy});

      if (mounted) {
        setState(() { _upvoteCount = newUpvoteCount; _isUpvoted = true; });
      }
      widget.onUpvoted?.call();

    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upvote: $error')));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      clipBehavior: Clip.antiAlias,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.issueData['issueType'] ?? 'Unknown Issue', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Chip(label: Text(widget.issueData['status'] ?? 'N/A')),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ElevatedButton.icon(
              onPressed: _handleUpvote,
              icon: Icon(_isUpvoted ? Icons.check_circle : Icons.thumb_up_outlined),
              // FIX 4: Updated button text to be more informative
              label: Text('Yes, this is it! ($_upvoteCount)'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: _isUpvoted ? Colors.green.withOpacity(0.2) : null,
                foregroundColor: _isUpvoted ? Colors.green : null,
              ),
            ),
          )
        ],
      ),
    );
  }
}