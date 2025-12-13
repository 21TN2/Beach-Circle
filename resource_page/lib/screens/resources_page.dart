//Dependencies
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

//Page Set Up
class ResourcesPage extends StatefulWidget {
  const ResourcesPage({super.key});

  //Creates a state for main to use
  @override
  State<ResourcesPage> createState() => _ResourcesPageState();
}

//Page Details
class _ResourcesPageState extends State<ResourcesPage> {
  //This is for expanding the card

  //Academics Section
  bool academicsExpanded = false;
  bool tutoringOpen = false;
  bool advisingOpen = false;
  bool calendarOpen = false;
  bool catalogOpen = false;
  bool enrollmentOpen = false;
  bool helpcenterOpen = false;

  //Mental Health Section
  bool mentalExpanded = false;
  bool accessibilityOpen = false;
  bool capsOpen = false;
  bool groupcounselingOpen = false;
  bool crisisOpen = false;

  // Care & Wellness Section
  bool careExpanded = false;
  bool needsOpen = false;
  bool balanceOpen = false;
  bool wellnessOpen = false;
  bool centerOpen = false;
  bool oceanOpen = false;

  // Student Development & Success
  bool developmentExpanded = false;
  bool careerOpen = false;
  bool internshipOpen = false;
  bool mentorOpen = false;
  bool researchOpen = false;
  bool graduateOpen = false;

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

    // ---------- URLs -----------------------------------------------
    //URL links from specific resources
    //Academic Section
    const tutoringUrl =
        'https://www.csulb.edu/academic-affairs/undergraduate-studies/tutoring-at-csulb';
    const advisingUrl = 'https://www.csulb.edu/undergraduate-advising';
    const calendarUrl =
        'https://www.csulb.edu/academic-affairs/academic-affairs-calendar';
    const catalogUrl = 'http://catalog.csulb.edu/';
    const enrollmentUrl = 'https://www.csulb.edu/enrollment-services';
    const helpcenterUrl = 'https://www.csulb.edu/information-technology';

    //Mental Health Section
    const accessbilityUrl =
        'https://www.csulb.edu/student-affairs/bob-murphy-access-center';
    const capsUrl =
        'https://www.csulb.edu/student-affairs/counseling-and-psychological-services/counseling-and-psychological-services';
    const groupcounselingUrl =
        'https://www.csulb.edu/student-affairs/counseling-and-psychological-services/group-counseling';
    const crisisUrl =
        'https://www.csulb.edu/student-affairs/beach-wellness/crisis-and-mental-health-resources';

    // Care & Wellness Section
    const needsUrl = 'https://www.csulb.edu/student-affairs/basic-needs';
    const balanceUrl = 'https://www.asirecreation.org/beach-balance';
    const wellnessUrl = 'https://www.csulb.edu/student-affairs/beach-wellness';
    const centerUrl = 'https://www.asirecreation.org/';
    const oceanUrl =
        'https://www.csulb.edu/student-affairs/counseling-and-psychological-services/rising-tides';

    // Success & Development
    const careerUrl =
        'https://www.csulb.edu/career-development-center/employers/employer-career-events';
    const internshipUrl =
        'https://www.csulb.edu/career-development-center/students/internships';
    const mentorUrl =
        'https://www.csulb.edu/student-affairs/mentoring-at-the-beach';
    const researchUrl =
        'https://www.csulb.edu/office-of-research-and-economic-development/student-research-opportunities';
    const graduateUrl =
        'https://www.csulb.edu/graduate-studies/graduate-programs-and-academic-advisors';

    // ---------- SEARCH MATCHES -------------------------------------
    //Check which sub-resources match the query, this is to search the resources
    //Academic Section
    final showTutoring = _matchesQuery('Tutoring', tutoringUrl);
    final showAdvising = _matchesQuery('Advising', advisingUrl);
    final showCalendar = _matchesQuery('Academic Calendar', calendarUrl);
    final showCatalog = _matchesQuery('Class Catalog', catalogUrl);
    final showEnrollment = _matchesQuery('Enrollment Service', enrollmentUrl);
    final showHelpcenter = _matchesQuery('Help Center', helpcenterUrl);

    //Mental Health Section
    final showAccessbility = _matchesQuery('Accessibility', accessbilityUrl);
    final showCaps = _matchesQuery('CAPS', capsUrl);
    final showGroup = _matchesQuery('Group Counseling', groupcounselingUrl);
    final showCrisis = _matchesQuery('Crisis Line', crisisUrl);

    // Care & Wellness Section
    final showNeeds = _matchesQuery('Basic Needs', needsUrl);
    final showBalance = _matchesQuery('Beach Balance', balanceUrl);
    final showWellness = _matchesQuery('Beach Wellness', wellnessUrl);
    final showCenter = _matchesQuery(
      'Student Recreation Center & Wellness',
      centerUrl,
    );
    final showOcean = _matchesQuery('Project Ocean', oceanUrl);

    // Success & Development
    final showCareer = _matchesQuery('Career Opportunities', careerUrl);
    final showInternship = _matchesQuery(
      'Internship Opportunities',
      internshipUrl,
    );
    final showMentor = _matchesQuery('Mentorship Program', mentorUrl);
    final showResearch = _matchesQuery('Research Opportunities', researchUrl);
    final showGraduate = _matchesQuery('Graduate Programs', graduateUrl);

    // Auto-expand Resource Title when searching
    final showAcademicsExpanded = academicsExpanded || _searchQuery.isNotEmpty;
    final showMentalExpanded = mentalExpanded || _searchQuery.isNotEmpty;
    final showCareExpanded = careExpanded || _searchQuery.isNotEmpty;
    final showDevelopmentExpanded =
        developmentExpanded || _searchQuery.isNotEmpty;
    //------------------------------------------------------------------

    //Page Set up
    return Scaffold(
      //Title
      appBar: AppBar(
        title: const Text('Resources4U'),
        centerTitle: true,
        backgroundColor: Colors.yellow,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
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
              // Page header
              Text(
                'Find the right campus resources fast.',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              // Image of CSULB
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  'https://raw.githubusercontent.com/21TN2/Beach-Circle/resourcepage/Bob%20Cole%20Conservatory%20of%20Music%20@%20CSULB.jpeg',
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),

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

              // ============================ ACADEMICS SECTION ===========================

              //------------------Academic Card(Main Card)---------------
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,

                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    setState(() {
                      //Allows the Card to expand
                      academicsExpanded = !academicsExpanded;
                    });
                  },

                  //Layering Card
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.yellow.shade100,
                            shape: BoxShape.circle,
                          ),

                          //Custom Icon
                          child: const Icon(
                            Icons.school,
                            color: Colors.black,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),

                        //Academic Card Title
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Academics',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),

                              //Academic description
                              Text(
                                'Tutoring, advising, calendar, and more !',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                              ),
                            ],
                          ),
                        ),

                        //Shows the arrow icon going up(opening) and going down(closing)
                        Icon(
                          showAcademicsExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              //------------------Academic card ends here-----------------------------
              const SizedBox(height: 8),

              //-------------------------------Sub Section Starting----------------------------------

              //Shows the sub-section of Academics(Tutoring, Calendar, etc.)
              if (showAcademicsExpanded) ...[
                const SizedBox(height: 4),

                // -------------------- TUTORING -------------------------------------------
                if (showTutoring)
                  //Card Details
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: Column(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setState(() {
                              //Allows tutoring to be opened
                              tutoringOpen = !tutoringOpen;
                            });
                          },

                          //Layering
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  //Add icon(Open) and subtract(Close)
                                  tutoringOpen ? Icons.remove : Icons.add,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),

                                //Title for sub card
                                const Expanded(
                                  child: Text(
                                    'Tutoring',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),

                                //External link icon
                                const Icon(Icons.open_in_new, size: 18),
                              ],
                            ),
                          ),
                        ),

                        //When Tutor card is open
                        if (tutoringOpen) ...[
                          const Divider(height: 1),
                          InkWell(
                            //Shows the link and allows it to be opened
                            onTap: () => _openLink(tutoringUrl),

                            //Layering
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                tutoringUrl,
                                style: TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                //Closes the card and adds the spacing
                if (showTutoring) const SizedBox(height: 8),

                // ---------------------- ADVISING --------------------------------------
                if (showAdvising)
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setState(() {
                              advisingOpen = !advisingOpen;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  advisingOpen ? Icons.remove : Icons.add,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Advising',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.open_in_new, size: 18),
                              ],
                            ),
                          ),
                        ),
                        if (advisingOpen) ...[
                          const Divider(height: 1),
                          InkWell(
                            onTap: () => _openLink(advisingUrl),
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                advisingUrl,
                                style: TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                if (showAdvising) const SizedBox(height: 8),

                // ----------------------------- ACADEMIC CALENDAR ---------------------------
                if (showCalendar)
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setState(() {
                              calendarOpen = !calendarOpen;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  calendarOpen ? Icons.remove : Icons.add,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Academic Calendar',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.open_in_new, size: 18),
                              ],
                            ),
                          ),
                        ),
                        if (calendarOpen) ...[
                          const Divider(height: 1),
                          InkWell(
                            onTap: () => _openLink(calendarUrl),
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                calendarUrl,
                                style: TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                if (showCalendar) const SizedBox(height: 8),

                /// --------------------- CLASS CATALOG --------------------------------------------
                if (showCatalog)
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setState(() {
                              catalogOpen = !catalogOpen;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  catalogOpen ? Icons.remove : Icons.add,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Class Catalog',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.open_in_new, size: 18),
                              ],
                            ),
                          ),
                        ),
                        if (catalogOpen) ...[
                          const Divider(height: 1),
                          InkWell(
                            onTap: () => _openLink(catalogUrl),
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                catalogUrl,
                                style: TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                if (showCatalog) const SizedBox(height: 8),
                // ------------------------  Enrollment ---------------------------------------------
                if (showEnrollment)
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setState(() {
                              enrollmentOpen = !enrollmentOpen;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  enrollmentOpen ? Icons.remove : Icons.add,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Enrollment',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.open_in_new, size: 18),
                              ],
                            ),
                          ),
                        ),
                        if (enrollmentOpen) ...[
                          const Divider(height: 1),
                          InkWell(
                            onTap: () => _openLink(enrollmentUrl),
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                enrollmentUrl,
                                style: TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                if (showEnrollment) const SizedBox(height: 8),
                // ------------------------ Help Center --------------------------------------------
                if (showHelpcenter)
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setState(() {
                              helpcenterOpen = !helpcenterOpen;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  helpcenterOpen ? Icons.remove : Icons.add,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Help Center',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.open_in_new, size: 18),
                              ],
                            ),
                          ),
                        ),
                        if (helpcenterOpen) ...[
                          const Divider(height: 1),
                          InkWell(
                            onTap: () => _openLink(helpcenterUrl),
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                helpcenterUrl,
                                style: TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                if (showHelpcenter) const SizedBox(height: 8),
                //-------If resources don't show up in the search bar -------------------------------
                if (!showTutoring &&
                    !showAdvising &&
                    !showCalendar &&
                    !showCatalog &&
                    !showEnrollment &&
                    !showHelpcenter)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'No academic resources match your search.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
              //==================================End of Academic Section============================================================

              //==================================Mental Health Section============================================================

              //------------------Mental Health Card------------------
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,

                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    setState(() {
                      //Allows the Card to expand
                      mentalExpanded = !mentalExpanded;
                    });
                  },

                  //Layering Card
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.yellow.shade100,
                            shape: BoxShape.circle,
                          ),

                          //Custom Icon
                          child: const Icon(
                            Icons.self_improvement,
                            color: Colors.black,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),

                        //Academic Card Title
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mental Health',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),

                              //Academic description
                              Text(
                                'CAPS, group counseling, accessibility, and more !',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                              ),
                            ],
                          ),
                        ),

                        //Shows the arrow icon going up(opening) and going down(closing)
                        Icon(
                          showMentalExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              //------------------Mental Health card ends here-----------------------------
              const SizedBox(height: 8),

              //-------------------------------Sub Section Starting----------------------------------

              //Shows the sub-section
              if (showMentalExpanded) ...[
                const SizedBox(height: 4),

                // -------------------- Accesibility -------------------------------------------
                if (showAccessbility)
                  //Card Details
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: Column(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setState(() {
                              //Allows accesiblity to be opened
                              accessibilityOpen = !accessibilityOpen;
                            });
                          },

                          //Layering
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  //Add icon(Open) and subtract(Close)
                                  accessibilityOpen ? Icons.remove : Icons.add,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),

                                //Title for sub card
                                const Expanded(
                                  child: Text(
                                    'Accesibility',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),

                                //External link icon
                                const Icon(Icons.open_in_new, size: 18),
                              ],
                            ),
                          ),
                        ),

                        //When Accesiblity card is open
                        if (accessibilityOpen) ...[
                          const Divider(height: 1),
                          InkWell(
                            //Shows the link and allows it to be opened
                            onTap: () => _openLink(accessbilityUrl),

                            //Layering
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                accessbilityUrl,
                                style: TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                //Closes the card and adds the spacing
                if (showAccessbility) const SizedBox(height: 8),

                // -------------------- CAPS -------------------------------------------
                if (showCaps)
                  //Card Details
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: Column(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setState(() {
                              //Allows card to be opened
                              capsOpen = !capsOpen;
                            });
                          },

                          //Layering
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  //Add icon(Open) and subtract(Close)
                                  capsOpen ? Icons.remove : Icons.add,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),

                                //Title for sub card
                                const Expanded(
                                  child: Text(
                                    'CAPS',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),

                                //External link icon
                                const Icon(Icons.open_in_new, size: 18),
                              ],
                            ),
                          ),
                        ),

                        //When Accesiblity card is open
                        if (capsOpen) ...[
                          const Divider(height: 1),
                          InkWell(
                            //Shows the link and allows it to be opened
                            onTap: () => _openLink(capsUrl),

                            //Layering
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                capsUrl,
                                style: TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                //Closes the card and adds the spacing
                if (showCaps) const SizedBox(height: 8),
                // -------------------- Group Counseling -------------------------------------------
                if (showGroup)
                  //Card Details
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: Column(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setState(() {
                              //Allows card to be opened
                              groupcounselingOpen = !groupcounselingOpen;
                            });
                          },

                          //Layering
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  //Add icon(Open) and subtract(Close)
                                  groupcounselingOpen
                                      ? Icons.remove
                                      : Icons.add,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),

                                //Title for sub card
                                const Expanded(
                                  child: Text(
                                    'Group Counseling',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),

                                //External link icon
                                const Icon(Icons.open_in_new, size: 18),
                              ],
                            ),
                          ),
                        ),

                        //When Accesiblity card is open
                        if (groupcounselingOpen) ...[
                          const Divider(height: 1),
                          InkWell(
                            //Shows the link and allows it to be opened
                            onTap: () => _openLink(groupcounselingUrl),

                            //Layering
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                groupcounselingUrl,
                                style: TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                //Closes the card and adds the spacing
                if (showGroup) const SizedBox(height: 8),

                // -------------------- Crisis Line -------------------------------------------
                if (showCrisis)
                  //Card Details
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: Column(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setState(() {
                              //Allows card to be opened
                              crisisOpen = !crisisOpen;
                            });
                          },

                          //Layering
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  //Add icon(Open) and subtract(Close)
                                  crisisOpen ? Icons.remove : Icons.add,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),

                                //Title for sub card
                                const Expanded(
                                  child: Text(
                                    'Crisis Line',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),

                                //External link icon
                                const Icon(Icons.open_in_new, size: 18),
                              ],
                            ),
                          ),
                        ),

                        //When Accesiblity card is open
                        if (crisisOpen) ...[
                          const Divider(height: 1),
                          InkWell(
                            //Shows the link and allows it to be opened
                            onTap: () => _openLink(crisisUrl),

                            //Layering
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                crisisUrl,
                                style: TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                //Closes the card and adds the spacing
                if (showCrisis) const SizedBox(height: 8),
                //-------If resources don't show up in the search bar -------------------------------
                if (!showAccessbility && !showCaps && !showGroup && !showCrisis)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'No Mental Health resources match your search.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
              //================================== Care & Wellness Section  ===========================================================

              // // ============================ Care & Wellness  ===========================

              //     //------------------Main Card------------------
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,

                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    setState(() {
                      //Allows the Card to expand
                      careExpanded = !careExpanded;
                    });
                  },

                  //Layering Card
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.yellow.shade100,
                            shape: BoxShape.circle,
                          ),

                          //Custom Icon
                          child: const Icon(
                            Icons.emoji_nature,
                            color: Colors.black,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Care & Welness Card Title
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Care & Wellness',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),

                              // Wellness description
                              Text(
                                'Basic Needs, Beach Wellness, Rising Tide, and more !',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                              ),
                            ],
                          ),
                        ),

                        //Shows the arrow icon going up(opening) and going down(closing)
                        Icon(
                          showCareExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              //------------------ Wellness card ends here-----------------------------
              const SizedBox(height: 8),

              //     //-------------------------------Sub Section Starting----------------------------------

              //               //Shows the sub-section of Wellness(Basic Needs, Beach Balnce, etc.)
              if (showCareExpanded) ...[
                const SizedBox(height: 4),

                //         // -------------------- Basic Needs -------------------------------------------
                if (showNeeds)
                  //Card Details
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: Column(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setState(() {
                              //Allows basic needs to be opened
                              needsOpen = !needsOpen;
                            });
                          },

                          //Layering
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  //Add icon(Open) and subtract(Close)
                                  needsOpen ? Icons.remove : Icons.add,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),

                                //Title for sub card
                                const Expanded(
                                  child: Text(
                                    'Basic Needs',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),

                                //External link icon
                                const Icon(Icons.open_in_new, size: 18),
                              ],
                            ),
                          ),
                        ),

                        //When Needs card is open
                        if (needsOpen) ...[
                          const Divider(height: 1),
                          InkWell(
                            //Shows the link and allows it to be opened
                            onTap: () => _openLink(needsUrl),

                            //Layering
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                needsUrl,
                                style: TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                //Closes the card and adds the spacing
                if (showNeeds) const SizedBox(height: 8),

                // --------------------  Beach Balance -------------------------------------------
                if (showBalance)
                  //Card Details
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: Column(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setState(() {
                              //Allows card to be opened
                              balanceOpen = !balanceOpen;
                            });
                          },

                          //Layering
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  //Add icon(Open) and subtract(Close)
                                  balanceOpen ? Icons.remove : Icons.add,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),

                                //Title for sub card
                                const Expanded(
                                  child: Text(
                                    'Beach Balance',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),

                                //External link icon
                                const Icon(Icons.open_in_new, size: 18),
                              ],
                            ),
                          ),
                        ),

                        //When Balance card is open
                        if (balanceOpen) ...[
                          const Divider(height: 1),
                          InkWell(
                            //Shows the link and allows it to be opened
                            onTap: () => _openLink(balanceUrl),

                            //Layering
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                balanceUrl,
                                style: TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                //Closes the card and adds the spacing
                if (showBalance) const SizedBox(height: 8),

                // -------------------- Beach Wellness -------------------------------------------
                if (showWellness)
                  //Card Details
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: Column(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setState(() {
                              //Allows card to be opened
                              wellnessOpen = !wellnessOpen;
                            });
                          },

                          //Layering
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  //Add icon(Open) and subtract(Close)
                                  wellnessOpen ? Icons.remove : Icons.add,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),

                                //Title for sub card
                                const Expanded(
                                  child: Text(
                                    'Beach Wellness',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),

                                //External link icon
                                const Icon(Icons.open_in_new, size: 18),
                              ],
                            ),
                          ),
                        ),

                        //When Wellness card is open
                        if (wellnessOpen) ...[
                          const Divider(height: 1),
                          InkWell(
                            //Shows the link and allows it to be opened
                            onTap: () => _openLink(wellnessUrl),

                            //Layering
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                wellnessUrl,
                                style: TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                //Closes the card and adds the spacing
                if (showWellness) const SizedBox(height: 8),

                // -------------------- Student Rec Center -------------------------------------------
                if (showCenter)
                  //Card Details
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: Column(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setState(() {
                              //Allows card to be opened
                              centerOpen = !centerOpen;
                            });
                          },

                          //Layering
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  //Add icon(Open) and subtract(Close)
                                  centerOpen ? Icons.remove : Icons.add,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),

                                //Title for sub card
                                const Expanded(
                                  child: Text(
                                    'Student Recreation Wellness Center',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),

                                //External link icon
                                const Icon(Icons.open_in_new, size: 18),
                              ],
                            ),
                          ),
                        ),

                        //When Rec Center card is open
                        if (centerOpen) ...[
                          const Divider(height: 1),
                          InkWell(
                            //Shows the link and allows it to be opened
                            onTap: () => _openLink(centerUrl),

                            //Layering
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                centerUrl,
                                style: TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                //Closes the card and adds the spacing
                if (showCenter) const SizedBox(height: 8),

                // -------------------- Rising Tide / Project Ocean -------------------------------------------
                if (showOcean)
                  //Card Details
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: Column(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setState(() {
                              //Allows card to be opened
                              oceanOpen = !oceanOpen;
                            });
                          },

                          //Layering
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  //Add icon(Open) and subtract(Close)
                                  oceanOpen ? Icons.remove : Icons.add,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),

                                //Title for sub card
                                const Expanded(
                                  child: Text(
                                    'Rising Tide',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),

                                //External link icon
                                const Icon(Icons.open_in_new, size: 18),
                              ],
                            ),
                          ),
                        ),

                        //When Rising Tide card is open
                        if (oceanOpen) ...[
                          const Divider(height: 1),
                          InkWell(
                            //Shows the link and allows it to be opened
                            onTap: () => _openLink(oceanUrl),

                            //Layering
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                oceanUrl,
                                style: TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                //Closes the card and adds the spacing
                if (showOcean) const SizedBox(height: 8),

                //-------If resources don't show up in the search bar -------------------------------
                if (!showNeeds &&
                    !showBalance &&
                    !showWellness &&
                    !showCenter &&
                    !showOcean)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'No Careness & Wellness resources match your search.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],

              //================================== Success & Development Section  ===========================================================

              // // ============================ Success & Development ===========================

              //     //------------------Main Card------------------
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,

                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    setState(() {
                      //Allows the Card to expand
                      developmentExpanded = !developmentExpanded;
                    });
                  },

                  //Layering Card
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.yellow.shade100,
                            shape: BoxShape.circle,
                          ),

                          //Custom Icon
                          child: const Icon(
                            Icons.diversity_3,
                            color: Colors.black,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Success & Development Card Title
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Success & Development',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),

                              // Development description
                              Text(
                                'Career Development, Internship Opportunities, Mentoring, and more !',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                              ),
                            ],
                          ),
                        ),

                        //Shows the arrow icon going up(opening) and going down(closing)
                        Icon(
                          showDevelopmentExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              //------------------ Development card ends here-----------------------------
              const SizedBox(height: 8),

              //     //-------------------------------Sub Section Starting----------------------------------

              //               //Shows the sub-section of Development(Career, Internship, etc.)
              if (showDevelopmentExpanded) ...[
                const SizedBox(height: 4),

                //         // -------------------- Career Development -------------------------------------------
                if (showCareer)
                  //Card Details
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: Column(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setState(() {
                              //Allows Career Development to be opened
                              careerOpen = !careerOpen;
                            });
                          },

                          //Layering
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  //Add icon(Open) and subtract(Close)
                                  careerOpen ? Icons.remove : Icons.add,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),

                                //Title for sub card
                                const Expanded(
                                  child: Text(
                                    'Career Development',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),

                                //External link icon
                                const Icon(Icons.open_in_new, size: 18),
                              ],
                            ),
                          ),
                        ),

                        //When Career Development card is open
                        if (careerOpen) ...[
                          const Divider(height: 1),
                          InkWell(
                            //Shows the link and allows it to be opened
                            onTap: () => _openLink(careerUrl),

                            //Layering
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                careerUrl,
                                style: TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                //Closes the card and adds the spacing
                if (showCareer) const SizedBox(height: 8),

                // -------------------- Internship Opportunities -------------------------------------------
                if (showInternship)
                  //Card Details
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: Column(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setState(() {
                              //Allows Career Development to be opened
                              internshipOpen = !internshipOpen;
                            });
                          },

                          //Layering
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  //Add icon(Open) and subtract(Close)
                                  internshipOpen ? Icons.remove : Icons.add,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),

                                //Title for sub card
                                const Expanded(
                                  child: Text(
                                    'Internship Opportunities',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),

                                //External link icon
                                const Icon(Icons.open_in_new, size: 18),
                              ],
                            ),
                          ),
                        ),

                        //When Internship Opportunties card is open
                        if (internshipOpen) ...[
                          const Divider(height: 1),
                          InkWell(
                            //Shows the link and allows it to be opened
                            onTap: () => _openLink(internshipUrl),

                            //Layering
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                internshipUrl,
                                style: TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                //Closes the card and adds the spacing
                if (showInternship) const SizedBox(height: 8),

                //  -------------------- Research Programs -------------------------------------------
                if (researchOpen)
                  //Card Details
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: Column(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setState(() {
                              //Allows Research Program to be opened
                              researchOpen = !researchOpen;
                            });
                          },

                          //Layering
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  //Add icon(Open) and subtract(Close)
                                  researchOpen ? Icons.remove : Icons.add,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),

                                //Title for sub card
                                const Expanded(
                                  child: Text(
                                    'Research Opportunities',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),

                                //External link icon
                                const Icon(Icons.open_in_new, size: 18),
                              ],
                            ),
                          ),
                        ),

                        //When Research Program Opportunities card is open
                        if (researchOpen) ...[
                          const Divider(height: 1),
                          InkWell(
                            //Shows the link and allows it to be opened
                            onTap: () => _openLink(researchUrl),

                            //Layering
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                researchUrl,
                                style: TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                //Closes the card and adds the spacing
                if (showResearch) const SizedBox(height: 8),

                // -------------------- Mentoring Program -------------------------------------------
                if (showMentor)
                  //Card Details
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: Column(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setState(() {
                              //Allows Mentoring Program to be opened
                              mentorOpen = !mentorOpen;
                            });
                          },

                          //Layering
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  //Add icon(Open) and subtract(Close)
                                  mentorOpen ? Icons.remove : Icons.add,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),

                                //Title for sub card
                                const Expanded(
                                  child: Text(
                                    'Mentoring Program',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),

                                //External link icon
                                const Icon(Icons.open_in_new, size: 18),
                              ],
                            ),
                          ),
                        ),

                        //When Mentoring Program card is open
                        if (mentorOpen) ...[
                          const Divider(height: 1),
                          InkWell(
                            //Shows the link and allows it to be opened
                            onTap: () => _openLink(mentorUrl),

                            //Layering
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                mentorUrl,
                                style: TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                //Closes the card and adds the spacing
                if (showMentor) const SizedBox(height: 8),

                // -------------------- Research Opportunities -------------------------------------------
                if (showResearch)
                  //Card Details
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: Column(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setState(() {
                              //Allows Research Program to be opened
                              researchOpen = !researchOpen;
                            });
                          },

                          //Layering
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  //Add icon(Open) and subtract(Close)
                                  researchOpen ? Icons.remove : Icons.add,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),

                                //Title for sub card
                                const Expanded(
                                  child: Text(
                                    'Research Opportunities',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),

                                //External link icon
                                const Icon(Icons.open_in_new, size: 18),
                              ],
                            ),
                          ),
                        ),

                        //When Research Program card is open
                        if (researchOpen) ...[
                          const Divider(height: 1),
                          InkWell(
                            //Shows the link and allows it to be opened
                            onTap: () => _openLink(researchUrl),

                            //Layering
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                researchUrl,
                                style: TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                //Closes the card and adds the spacing
                if (showResearch) const SizedBox(height: 8),

                //  -------------------- Graduate Studies -------------------------------------------
                if (showGraduate)
                  //Card Details
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: Column(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setState(() {
                              //Allows Graduate Studies to be opened
                              graduateOpen = !graduateOpen;
                            });
                          },

                          //Layering
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  //Add icon(Open) and subtract(Close)
                                  graduateOpen ? Icons.remove : Icons.add,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),

                                //Title for sub card
                                const Expanded(
                                  child: Text(
                                    'Graduate Programs @ the Beach',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),

                                //External link icon
                                const Icon(Icons.open_in_new, size: 18),
                              ],
                            ),
                          ),
                        ),

                        //When Graduate Program card is open
                        if (graduateOpen) ...[
                          const Divider(height: 1),
                          InkWell(
                            //Shows the link and allows it to be opened
                            onTap: () => _openLink(graduateUrl),

                            //Layering
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                graduateUrl,
                                style: TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                //Closes the card and adds the spacing
                if (showGraduate) const SizedBox(height: 8),

                //-------If resources don't show up in the search bar -------------------------------
                if (!showCareer &&
                    !showInternship &&
                    !showMentor &&
                    !showResearch &&
                    !showGraduate)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'No Development & Success resources match your search.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
