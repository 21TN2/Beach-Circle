// import 'package:flutter/material.dart';
// import 'package:beach_circle_flutter/community_goods/dorm_life/models/dorm_event.dart';
// import 'package:beach_circle_flutter/community_goods/dorm_life/widgets/dorm_category_dot.dart';
// import 'package:beach_circle_flutter/community_goods/dorm_life/widgets/dorm_events.dart';
// // ── Sample data (no Firebase needed for preview) ─────────────────────────────

// final List<DormEvent> _sampleEvents = [
//   DormEvent(
//     id: '1',
//     title: 'LBSU vs Stanford\nRip the Roots',
//     location: 'Pyramid Lawn',
//     date: DateTime(2024, 10, 26),
//     startTime: const TimeOfDay(hour: 18, minute: 0),
//     endTime: const TimeOfDay(hour: 19, minute: 30),
//     description: "Join us as we come together to support CSULB Women's Volleyball Team!",
//     links: 'Flyer: https://www.instagram.com/p/DN1Wott5NSv/',
//     category: DormCategory.athletics,
//   ),
//   DormEvent(
//     id: '2',
//     title: 'General\nBody Meeting',
//     location: 'Los Cerritos Classroom',
//     date: DateTime(2024, 10, 26),
//     startTime: const TimeOfDay(hour: 19, minute: 0),
//     endTime: const TimeOfDay(hour: 20, minute: 0),
//     category: DormCategory.organization,
//   ),
//   DormEvent(
//     id: '3',
//     title: "Final's\nGoodie Bags",
//     location: 'Service Center Front Desk',
//     date: DateTime(2024, 10, 26),
//     startTime: const TimeOfDay(hour: 0, minute: 0),
//     isAllDay: true,
//     category: DormCategory.residential,
//   ),
// ];

// // ── Screen ────────────────────────────────────────────────────────────────────

// class DormHomePage extends StatefulWidget {
//   const DormHomePage({super.key});

//   @override
//   State<DormHomePage> createState() => _DormHomePageState();
// }

// class _DormHomePageState extends State<DormHomePage> {
//   DateTime _selectedDate = DateTime(2024, 10, 26);
//   DormCategory _selectedCategory = DormCategory.athletics;

//   final List<DateTime> _days = List.generate(
//     7,
//     (i) => DateTime(2024, 10, 24).add(Duration(days: i)),
//   );

//   static const _dayNames = [
//     'MON', 'TUES', 'WED', 'THURS', 'FRI', 'SAT', 'SUN'
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,

//       // ── Yellow top bar ──────────────────────────────────────────────────
//       appBar: AppBar(
//         backgroundColor: const Color(0xFFFFCC00),
//         elevation: 0,
//         leading: const Icon(Icons.arrow_back, color: Colors.black),
//         title: Container(
//           height: 36,
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: const Center(
//             child: Text(
//               'Dorm Life',
//               style: TextStyle(color: Colors.black54, fontSize: 16),
//             ),
//           ),
//         ),
//         actions: const [
//           Padding(
//             padding: EdgeInsets.only(right: 12),
//             child: Icon(Icons.chevron_right, color: Colors.blue),
//           ),
//         ],
//       ),

//       body: SingleChildScrollView(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [

//             // ── Interested banner ─────────────────────────────────────────
//             Align(
//               alignment: Alignment.topRight,
//               child: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
//                 decoration: const BoxDecoration(
//                   color: Color(0xFFE07B00),
//                   borderRadius: BorderRadius.only(
//                     bottomLeft: Radius.circular(12),
//                   ),
//                 ),
//                 child: const Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(Icons.star_border, color: Colors.white, size: 16),
//                     SizedBox(width: 6),
//                     Text(
//                       'Interested',
//                       style: TextStyle(color: Colors.white, fontSize: 13),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             // ── Date strip ────────────────────────────────────────────────
//             Container(
//               height: 90,
//               color: Colors.grey.shade100,
//               child: ListView.builder(
//                 scrollDirection: Axis.horizontal,
//                 padding: const EdgeInsets.symmetric(horizontal: 12),
//                 itemCount: _days.length,
//                 itemBuilder: (context, i) {
//                   final day = _days[i];
//                   final isSelected = day.day == _selectedDate.day;
//                   final cats = day.day == 26
//                       ? [
//                           DormCategory.athletics,
//                           DormCategory.organization,
//                           DormCategory.residential,
//                         ]
//                       : <DormCategory>[];

//                   return GestureDetector(
//                     onTap: () => setState(() => _selectedDate = day),
//                     child: AnimatedContainer(
//                       duration: const Duration(milliseconds: 200),
//                       width: 64,
//                       margin: const EdgeInsets.symmetric(
//                           vertical: 8, horizontal: 2),
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(12),
//                         border: isSelected
//                             ? Border.all(color: Colors.black87, width: 2)
//                             : null,
//                       ),
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text(
//                             _dayNames[day.weekday - 1],
//                             style: TextStyle(
//                               fontSize: 11,
//                               fontWeight: isSelected
//                                   ? FontWeight.bold
//                                   : FontWeight.normal,
//                               color: isSelected
//                                   ? Colors.black
//                                   : Colors.grey.shade600,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             '${day.day}',
//                             style: const TextStyle(
//                               fontSize: 20,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.black87,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           DormCategoryDotRow(categories: cats, dotSize: 9),
//                         ],
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),

//             const SizedBox(height: 8),

//             // ── Event cards ───────────────────────────────────────────────
//             ..._sampleEvents.map((event) => DormEvents(
//                 title: event.title,
//                 location: event.location,
//                 body: event.description,
//                 dateLabel: 'SUN, OCT 26',
//                 timeText: event.timeDisplay,
//                 isStarred: event.isInterested,
//                 color: event.category.color,
//             )),

//             const SizedBox(height: 24),

//             // ── Category dot selector preview ─────────────────────────────
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     '[ Category Selector Preview ]',
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: Colors.grey,
//                       fontStyle: FontStyle.italic,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Row(
//                     children: [
//                       const Text('Add Dorm Details  '),
//                       DormCategorySelector(
//                         selected: _selectedCategory,
//                         onChanged: (cat) =>
//                             setState(() => _selectedCategory = cat),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     'Selected: ${_selectedCategory.label}',
//                     style: const TextStyle(fontSize: 12, color: Colors.black54),
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 32),
//           ],
//         ),
//       ),
//     );
//   }
// }
