import 'package:flutter/material.dart';
import 'interested_button.dart';
import 'report_button.dart';

class ForumPostTile extends StatefulWidget {
  final String title;
  final String description;
  final bool isInterested;
  final VoidCallback onInterestedTap;
  final VoidCallback onReportTap;

  const ForumPostTile({
    super.key,
    required this.title,
    required this.description,
    required this.isInterested,
    required this.onInterestedTap,
    required this.onReportTap,
  });

  @override
  State<ForumPostTile> createState() => _ForumPostTileState();
}

class _ForumPostTileState extends State<ForumPostTile> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(isExpanded ? Icons.remove : Icons.add),
                onPressed: () {
                  setState(() {
                    isExpanded = !isExpanded;
                  });
                },
              ),
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ),
              InterestedButton(
                isInterested: widget.isInterested,
                onPressed: widget.onInterestedTap,
              ),
              ReportButton(onPressed: widget.onReportTap),
            ],
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 40, top: 8),
              child: Text(widget.description),
            ),
        ],
      ),
    );
  }
}
