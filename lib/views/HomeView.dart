import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:visit_1000_hills/theme_provider.dart';
import 'package:visit_1000_hills/views/ApartmentListView.dart';
import 'package:visit_1000_hills/views/HotelRoomListView.dart';
import 'package:visit_1000_hills/views/TicketListView.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  final List<Widget> carouselItems = [
    bannerItem('Discover Rwanda!', Colors.blueAccent),
    bannerItem('Book Hotels Easily', Colors.deepOrange),
    bannerItem('Explore Apartments', Colors.green),
  ];

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
    _pageController = PageController(viewportFraction: 0.8);
    _timer = Timer.periodic(const Duration(seconds: 10), (Timer timer) {
      if (_currentPage < carouselItems.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Visit 1000 Hills'),
            centerTitle: true,
            floating: true,
            pinned: true,
            snap: true,
            elevation: 0,
            actions: [
              Switch(
                value: themeProvider.isDarkMode,
                onChanged: themeProvider.toggleTheme,
                activeColor: Colors.white,
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: SizedBox(
              height: 200,
              child: PageView.builder(
                controller: _pageController,
                itemCount: carouselItems.length,
                itemBuilder: (context, index) => carouselItems[index],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          SliverPersistentHeader(
            pinned: true,
            delegate: _SearchHeader(theme: theme, onSearchTap: () => showServiceSelector(context, theme)),
          ),

          SliverToBoxAdapter(child: const SizedBox(height: 24)),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  choiceCard(Icons.train, 'Bus Tickets', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => TicketListView()));
                  }, theme),
                  choiceCard(Icons.hotel, 'Hotel Rooms', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => HotelRoomListView()));
                  }, theme),
                  choiceCard(Icons.apartment, 'Apartments', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ApartmentListingPage()));
                  }, theme),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          SliverToBoxAdapter(
            child: Padding(
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
                  offerCard(
                    theme,
                    'Limited Time Offer!',
                    'Book an apartment now and save 15%!',
                    'Claim Offer',
                    Colors.greenAccent.withOpacity(0.1),
                    Colors.greenAccent,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void showServiceSelector(BuildContext context, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Column(
          children: [
  serviceTile(
    title: 'Bus Tickets',
    description: 'Book intercity and local bus tickets with ease.',
    icon: Icons.train,
    theme: theme,
    onTap: () {
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(builder: (_) => TicketListView()));
    },
  ),
  serviceTile(
    title: 'Hotel Rooms',
    description: 'Find and book comfortable hotel stays.',
    icon: Icons.hotel,
    theme: theme,
    onTap: () {
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(builder: (_) => HotelRoomListView()));
    },
  ),
  serviceTile(
    title: 'Apartments',
    description: 'Explore and rent affordable apartments.',
    icon: Icons.apartment,
    theme: theme,
    onTap: () {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ApartmentListingPage()));
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
        style: theme.textTheme.bodySmall?.copyWith(color: Colors.blueGrey[800]),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.blueAccent),
      onTap: onTap,
    ),
  );
}


  Widget choiceCard(IconData icon, String label, VoidCallback onTap, ThemeData theme) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        height: 160,
        decoration: BoxDecoration(
          color: theme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Color.fromARGB(66, 222, 213, 213), blurRadius: 10, offset: Offset(0, 8)),
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

  Widget offerCard(ThemeData theme, String title, String desc, String btnText, Color color, Color btnColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: btnColor)),
          const SizedBox(height: 8),
          Text(desc, style: theme.textTheme.bodyMedium?.copyWith(color: btnColor)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: btnColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
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
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: theme.scaffoldBackgroundColor,
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
                      fontSize: 16,
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
