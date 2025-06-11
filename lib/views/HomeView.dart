import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:visit_1000_hills/theme_provider.dart';
import 'package:visit_1000_hills/views/ApartmentListView.dart';
import 'package:visit_1000_hills/views/HotelRoomListView.dart';
import 'package:visit_1000_hills/views/TicketListView.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'EventListPage.dart';
import 'HotelRoomDetailsView.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late PageController _pageController;
  Timer? _timer;
  bool loading = true;
  int page = 1;
  int lastPage = 1;

  String searchTerm = '';
  String capacityFilter = '';
  String statusFilter = '';
  List<dynamic> rooms = [];
  List<dynamic> filteredRooms = [];
  final String storageUrl = dotenv.env['BASE_URL_STORAGE'] ?? '';
  final String apiUrl = '${dotenv.env['API_URL'] ?? ''}/client/rooms';

  static Widget bannerItem(String text, Color color) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 8.0),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Center(
      child: Text(
        text,
        style: const TextStyle(fontSize: 24, color: Colors.white),
      ),
    ),
  );

  @override
  void initState() {
    super.initState();
    fetchRooms(page);
    _pageController = PageController(viewportFraction: 0.8);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> fetchRooms(int page) async {
    setState(() => loading = true);

    try {
      final response = await http.get(Uri.parse('$apiUrl?page=$page'));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          rooms = jsonData['data'];
          filteredRooms = jsonData['data'];
          this.page = jsonData['current_page'];
          lastPage = jsonData['last_page'];
        });
      } else {
        print("Failed to fetch rooms: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching rooms: $e");
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            height: MediaQuery.of(context).size.height * 0.31,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/background/img.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Scrollable content
          CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                expandedHeight: 80,
                floating: true,
                pinned: true,
                centerTitle: true,
                title: const Text(
                  'Visit 1000 Hills',
                  style: TextStyle(color: Colors.white),
                ),
                actions: [
                  Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: themeProvider.toggleTheme,
                    activeColor: Colors.white,
                  ),
                ],
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 30)),
              // Floating search box
              SliverPersistentHeader(
                pinned: true,
                floating: false,
                delegate: _SearchHeader(
                  theme: theme,
                  onSearchTap: () => showServiceSelector(context, theme),
                ),
              ),

              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white, // ✅ White background
                  child: const SizedBox(height: 30),
                ),
              ),

              // Choices
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white, // ✅ Set background color
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      choiceCard(Icons.train, 'Bus Tickets', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => TicketListView()),
                        );
                      }, theme),
                      choiceCard(Icons.hotel, 'Hotel Rooms', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HotelRoomListView(),
                          ),
                        );
                      }, theme),


                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white, // ✅ White background
                  child: const SizedBox(height: 30),
                ),
              ),

              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white, // ✅ Set background color
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      choiceCard(Icons.event, 'Event & Meeting', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EventListPage(),
                          ),
                        );
                      }, theme),
                      choiceCard(Icons.apartment, 'Apartments', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ApartmentListingPage(),
                          ),
                        );
                      }, theme),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white, // ✅ White background
                  child: const SizedBox(height: 30),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Featured Rooms",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              if (loading)
                const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (filteredRooms.isEmpty)
                const SliverToBoxAdapter(
                  child: Center(child: Text("No rooms found.")),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final room = filteredRooms[index];
                    final photoPath =
                        room['photos'].isNotEmpty
                            ? '$storageUrl/${room['photos'][0]['path']}'
                            : null;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => RoomDetailScreen(
                                  roomId: room['id'].toString(),
                                ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8,
                        ),
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    image: DecorationImage(
                                      fit: BoxFit.cover,
                                      image:
                                          photoPath != null
                                              ? NetworkImage(photoPath)
                                              : const AssetImage(
                                                    'assets/placeholder/placeholder.png',
                                                  )
                                                  as ImageProvider,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        room['name'],
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.indigo,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        room['description'] ?? '',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text('Price: \$${room['price']}'),
                                      Text(
                                        'Capacity: ${room['capacity']} people',
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Status: ${room['status'] ?? 'N/A'}',
                                        style: TextStyle(
                                          color:
                                              room['status'] == 'available'
                                                  ? Colors.green
                                                  : Colors.red,
                                        ),
                                      ),
                                      if (room['deleted_on'] != null)
                                        Text(
                                          'Deleted on: ${room['deleted_on']}',
                                          style: const TextStyle(
                                            color: Colors.red,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }, childCount: min(5, filteredRooms.length)),
                ),

              SliverToBoxAdapter(
                child: Container(
                  color:
                      Colors
                          .white, // ✅ White background for the offer section too
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      offerCard(
                        theme,
                        'Special Offer!',
                        'Get 10% off on your first hotel booking with us.',
                        'Claim Offer',
                        theme.primaryColor.withOpacity(0.1),
                        theme.primaryColor,
                      ),
                      const SizedBox(height: 24),
                      serviceTile(
                        title: 'Bus Tickets',
                        description:
                        'Book intercity and local bus tickets with ease.',
                        icon: Icons.train,
                        theme: theme,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => TicketListView()),
                          );
                        },
                      ),
                      serviceTile(
                        title: 'Hotel Rooms',
                        description: 'Find and book comfortable hotel stays.',
                        icon: Icons.hotel,
                        theme: theme,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => HotelRoomListView()),
                          );
                        },
                      ),
                      serviceTile(
                        title: 'Apartments',
                        description: 'Explore and rent affordable apartments.',
                        icon: Icons.apartment,
                        theme: theme,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ApartmentListingPage()),
                          );
                          // You can add apartment navigation here
                        },
                      ),
                      // Repeat as needed...
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void showServiceSelector(BuildContext context, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Column(
              children: [
                serviceTile(
                  title: 'Bus Tickets',
                  description:
                      'Book intercity and local bus tickets with ease.',
                  icon: Icons.train,
                  theme: theme,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => TicketListView()),
                    );
                  },
                ),
                serviceTile(
                  title: 'Hotel Rooms',
                  description: 'Find and book comfortable hotel stays.',
                  icon: Icons.hotel,
                  theme: theme,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => HotelRoomListView()),
                    );
                  },
                ),
                serviceTile(
                  title: 'Apartments',
                  description: 'Explore and rent affordable apartments.',
                  icon: Icons.apartment,
                  theme: theme,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ApartmentListingPage()),
                    );
                    // You can add apartment navigation here
                  },
                ),
                serviceTile(
                  title: 'Events And Meeting',
                  description: 'Explore and rent affordable Event Space.',
                  icon: Icons.event,
                  theme: theme,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => EventListPage()),
                    );
                    // You can add apartment navigation here
                  },
                ),
              ],
            ),
          ),
    );
  }

  Widget serviceTile({
    required String title,
    required String description,
    required IconData icon,
    required ThemeData theme,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Colors.blue[50],
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Icon(icon, color: Colors.blue.shade800),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade900,
          ),
        ),
        subtitle: Text(
          description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.blueGrey[800],
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 18,
          color: Colors.blueAccent,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget choiceCard(
    IconData icon,
    String label,
    VoidCallback onTap,
    ThemeData theme,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        height: 160,
        decoration: BoxDecoration(
          color: theme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color.fromARGB(66, 222, 213, 213),
              blurRadius: 10,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: theme.primaryColor),
            const SizedBox(height: 12),
            Text(
              label,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget offerCard(
    ThemeData theme,
    String title,
    String desc,
    String btnText,
    Color color,
    Color btnColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: btnColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: theme.textTheme.bodyMedium?.copyWith(color: btnColor),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: btnColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: Text(btnText),
          ),
        ],
      ),
    );
  }
}

class _SearchHeader extends SliverPersistentHeaderDelegate {
  final ThemeData theme;
  final VoidCallback onSearchTap;

  _SearchHeader({required this.theme, required this.onSearchTap});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.transparent,

      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue[50],
          border: Border.all(color: Colors.blue.shade700, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade800, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'What would you like to book?',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.blue.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              readOnly: true,
              onTap: onSearchTap,
              decoration: InputDecoration(
                hintText: 'Search for destinations, hotels, etc...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white70,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  double get maxExtent => 170;

  @override
  double get minExtent => 170;

  @override
  bool shouldRebuild(_SearchHeader oldDelegate) => false;
}
