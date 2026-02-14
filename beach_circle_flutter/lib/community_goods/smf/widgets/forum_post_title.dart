// REUSABLE FORUM POST TILE WIDGET

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
  // EXPANDED OR COLLAPSED
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      // VERTICAL SPACING
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
              // EXPAND/COLLAPSE BUTTON
              IconButton(
                icon: Icon(isExpanded ? Icons.remove : Icons.add),
                onPressed: () {
                  setState(() {
                    isExpanded = !isExpanded;
                  });
                },
              ),

              // POST TITLE
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ),

              // INTERESTED BUTTON
              InterestedButton(
                isInterested: widget.isInterested,
                onPressed: widget.onInterestedTap,
              ),

              // REPORT BUTTON
              ReportButton(
                onPressed: widget.onReportTap,
              ),
            ],
          ),

          // POST DESCRIPTION WHEN EXPANDED
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