// Report Confirmation Page
// For Student Review 2 - Giselle made this

import 'package:flutter/material.dart';

class ReportSubmittedWidget extends StatelessWidget {
  final String title; // creating the report ! screen
  final String symbol;
  final Color circleColor;
  final VoidCallback? onExit;

  const ReportSubmittedWidget({
    super.key,
    this.title = "Report Submitted", // the icon title
    this.symbol = "!", // symbol
    this.circleColor = const Color(0xFFE53935), // color
    this.onExit, // exit
  });

  static const Color _submitGreen = Color(0xFFB7C300);

  @override
  Widget build(BuildContext context) {
    // creating the icon
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    color: circleColor,
                    shape: BoxShape.circle, // icon shape
                  ),
                  child: Center(
                    child: Text(
                      symbol,
                      style: const TextStyle(
                        // text format
                        fontSize: 110,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 26),

                SizedBox(
                  width: 180,
                  child: ElevatedButton(
                    // exit button
                    onPressed:
                        onExit ??
                        () =>
                            Navigator.of(
                              context,
                            ).pop(), // takes them back to prev page
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _submitGreen, // color
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Exit', // says exit
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
