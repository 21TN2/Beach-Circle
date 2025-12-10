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

  //This is the current text in the search query
  String _searchQuery = '';

  //Allows the url to open
  Future<void> _openLink(String url) async {

    //Turns string into url
    final uri = Uri.parse(url);

    //Opens the browser, if it fails an error message will pop up
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
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

 // ---------- SEARCH MATCHES -------------------------------------
    //Check which sub-resources match the query, this is to search the resources
    //Academic Section
    final showTutoring = _matchesQuery('Tutoring', tutoringUrl);
    final showAdvising = _matchesQuery('Advising', advisingUrl);
    final showCalendar =
        _matchesQuery('Academic Calendar', calendarUrl);

    // Auto-expand Resource Title when searching
    final showAcademicsExpanded = academicsExpanded || _searchQuery.isNotEmpty;
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
                            size: 24),
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
                                'Tutoring, advising, calendar, and more',
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
    //-------If resources don't show up in the search bar -------------------------------
                if (!showTutoring && !showAdvising && !showCalendar)
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
//==================================End of Aademic Section============================================================

//Paste Here For new sections 

// // ============================Template ===========================
    
//     //------------------Main Card------------------
//               Card(
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//                 elevation: 3,

//                 child: InkWell(
//                   borderRadius: BorderRadius.circular(16),
//                   onTap: () {
//                     setState(() {

//                       //Allows the Card to expand
//                       (Resource Name)Expanded = !(Resource name)Expanded;
//                     });
//                   },

//                   //Layering Card
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 16,
//                       vertical: 18,
//                     ),
//                     child: Row(
//                       children: [
//                         Container(
//                           padding: const EdgeInsets.all(10),
//                           decoration: BoxDecoration(
//                             color: Colors.yellow.shade100,
//                             shape: BoxShape.circle,
//                           ),
                          
//                           //Custom Icon
//                           child: const Icon(
//                             Icons.(Icon name), 
//                             color: Colors.(color),
//                             size: (num size)),
//                         ),
//                         const SizedBox(width: 16),

//                         //Academic Card Title
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 '(message)',
//                                 style: theme.textTheme.titleMedium?.copyWith(
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                               const SizedBox(height: 4),

//                               //Academic description
//                               Text(
//                                 '(message)',
//                                 style: theme.textTheme.bodyMedium?.copyWith(
//                                   color: theme.textTheme.bodySmall?.color,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),

//                         //Shows the arrow icon going up(opening) and going down(closing)
//                         Icon(
//                           show(Resource name)Expanded
//                               ? Icons.keyboard_arrow_up
//                               : Icons.keyboard_arrow_down,
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//         //------------------Academic card ends here-----------------------------
//               const SizedBox(height: 8),

//     //-------------------------------Sub Section Starting----------------------------------

//               //Shows the sub-section of Academics(Tutoring, Calendar, etc.)
//               if (show(Resource name)Expanded) ...[
//                 const SizedBox(height: 4),

//         // -------------------- TUTORING -------------------------------------------
//                 if (show(Resource name))

//                 //Card Details
//                   Card(
//                     elevation: 2,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),

//                     child: Column(
//                       children: [
//                         InkWell(
//                           borderRadius: BorderRadius.circular(12),
//                           onTap: () {
//                             setState(() {

//                               //Allows tutoring to be opened
//                               (Resource name)Open = !(Resouce name)Open;
//                             });
//                           },

//                           //Layering
//                           child: Padding(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 12,
//                               vertical: 14,
//                             ),
//                             child: Row(
//                               children: [
//                                 Icon(

//                                   //Add icon(Open) and subtract(Close)
//                                   (Resource name)Open ? Icons.remove : Icons.add,
//                                   size: 24,
//                                 ),
//                                 const SizedBox(width: 12),

//                                 //Title for sub card
//                                 const Expanded(
//                                   child: Text(
//                                     '(message)',
//                                     style: TextStyle(
//                                       fontSize: 18,
//                                       fontWeight: FontWeight.w500,
//                                     ),
//                                   ),
//                                 ),

//                                 //External link icon
//                                 const Icon(Icons.open_in_new, size: 18),
//                               ],
//                             ),
//                           ),
//                         ),

//                         //When Tutor card is open
//                         if ((Resource name)Open) ...[
//                           const Divider(height: 1),
//                           InkWell(

//                             //Shows the link and allows it to be opened 
//                             onTap: () => _openLink((Resource name)Url),

//                             //Layering
//                             child: const Padding(
//                               padding: EdgeInsets.all(12),
//                               child: Text(
//                                 (Resource name)Url,
//                                 style: TextStyle(
//                                   color: Colors.blue,
//                                   decoration: TextDecoration.underline,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ],
//                     ),
//                   ),

//                 //Closes the card and adds the spacing
//                 if (show(Resource name)) const SizedBox(height: 8),

//     //-------If resources don't show up in the search bar -------------------------------
//                 if (!show(Resource name) && !show(Resource name) && !show(Resource name))
//                   Padding(
//                     padding: const EdgeInsets.only(top: 12),
//                     child: Text(
//                       'No (Resource name) resources match your search.',
//                       style: theme.textTheme.bodyMedium?.copyWith(
//                         color: theme.colorScheme.onSurfaceVariant,
//                       ),
//                     ),
//                   ),
//               ],
// //==================================Template============================================================  
            ],
          ),
        ),
      ),
    );
  }
}