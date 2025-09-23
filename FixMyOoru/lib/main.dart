// lib/main.dart
import 'package:fixmyooru/services/user_session.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fixmyooru/firebase_options.dart';
import 'package:fixmyooru/screens/app_drawer.dart';
import 'package:fixmyooru/screens/report_issue_screen.dart';
import 'package:fixmyooru/screens/user_profile.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fixmyooru/screens/login_register_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- THEME DATA (No changes) ---
final _lightColorScheme = ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4), brightness: Brightness.light);
final _darkColorScheme = ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4), brightness: Brightness.dark);
ThemeData getAppTheme(ColorScheme colorScheme, BuildContext context) {
  final baseTheme = ThemeData(colorScheme: colorScheme, useMaterial3: true, textTheme: GoogleFonts.interTextTheme(ThemeData(brightness: colorScheme.brightness).textTheme).apply(bodyColor: colorScheme.onSurface, displayColor: colorScheme.onSurface,),);
  return baseTheme.copyWith(scaffoldBackgroundColor: colorScheme.background, cardTheme: const CardThemeData(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))), clipBehavior: Clip.antiAlias,), tabBarTheme: TabBarThemeData(labelColor: colorScheme.primary, unselectedLabelColor: colorScheme.onSurfaceVariant, indicatorSize: TabBarIndicatorSize.tab, dividerColor: Colors.transparent,), floatingActionButtonTheme: FloatingActionButtonThemeData(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary,), elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),),),);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bengaluru Civic Watch',
      theme: getAppTheme(_lightColorScheme, context),
      darkTheme: getAppTheme(_darkColorScheme, context),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});
  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  Future<void> _initializeSession() async {
    await UserSessionService().loadUserFromStorage();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MapScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  String? _darkMapStyle;
  bool _isLoading = true;
  bool _locationPermissionGranted = false;
  late AnimationController _panelAnimationController;
  MapType _currentMapType = MapType.normal;

  // NEW: State variable to hold the map markers
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _panelAnimationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    rootBundle.loadString('assets/map_style.json').then((string) => _darkMapStyle = string);
    _checkLocationPermission();

    // NEW: Start listening for live issue updates from Firestore
    _listenForLiveIssues();
  }

  // NEW: Method to listen for real-time data and create markers
  void _listenForLiveIssues() {
    FirebaseFirestore.instance
        .collection('issues')
        .where('status', whereIn: ['Approved', 'InProgress'])
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;

      final newMarkers = snapshot.docs.map((doc) {
        final data = doc.data();
        final geoPoint = data['location'] as GeoPoint;
        final position = LatLng(geoPoint.latitude, geoPoint.longitude);

        return Marker(
          markerId: MarkerId(doc.id),
          position: position,
          infoWindow: InfoWindow(
            title: data['issueType'] ?? 'Unknown Issue',
            snippet: 'Status: ${data['status']}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              data['status'] == 'InProgress'
                  ? BitmapDescriptor.hueOrange
                  : BitmapDescriptor.hueYellow
          ),
        );
      }).toSet();

      setState(() {
        _markers = newMarkers;
      });
    });
  }

  @override
  void dispose() {
    _panelAnimationController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_mapController != null) _updateMapStyleBasedOnTheme();
  }
  void _updateMapStyleBasedOnTheme() {
    if (Theme.of(context).brightness == Brightness.dark && _darkMapStyle != null) {
      _mapController?.setMapStyle(_darkMapStyle);
    } else {
      _mapController?.setMapStyle(null);
    }
  }
  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      if (mounted) setState(() { _locationPermissionGranted = true; });
    }
  }
  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      if (mounted) {
        setState(() { _locationPermissionGranted = true; });
        _goToCurrentUserLocation();
      }
    }
  }
  Future<void> _goToCurrentUserLocation() async {
    if (_mapController == null || !mounted || !_locationPermissionGranted) return;
    try {
      Position position = await Geolocator.getCurrentPosition();
      _mapController?.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: LatLng(position.latitude, position.longitude), zoom: 15.0)));
    } catch (e) {
      print("Error getting current location: $e");
    }
  }
  void _toggleMapType() {
    setState(() => _currentMapType = _currentMapType == MapType.normal ? MapType.satellite : MapType.normal);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          GoogleMap(
            // UPDATED: Add the markers to the map
            markers: _markers,
            initialCameraPosition: const CameraPosition(target: LatLng(12.9716, 77.5946), zoom: 12.0),
            mapType: _currentMapType,
            onCameraMoveStarted: () => _panelAnimationController.forward(),
            onCameraIdle: () => _panelAnimationController.reverse(),
            onMapCreated: (controller) {
              _mapController = controller;
              _updateMapStyleBasedOnTheme();
              if (_locationPermissionGranted) _goToCurrentUserLocation();
              if (mounted) setState(() { _isLoading = false; });
            },
            myLocationEnabled: _locationPermissionGranted,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          _buildTopCombinedPanel(),
          _buildBottomControlHub(),
          if (!_locationPermissionGranted && !_isLoading) _buildPermissionRequestView(),
          if (_isLoading) Container(color: Theme.of(context).colorScheme.background.withOpacity(0.5), child: const Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }

  // --- The rest of the _build methods are unchanged ---
  Widget _buildTopCombinedPanel() {
    final screenHeight = MediaQuery.of(context).size.height;
    final collapsedHeight = 77.0 + MediaQuery.of(context).padding.top;
    final expandedHeight = screenHeight * 0.40;
    return Positioned(
      top: 0, left: 0, right: 0,
      child: AnimatedBuilder(
        animation: _panelAnimationController,
        builder: (context, child) {
          final height = expandedHeight - (_panelAnimationController.value * (expandedHeight - collapsedHeight));
          return Container(height: height, decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)), boxShadow: [BoxShadow(blurRadius: 20.0, color: Colors.black.withOpacity(0.1))]), child: ClipRRect(borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)), child: child));
        },
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Builder(builder: (context) => IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(context).openDrawer())),
                    const SizedBox(width: 8),
                    Text('Bengaluru Civic Watch', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: FadeTransition(
                  opacity: Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: _panelAnimationController, curve: const Interval(0.0, 0.5))),
                  child: Column(
                    children: [
                      TabBar(indicator: BoxDecoration(borderRadius: BorderRadius.circular(50), color: Theme.of(context).colorScheme.primaryContainer), tabs: const [Tab(text: 'Trending'), Tab(text: 'Categories')]),
                      Expanded(
                        child: TabBarView(
                          physics: const NeverScrollableScrollPhysics(),
                          children: [_buildTrendingIssuesContent(), _buildCategoriesContent()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildBottomControlHub() {
    return Positioned(
      bottom: 30, left: 24, right: 24,
      child: Card(
        elevation: 8,
        shape: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Builder(builder: (context) => IconButton(icon: const Icon(Icons.menu), tooltip: 'Menu', onPressed: () => Scaffold.of(context).openDrawer())),
              IconButton(icon: const Icon(Icons.my_location), tooltip: 'My Location', onPressed: _goToCurrentUserLocation),
              FloatingActionButton(
                onPressed: () async {
                  final isUserLoggedIn = UserSessionService().currentUser.value != null;
                  if (isUserLoggedIn) {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportIssueScreen()));
                  } else {
                    final successfullyLoggedIn = await Navigator.push<bool>(context, MaterialPageRoute(builder: (context) => const LoginOrRegisterScreen()));
                    if (successfullyLoggedIn == true && mounted) {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportIssueScreen()));
                    }
                  }
                },
                elevation: 4.0,
                tooltip: 'Report an Issue',
                child: const Icon(Icons.add_location_alt_outlined),
              ),
              IconButton(icon: Icon(_currentMapType == MapType.satellite ? Icons.map : Icons.satellite_alt), tooltip: _currentMapType == MapType.satellite ? 'Normal View' : 'Satellite View', onPressed: _toggleMapType),
              IconButton(
                icon: const Icon(Icons.person_outline),
                tooltip: 'Profile',
                onPressed: () {
                  final isUserLoggedIn = UserSessionService().currentUser.value != null;
                  if (isUserLoggedIn) {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const UserProfile()));
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginOrRegisterScreen()));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildTrendingIssuesContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 12.0), child: Text("Highest Priority Issues", style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold))),
        Expanded(
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            children: [
              _buildTrendingIssueCard(context, 'Large Pothole', 'MG Road', Icons.add_road_outlined, Colors.orange),
              const SizedBox(width: 12),
              _buildTrendingIssueCard(context, 'Garbage Dump', 'Jayanagar', Icons.delete_outline, Colors.red),
              const SizedBox(width: 12),
              _buildTrendingIssueCard(context, 'Faulty Light', 'Koramangala', Icons.lightbulb_outline, Colors.yellow),
            ],
          ),
        ),
      ],
    );
  }
  Widget _buildCategoriesContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
      child: GridView.count(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        children: [
          _buildCategoryChip(context, 'Potholes', Icons.add_road),
          _buildCategoryChip(context, 'Garbage', Icons.delete),
          _buildCategoryChip(context, 'Streetlight', Icons.lightbulb),
          _buildCategoryChip(context, 'Water Log', Icons.water_drop),
        ],
      ),
    );
  }
  Widget _buildPermissionRequestView() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on_rounded, size: 60, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                Text('Unlock Bengaluru\'s Pulse', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text('Grant location access to see real-time civic issues.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 24),
                ElevatedButton.icon(onPressed: _requestLocationPermission, icon: const Icon(Icons.my_location), label: const Text('Enable Location Services')),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildTrendingIssueCard(BuildContext context, String title, String subtitle, IconData icon, Color iconColor) {
    return SizedBox(
      width: 150,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: iconColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: iconColor, size: 20)),
                const Spacer(),
                Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildCategoryChip(BuildContext context, String label, IconData icon) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondaryContainer, shape: BoxShape.circle), child: Icon(icon, size: 24, color: Theme.of(context).colorScheme.onSecondaryContainer)),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}