import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // --- State Variables to track your settings ---
  bool _notificationsEnabled = true;
  bool _eventReminders = true;
  bool _foodAlerts = true;
  bool _systemAlerts = true;
  bool _locationAccess = true;
  bool _showBuildingLabels = true;
  bool _weatherAlerts = true;

  // Log out function
  void _logOut() async {
    await FirebaseAuth.instance.signOut();
    // Usually, auth state changes will handle navigation, but strictly popping can help too
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // Helper widget to build the section titles
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  // Helper widget to build the toggle buttons
  Widget _buildToggleOption(String label, bool value, VoidCallback onToggle) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggle, // This triggers the switch
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Text changes based on the boolean value
                Text(
                  "$label: ${value ? 'ON' : 'OFF'}",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper for non-toggle buttons (like Pin Color)
  Widget _buildStaticOption(String text, {Widget? trailing}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1)),
        ],
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        // This makes the back button appear to go back to Dashboard
        automaticallyImplyLeading: true, 
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(), // Exit to Dashboard
        ),
        backgroundColor: const Color(0xFFFFD700),
        elevation: 0,
        toolbarHeight: 70,
        title: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Settings',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              Icon(Icons.tune, color: Colors.blue, size: 20),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: _logOut,
            tooltip: 'Log Out',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Profile Settings Button
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.92,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Profile Settings',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ),

            // ----- Notifications Section -----
            _buildSectionHeader('Notifications'),
            _buildToggleOption('Enable Notifications', _notificationsEnabled, () {
              setState(() => _notificationsEnabled = !_notificationsEnabled);
            }),
            _buildToggleOption('Event Reminders', _eventReminders, () {
              setState(() => _eventReminders = !_eventReminders);
            }),
            _buildToggleOption('Food Alerts', _foodAlerts, () {
              setState(() => _foodAlerts = !_foodAlerts);
            }),
            _buildToggleOption('System Alerts', _systemAlerts, () {
              setState(() => _systemAlerts = !_systemAlerts);
            }),

            // ----- Location and Map Section -----
            _buildSectionHeader('Location and Map'),
            _buildToggleOption('Allow Location Access', _locationAccess, () {
              setState(() => _locationAccess = !_locationAccess);
            }),
            _buildToggleOption('Show Building Labels', _showBuildingLabels, () {
              setState(() => _showBuildingLabels = !_showBuildingLabels);
            }),
            // Static option (doesn't toggle ON/OFF in the text)
            _buildStaticOption(
              'Pin Color: Default',
              trailing: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Color(0xFFD9D9D9),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // ----- Weather Section -----
            _buildSectionHeader('Weather and Enviroment'),
            // Static option
            _buildStaticOption('Temperature Units: Fahrenheit'),
            _buildToggleOption('Weather Alerts', _weatherAlerts, () {
              setState(() => _weatherAlerts = !_weatherAlerts);
            }),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}