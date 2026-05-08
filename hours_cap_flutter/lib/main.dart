import 'package:flutter/material.dart';

void main() {
  runApp(const CSULBApp());
}

class CSULBApp extends StatelessWidget {
  const CSULBApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CSULB Campus',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.grey[200],
        primaryColor: const Color(0xFFFFC72C),
      ),
      home: const HoursCapacityPage(),
    );
  }
}

class Building {
  final String name;
  final IconData icon;
  final List<String> hours;
  final String capacity;
  final String location;
  final List<String> services;

  Building({
    required this.name,
    required this.icon,
    required this.hours,
    required this.capacity,
    required this.location,
    required this.services,
  });
}

class HoursCapacityPage extends StatelessWidget {
  const HoursCapacityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Building> buildings = [
      Building(
        name: "Academic Services",
        icon: Icons.school,
        hours: ["Mon–Fri 8AM-10PM"],
        capacity: "Office Based",
        location: "Upper Campus",
        services: ["Advising", "Enrollment Help"],
      ),
      Building(
        name: "Amazon @ The Beach",
        icon: Icons.local_shipping,
        hours: ["Mon-Fri 9AM-7PM \nSat-Sun 11AM-5PM"],
        capacity: "Retail Space",
        location: "Usu area",
        services: ["Package Pickup", "Returns"],
      ),
      Building(
        name: "Anna W. Ngai Alumni Center",
        icon: Icons.apartment,
        hours: ["Mon-Fri 8AM-5PM \nClosed Sat & Sun"],
        capacity: "Event Space",
        location: "West Campus",
        services: ["Events", "Alumni Services"],
      ),
      Building(
        name: "Art Store",
        icon: Icons.palette,
        hours: ["Mon-Thu 8AM–7PM", "Fri 8AM-4PM", "Closed Sat & Sun"],
        capacity: "Retail Space",
        location: "Art Building",
        services: ["Art Supplies", "Snacks", "Drinks", "Microwaves"],
      ),
      Building(
        name: "Beach Hut Convenience Store (AS)",
        icon: Icons.store,
        hours: ["Mon-Thu 7:30AM–8:30PM", "Fri 7:30AM-4PM", "Sat 10AM-4PM", "Closed Sun"],
        capacity: "Retail Space",
        location: "Academic Service Building",
        services: ["Snacks", "Drinks", "Microwaves"],
      ),
      Building(
        name: "Bookstore",
        icon: Icons.bookmark,
        hours: ["Mon–Thu 7:30AM-7PM", "Fri 7:30AM-4PM", "Sat 11AM-4PM", "Closed Sun"],
        capacity: "Retail",
        location: "Bookstore Area",
        services: ["Supplies", "Textbooks", "Printing", "Merch"],
      ),
      Building(
        name: "Bookstore Convenience Store",
        icon: Icons.shopping_bag,
        hours: ["Mon–Thu 7:30AM-7PM", "Fri 7:30AM-4PM", "Sat 11AM-4PM", "Closed Sun"],
        capacity: "Retail Space",
        location: "Bookstore Area",
        services: ["Supplies", "Snacks", "Drinks", "Microwaves"],
      ),
      Building(
        name: "Brotman Hall (BH)",
        icon: Icons.business,
        hours: ["Mon–Fri 9AM–5PM", "Closed Sat & Sun"],
        capacity: "Administrative Offices",
        location: "Central Campus",
        services: ["Admissions", "Financial Aid", "Registar", "Payroll",
        "Mental Health"],
      ),
      Building(
        name: "Carpenter Performing Arts Center",
        icon: Icons.theater_comedy,
        hours: ["Event Based"],
        capacity: "Performance Hall",
        location: "West Campus",
        services: ["Shows", "Events"],
      ),
      Building(
        name: "Child Development Center",
        icon: Icons.child_care,
        hours: ["Mon–Fri 8AM–5PM", "Closed Sat & Sun"],
        capacity: "Program Based",
        location: "Close by Parkside North",
        services: ["Child Care & Child Program"],
      ),
      Building(
        name: "CSULB Library",
        icon: Icons.account_balance,
        hours: [
          "Sunday 12PM–8PM",
          "Mon–Thurs 8AM–10PM",
          "Friday 8AM–5PM",
          "Saturday 10AM–4PM",
        ],
        capacity: "Varies by Floor",
        location: "Upper Campus",
        services: ["Study Cubicals", "Printing", "Research Help", 
        "Coffee Shop"],
      ),
      Building(
        name: "Horn Center",
        icon: Icons.computer,
        hours: ["Mon–Thu 8AM–8PM", "Fri 8AM-5PM", "Closed Sat & Sun"],
        capacity: "Study Hall",
        location: "Lower Campus",
        services: ["Tech Help Desk", "Printing", "Computer Lab"],
      ),
      Building(
        name: "Japanese Garden (JG)",
        icon: Icons.park,
        hours: ["Wed-Thu 10AM-5PM", "Fri 1PM-5PM", "Sat-Sun 9AM-1PM"],
        capacity: "Outdoor Garden",
        location: "Close by Parkside Dorms",
        services: ["Events", "Tours"],
      ),
      Building(
        name: "Kleefeld Contemporary Art Museum (KCAM)",
        icon: Icons.museum,
        hours: ["Mon-Wed 10AM-5PM", "Thu 10AM-7PM"],
        capacity: "Gallery Space",
        location: "Horn Center",
        services: ["Exhibitions"],
      ),
      Building(
        name: "LBS Financial Credit Union Pyramid",
        icon: Icons.sports_basketball,
        hours: ["Event Based"],
        capacity: "5,000 Seats",
        location: "Lower Campus",
        services: ["Sports Events", "Concerts"],
      ),
      Building(
        name: "Shakarian Student Success Center",
        icon: Icons.school,
        hours: ["Mon–Fri 8AM–10PM"],
        capacity: "Study Hall",
        location: "Central Campus",
        services: ["Tutoring", "Advising", "Study rooms"],
      ),
      Building(
        name: "Student Health Services (SHS)",
        icon: Icons.local_hospital,
        hours: ["Mon–Fri 8AM–5PM"],
        capacity: "Clinic",
        location: "West Campus",
        services: ["Medical Care", "Pharmacy"],
      ),
      Building(
        name: "Student Recreation & Wellness Center (SRWC)",
        icon: Icons.fitness_center,
        hours: ["Mon–Thu 6AM–11PM","Fri 6AM-9PM", "Sat-Sun 8AM–8PM"],
        capacity: "Gym Capacity",
        location: "East Campus",
        services: ["Gym", "Pool", "Events"],
      ),
      Building(
        name: "University Police Department",
        icon: Icons.local_police,
        hours: ["Mon-Fri 9AM-5PM", "Closed Sat & Sun"],
        capacity: "Emergency Services",
        location: "East Campus",
        services: ["Safety", "Emergency Reports"],
      ),
      Building(
        name: "University Theatre",
        icon: Icons.theater_comedy,
        hours: ["Event Based"],
        capacity: "Performance Hall",
        location: "Arts Area",
        services: ["Theatre Performances"],
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFFFC72C),
        leading: const Icon(Icons.arrow_back, color: Colors.black),
        title: const Text(
          "Hours & Capacity",
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: buildings.length,
        itemBuilder: (context, index) {
          return BuildingCard(building: buildings[index]);
        },
      ),
    );
  }
}

class BuildingCard extends StatelessWidget {
  final Building building;

  const BuildingCard({super.key, required this.building});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: Icon(building.icon, size: 28, color: Colors.black),
        title: Text(
          building.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        iconColor: Colors.black,
        collapsedIconColor: Colors.black,
        childrenPadding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          buildDropdownSection(
            title: "Hours",
            content: building.hours.join("\n"),
          ),
          buildDropdownSection(title: "Capacity", content: building.capacity),
          buildDropdownSection(title: "Location", content: building.location),
          buildDropdownSection(
            title: "Services",
            content: building.services.join("\n"),
          ),
        ],
      ),
    );
  }

  Widget buildDropdownSection({
    required String title,
    required String content,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isExpanded = false;

        return Theme(
          data: ThemeData().copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
            onExpansionChanged: (value) {
              setState(() {
                isExpanded = value;
              });
            },
            trailing: Icon(
              isExpanded ? Icons.remove : Icons.add,
              color: Colors.black,
            ),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(content),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
