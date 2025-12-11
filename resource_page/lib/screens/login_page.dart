//Dependencies
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

//Page Set Up
class LogInPage extends StatefulWidget {
  const LogInPage({super.key});

  //Creates a state for main to use
  @override
  State<LogInPage> createState() => _LogInPageState();
}

//Page Details
class _LogInPageState extends State<LogInPage> {
  //This is for expanding the card
  //Academics Section
  bool academicsExpanded = false;
  bool tutoringOpen = false;
  bool advisingOpen = false;
  bool calendarOpen = false;
  bool catalogOpen = false;
  bool enrollmentOpen = false;
  bool helpcenterOpen = false;

  //This is the current text in the search query
  String _searchQuery = '';

  //Allows the url to open
  Future<void> _openLink(String url) async {
    //Turns string into url
    final uri = Uri.parse(url);

    //Opens the browser, if it fails an error message will pop up
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open link')));
      }
    }
  }

  //Allows resources to be searched
  bool _matchesQuery(String title, String url) {
    if (_searchQuery.isEmpty) return true;
    final q = _searchQuery.toLowerCase();
    return title.toLowerCase().contains(q) || url.toLowerCase().contains(q);
  }

  //The building of the page
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    //Page Set up
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surfaceVariant.withOpacity(0.3),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        //Page Details
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              //Padding
              const SizedBox(height: 12),

              Icon(
                Icons.flutter_dash,
                size: 100,
                color: Colors.blue,
              ),
              // Page header
              Text(
                'Sign in with email',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              // Search bar
              TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.trim();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search for a campus resource',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              //The space in between cards
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
