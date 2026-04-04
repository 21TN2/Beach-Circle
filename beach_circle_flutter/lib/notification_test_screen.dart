import 'package:flutter/material.dart';

class NotificationTestScreen extends StatelessWidget {
  const NotificationTestScreen({super.key});

  void _showTopNotification(BuildContext context) {
    // 1. Create the Entry
    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            top: 50, // Distance from top
            left: 20,
            right: 20,
            child: Material(
              color: Colors.transparent,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: -100, end: 0), // Slide from -100px to 0px
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, value),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.notifications_active,
                            color: Colors.yellow,
                          ),
                          SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              "This is a test notification",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
    );

    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry?.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Secret Notification Lab")),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: () => _showTopNotification(context),
          icon: const Icon(Icons.touch_app),
          label: const Text("Trigger Test Notification"),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            textStyle: const TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}
