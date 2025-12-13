//Dependencies
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
  bool clubsOpen = false;

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

    //Caps Social Media
    const capsInstagramUrl = 'https://www.instagram.com/csulbcaps/';
    const capsFacebookUrl = 'https://www.facebook.com/csulongbeachCAPS/';
    const capsLinktreeUrl = 'https://linktr.ee/csulongbeachcaps';

    // Care & Wellness Section
    const needsUrl = 'https://www.csulb.edu/student-affairs/basic-needs';
    const balanceUrl = 'https://www.asirecreation.org/beach-balance';
    const wellnessUrl = 'https://www.csulb.edu/student-affairs/beach-wellness';
    const centerUrl = 'https://www.asirecreation.org/';
    const oceanUrl =
        'https://www.csulb.edu/student-affairs/counseling-and-psychological-services/rising-tides';

    // Basic Needs socials
    const needsInstagramUrl = 'https://www.instagram.com/basicneedscsulb/';
    const needsLinktreeUrl = 'https://linktr.ee/basicneedscsulb';

    // Student Recreation & Wellness Center socials
    const centerInstagramUrl = 'https://www.instagram.com/csulbsrwc/';

    // Project OCEAN / Rising Tides socials
    const oceanInstagramUrl = 'https://www.instagram.com/projectocean_csulb/';
    const oceanLinktreeUrl = 'https://linktr.ee/CSULBProjectOCEAN';

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
    const clubsMainUrl =
        'https://www.csulb.edu/sustainability/clubs-organizations';
    const clubsDirectoryUrl =
        'https://csulb.campuslabs.com/engage/organizations';
    // ASI (Associated Students, Inc.) Social Media
    const asiWebsiteUrl = 'https://www.instagram.com/csulbasi/';
    const asiInstagramUrl = 'https://www.instagram.com/csulbasi/';
    const asiFacebookUrl = 'https://www.facebook.com/csulbasi/';
    const asiTwitterUrl = 'https://twitter.com/csulbasi';
    const asiTikTokUrl = 'https://www.tiktok.com/@csulbasi';

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
    final showClubs =
        _matchesQuery('Clubs & Organizations', clubsMainUrl) ||
        _matchesQuery('Clubs & Organizations', clubsDirectoryUrl);

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
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Short description
                                Text(
                                  'Tutoring helps you review course material, prepare for exams, '
                                  'and build strong study habits across many subjects.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 8),

                                // Hours / appointment info
                                Text(
                                  'Hours & how to get help:',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Hours and availability can change each term. '
                                  'Check the tutoring website for the most current schedule and how to sign up for sessions.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 12),

                                // Button with icon (similar style to CAPS)
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _openLink(tutoringUrl),
                                      icon: const FaIcon(
                                        FontAwesomeIcons.globe,
                                        size: 20,
                                      ),
                                      label: const Text(
                                        'Open Tutoring website',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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

                        //when card is open
                        if (advisingOpen) ...[
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Undergraduate advising helps you plan your classes, stay on track '
                                  'for graduation, and understand university policies.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Appointments & hours:',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Most advising is scheduled online through your college advising center. '
                                  'Appointment availability and drop-in hours are listed on the website.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _openLink(advisingUrl),
                                      icon: const FaIcon(
                                        FontAwesomeIcons.globe,
                                        size: 18,
                                      ),
                                      label: const Text(
                                        'Open Advising website',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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

                        //When card is open
                        if (calendarOpen) ...[
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'The academic calendar lists important dates like the first day of classes, '
                                  'add/drop deadlines, holidays, and finals week.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tip:',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Always check the calendar before changing your schedule so you don’t '
                                  'miss refund deadlines or withdrawal dates.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _openLink(calendarUrl),
                                      icon: const FaIcon(
                                        FontAwesomeIcons.calendarDays,
                                        size: 18,
                                      ),
                                      label: const Text(
                                        'View Academic Calendar',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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

                        //When card is open
                        if (catalogOpen) ...[
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'The catalog lists degree requirements, course descriptions, and university policies.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'How to use it:',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Check your catalog year and review major or minor requirements, '
                                  'prerequisites, and course options.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _openLink(catalogUrl),
                                      icon: const FaIcon(
                                        FontAwesomeIcons.bookOpen,
                                        size: 18,
                                      ),
                                      label: const Text('Open Class Catalog'),
                                    ),
                                  ],
                                ),
                              ],
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
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Enrollment Services handles admissions, registration, financial aid, and student records.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'When to contact them:',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Use their site for questions about fees, transcripts, financial aid status, '
                                  'and enrollment changes.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _openLink(enrollmentUrl),
                                      icon: const FaIcon(
                                        FontAwesomeIcons.globe,
                                        size: 18,
                                      ),
                                      label: const Text(
                                        'Go to Enrollment Services',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'The Help Center supports technology issues like passwords, campus Wi-Fi, '
                                  'software access, and account problems.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'How to get support:',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'You can submit a ticket, browse help articles, or find contact info for live support on the website.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _openLink(helpcenterUrl),
                                      icon: const FaIcon(
                                        FontAwesomeIcons.circleQuestion,
                                        size: 18,
                                      ),
                                      label: const Text('Open Help Center'),
                                    ),
                                  ],
                                ),
                              ],
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
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'The Bob Murphy Access Center (BMAC) supports students with disabilities '
                                  'through accommodations, assistive technology, and advocacy.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Getting started:',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'New students usually complete an intake form and meet with an access coordinator. '
                                  'The website explains required documentation and how to schedule.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () =>
                                          _openLink(accessbilityUrl),
                                      icon: const FaIcon(
                                        FontAwesomeIcons.universalAccess,
                                        size: 18,
                                      ),
                                      label: const Text('Visit BMAC website'),
                                    ),
                                  ],
                                ),
                              ],
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

                        //When card is open
                        if (capsOpen) ...[
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Description
                                Text(
                                  'Counseling and Psychological Services (CAPS) provides short-term counseling, '
                                  'groups, crisis support, and workshops to support your mental health.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 8),

                                // Hours / appointments
                                Text(
                                  'Hours & appointments:',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Typical hours are Monday–Friday, 9 a.m.–5 p.m. '
                                  'Check the CAPS website for current hours and instructions on how to '
                                  'schedule an initial appointment or same-day support.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 12),

                                // Website button
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _openLink(capsUrl),
                                      icon: const FaIcon(
                                        FontAwesomeIcons.globe,
                                        size: 18,
                                      ),
                                      label: const Text('Open CAPS website'),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                // 🔹 Social media row
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () =>
                                          _openLink(capsInstagramUrl),
                                      icon: const FaIcon(
                                        FontAwesomeIcons.instagram,
                                        size: 26,
                                      ),
                                      tooltip: 'CAPS on Instagram',
                                    ),
                                    IconButton(
                                      onPressed: () =>
                                          _openLink(capsFacebookUrl),
                                      icon: const FaIcon(
                                        FontAwesomeIcons.facebook,
                                        size: 26,
                                      ),
                                      tooltip: 'CAPS on Facebook',
                                    ),
                                    IconButton(
                                      onPressed: () =>
                                          _openLink(capsLinktreeUrl),
                                      icon: const FaIcon(
                                        FontAwesomeIcons.link,
                                        size: 24,
                                      ),
                                      tooltip: 'CAPS Linktree (all links)',
                                    ),
                                  ],
                                ),
                              ],
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

                        //When card is open
                        if (groupcounselingOpen) ...[
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Group counseling offers a supportive space to connect with other students '
                                  'around shared experiences and topics.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'How groups work:',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Groups may require a brief screening with a CAPS counselor. '
                                  'The website lists current groups, times, and how to join.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () =>
                                          _openLink(groupcounselingUrl),
                                      icon: const FaIcon(
                                        FontAwesomeIcons.peopleGroup,
                                        size: 18,
                                      ),
                                      label: const Text(
                                        'View Group Counseling',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'This page lists crisis hotlines, after-hours counseling options, and emergency resources.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'If you are in crisis:',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Use these resources for urgent mental health support. '
                                  'For immediate, life-threatening emergencies, contact 911 or go to the nearest emergency room.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _openLink(crisisUrl),
                                      icon: const FaIcon(
                                        FontAwesomeIcons.phone,
                                        size: 18,
                                      ),
                                      label: const Text(
                                        'View Crisis Resources',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Basic Needs supports students experiencing food, housing, or financial insecurity '
                                  'through services like the Beach Pantry, emergency grants, and housing resources.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 8),

                                Text(
                                  'Hours & contact:',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Typical hours are Monday–Friday, 8 a.m.–5 p.m. '
                                  'Check the website for updated hours and details on services.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 12),

                                // Website button
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _openLink(needsUrl),
                                      icon: const FaIcon(
                                        FontAwesomeIcons.globe,
                                        size: 18,
                                      ),
                                      label: const Text(
                                        'Open Basic Needs site',
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                // 🔹 Social media row
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () =>
                                          _openLink(needsInstagramUrl),
                                      icon: const FaIcon(
                                        FontAwesomeIcons.instagram,
                                        size: 26,
                                      ),
                                      tooltip: 'Basic Needs on Instagram',
                                    ),
                                    IconButton(
                                      onPressed: () =>
                                          _openLink(needsLinktreeUrl),
                                      icon: const FaIcon(
                                        FontAwesomeIcons.link,
                                        size: 24,
                                      ),
                                      tooltip: 'Basic Needs Linktree',
                                    ),
                                  ],
                                ),
                              ],
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
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Beach Balance promotes wellness through services like nutrition education, '
                                  'stress management, and wellness coaching.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Hours & services:',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Program hours and offerings vary by semester. '
                                  'Check the site for current workshops, appointments, and events.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _openLink(balanceUrl),
                                      icon: const FaIcon(
                                        FontAwesomeIcons.handSparkles,
                                        size: 18,
                                      ),
                                      label: const Text('Open Beach Balance'),
                                    ),
                                  ],
                                ),
                              ],
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
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Beach Wellness connects students to health promotion programs, '
                                  'mental health resources, and campus wellness events.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Explore topics like:',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Sleep, stress, substance use, sexual health, and overall wellbeing.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _openLink(wellnessUrl),
                                      icon: const FaIcon(
                                        FontAwesomeIcons.heartPulse,
                                        size: 18,
                                      ),
                                      label: const Text('Visit Beach Wellness'),
                                    ),
                                  ],
                                ),
                              ],
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
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'The Student Recreation & Wellness Center (SRWC) offers fitness equipment, '
                                  'courts, a pool, fitness classes, and more.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 8),

                                Text(
                                  'Hours & info:',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Building hours, group fitness schedules, and membership information are posted on the SRWC website.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 12),

                                // Website button
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _openLink(centerUrl),
                                      icon: const FaIcon(
                                        FontAwesomeIcons.globe,
                                        size: 18,
                                      ),
                                      label: const Text('Open SRWC website'),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                // 🔹 Social media row
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () =>
                                          _openLink(centerInstagramUrl),
                                      icon: const FaIcon(
                                        FontAwesomeIcons.instagram,
                                        size: 26,
                                      ),
                                      tooltip: 'SRWC on Instagram',
                                    ),
                                  ],
                                ),
                              ],
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
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Rising Tides / Project OCEAN provides peer-led programs that promote mental health, '
                                  'connection, and suicide prevention.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 8),

                                Text(
                                  'How to get involved:',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Check the webpage and social media for current workshops, events, and ways to connect '
                                  'with peer educators.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 12),

                                // Website button
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _openLink(oceanUrl),
                                      icon: const FaIcon(
                                        FontAwesomeIcons.globe,
                                        size: 18,
                                      ),
                                      label: const Text(
                                        'Open Rising Tides page',
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                // 🔹 Social media row
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () =>
                                          _openLink(oceanInstagramUrl),
                                      icon: const FaIcon(
                                        FontAwesomeIcons.instagram,
                                        size: 26,
                                      ),
                                      tooltip: 'Project OCEAN on Instagram',
                                    ),
                                    IconButton(
                                      onPressed: () =>
                                          _openLink(oceanLinktreeUrl),
                                      icon: const FaIcon(
                                        FontAwesomeIcons.link,
                                        size: 24,
                                      ),
                                      tooltip: 'Project OCEAN Linktree',
                                    ),
                                  ],
                                ),
                              ],
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
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'The Career Development Center supports career exploration, resumes, '
                                  'interviews, and job or internship searches.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Events & services:',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Check for career fairs, employer info sessions, and workshops on the website.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _openLink(careerUrl),
                                      icon: const FaIcon(
                                        FontAwesomeIcons.briefcase,
                                        size: 18,
                                      ),
                                      label: const Text(
                                        'Open Career Center site',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                //Closes the card and adds the spacing
                if (showCareer) const SizedBox(height: 8),

                // -------------------- Clubs & Organizations -------------------------------------------
                if (showClubs)
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
                              clubsOpen = !clubsOpen;
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
                                  clubsOpen ? Icons.remove : Icons.add,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Clubs & Organizations',
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

                        // Expanded content
                        if (clubsOpen) ...[
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Description
                                Text(
                                  'Explore student clubs and organizations at CSULB to build community, '
                                  'develop leadership skills, and connect with people who share your interests.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 8),

                                Text(
                                  'How to get started:',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),

                                Text(
                                  'Use the Student Life & Development website to learn about involvement opportunities. '
                                  'Then browse BeachSync to find specific clubs and organizations to join.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 12),

                                // ASI Description
                                Text(
                                  'Associated Students, Inc. (ASI) is the student government and primary hub '
                                  'for campus involvement. Many clubs operate through ASI and use their resources '
                                  'for events, funding, and student engagement.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),

                                const SizedBox(height: 12),

                                // ASI Website Button
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _openLink(asiWebsiteUrl),
                                      icon: const FaIcon(
                                        FontAwesomeIcons.globe,
                                        size: 18,
                                      ),
                                      label: const Text('ASI Main Website'),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                // ASI Social Media Icons
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () =>
                                          _openLink(asiInstagramUrl),
                                      icon: const FaIcon(
                                        FontAwesomeIcons.instagram,
                                        size: 26,
                                      ),
                                      tooltip: 'ASI on Instagram',
                                    ),
                                    IconButton(
                                      onPressed: () =>
                                          _openLink(asiFacebookUrl),
                                      icon: const FaIcon(
                                        FontAwesomeIcons.facebook,
                                        size: 26,
                                      ),
                                      tooltip: 'ASI on Facebook',
                                    ),
                                    IconButton(
                                      onPressed: () => _openLink(asiTwitterUrl),
                                      icon: const FaIcon(
                                        FontAwesomeIcons.twitter,
                                        size: 26,
                                      ),
                                      tooltip: 'ASI on X / Twitter',
                                    ),
                                    IconButton(
                                      onPressed: () => _openLink(asiTikTokUrl),
                                      icon: const FaIcon(
                                        FontAwesomeIcons.tiktok,
                                        size: 26,
                                      ),
                                      tooltip: 'ASI on TikTok',
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 20),

                                // Buttons
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _openLink(clubsMainUrl),
                                      icon: const FaIcon(
                                        FontAwesomeIcons.globe,
                                        size: 18,
                                      ),
                                      label: const Text('Student Life Website'),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: () =>
                                          _openLink(clubsDirectoryUrl),
                                      icon: const FaIcon(
                                        FontAwesomeIcons.listUl,
                                        size: 18,
                                      ),
                                      label: const Text(
                                        'Find Clubs (BeachSync)',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                if (showClubs) const SizedBox(height: 8),

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
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'This page explains how to find and apply for internships related to your major or interests.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Getting started:',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'You can search postings, learn about academic credit, and see tips for strong applications.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _openLink(internshipUrl),
                                      icon: const FaIcon(
                                        FontAwesomeIcons.idBadge,
                                        size: 18,
                                      ),
                                      label: const Text('View Internship info'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                //Closes the card and adds the spacing
                if (showInternship) const SizedBox(height: 8),

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
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mentoring programs connect students with peers, staff, alumni, or professionals '
                                  'for guidance and support.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'How to join:',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'The website explains active mentoring programs, eligibility, and application steps.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _openLink(mentorUrl),
                                      icon: const FaIcon(
                                        FontAwesomeIcons.userGroup,
                                        size: 18,
                                      ),
                                      label: const Text('Open Mentoring info'),
                                    ),
                                  ],
                                ),
                              ],
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
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Student research opportunities let you work with faculty on projects, '
                                  'gain experience, and prepare for grad school or careers.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'How to get involved:',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'The site lists programs, funding opportunities, and ways to contact research mentors.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _openLink(researchUrl),
                                      icon: const FaIcon(
                                        FontAwesomeIcons.flask,
                                        size: 18,
                                      ),
                                      label: const Text(
                                        'View Research Opportunities',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Graduate Studies provides information about master’s and doctoral programs, '
                                  'admissions, and advising.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Next steps:',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Explore programs, check application deadlines, and find contacts for program advisors.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _openLink(graduateUrl),
                                      icon: const FaIcon(
                                        FontAwesomeIcons.graduationCap,
                                        size: 18,
                                      ),
                                      label: const Text(
                                        'Explore Graduate Programs',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
                    !showGraduate &&
                    !showClubs)
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
