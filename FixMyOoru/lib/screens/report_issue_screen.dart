import 'package:flutter/material.dart';
import 'issue_reporting_flow_screen.dart';

class ReportIssueScreen extends StatelessWidget {
  const ReportIssueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report a New Issue')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What type of issue would you like to report?', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildIssueCard(context, 'Potholes', Icons.add_road_outlined, Colors.orange),
                  _buildIssueCard(context, 'Garbage', Icons.delete_outline, Colors.red),
                  _buildIssueCard(context, 'Streetlight', Icons.lightbulb_outline, Colors.amber),
                  _buildIssueCard(context, 'Water Logging', Icons.water_drop_outlined, Colors.blue),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIssueCard(BuildContext context, String title, IconData icon, Color color) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // This now navigates directly to the reporting flow again
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IssueReportingFlowScreen(issueType: title),
            ),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}