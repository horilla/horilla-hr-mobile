import 'dart:async';
// import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shimmer/shimmer.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../checkin_checkout/checkin_checkout_views/geofencing.dart';


class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late StreamSubscription subscription;
  var isDeviceConnected = false;
  final ScrollController _scrollController = ScrollController();
  final _pageController = PageController(initialPage: 0);
  final _controller = NotchBottomBarController(index: 0);
  late Map<String, dynamic> arguments = {};
  bool permissionCheck = false;
  bool isLoading = true;
  bool isFirstFetch = true;
  bool isAlertSet = false;
  bool permissionLeaveOverviewCheck = false;
  bool permissionLeaveTypeCheck = false;
  bool permissionGeoFencingMapViewCheck = false;
  bool permissionWardCheck = false;
  bool permissionLeaveAssignCheck = false;
  bool permissionLeaveRequestCheck = false;
  bool permissionMyLeaveRequestCheck = false;
  bool permissionLeaveAllocationCheck = false;
  int initialTabIndex = 0;
  int notificationsCount = 0;
  int maxCount = 5;
  String? duration;
  List<Map<String, dynamic>> notifications = [];
  Timer? _notificationTimer;
  Set<int> seenNotificationIds = {};
  int currentPage = 0;

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _notificationTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    permissionGeoFencingMapView();
    fetchNotifications();
    unreadNotificationsCount();
    getConnectivity();
    prefetchData();
    permissionChecks();
    fetchData();
    permissionLeaveOverviewChecks();
    permissionLeaveTypeChecks();
  }

  Future<void> permissionLeaveOverviewChecks() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/leave/check-perm/');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      permissionLeaveOverviewCheck = true;
      permissionMyLeaveRequestCheck = true;
      permissionLeaveAllocationCheck = true;
    } else {
      permissionMyLeaveRequestCheck = true;
      permissionLeaveAllocationCheck = true;
    }
  }

  Future<void> permissionLeaveTypeChecks() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/leave/check-type/');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      permissionLeaveTypeCheck = true;
      permissionMyLeaveRequestCheck = true;
      permissionLeaveAllocationCheck = true;
    } else {
      permissionMyLeaveRequestCheck = true;
      permissionLeaveAllocationCheck = true;
    }
  }

  Future<void> permissionGeoFencingMapView() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/geofencing/setup-check/');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      permissionGeoFencingMapViewCheck = true;
    } else {
      permissionGeoFencingMapViewCheck = false;
    }
  }

  Future<void> permissionLeaveRequestChecks() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/leave/check-request/');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      permissionLeaveRequestCheck = true;
      permissionMyLeaveRequestCheck = true;
      permissionLeaveAllocationCheck = true;
    } else {
      permissionMyLeaveRequestCheck = true;
      permissionLeaveAllocationCheck = true;
    }
  }

  Future<void> permissionLeaveAssignChecks() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/leave/check-assign/');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      permissionLeaveAssignCheck = true;
      permissionMyLeaveRequestCheck = true;
      permissionLeaveAllocationCheck = true;
    } else {
      permissionMyLeaveRequestCheck = true;
      permissionLeaveAllocationCheck = true;
    }
  }

  void getConnectivity() {
    // subscription = Connectivity().onConnectivityChanged.listen(
    //   (ConnectivityResult result) async {
    //     isDeviceConnected = await InternetConnectionChecker().hasConnection;
    //     if (!isDeviceConnected && !isAlertSet) {
    //       showSnackBar();
    //       setState(() => isAlertSet = true);
    //     }
    //   },
    // );
  }

  final List<Widget> bottomBarPages = [
    const Home(),
    const Overview(),
    const User(),
  ];

  void _scrollListener() {
    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange) {
      currentPage++;
      fetchNotifications();
    }
  }

  Future<void> fetchData() async {
    await permissionWardChecks();
    setState(() {});
  }

  void permissionChecks() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri =
        Uri.parse('$typedServerUrl/api/attendance/permission-check/attendance');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      permissionCheck = true;
    }
  }

  Future<void> permissionWardChecks() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/ward/check-ward/');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      setState(() {
        permissionWardCheck = true;
      });
    }
  }

  void prefetchData() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var employeeId = prefs.getInt("employee_id");
    var uri = Uri.parse('$typedServerUrl/api/employee/employees/$employeeId');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      arguments = {
        'employee_id': responseData['id'] ?? '',
        'employee_name': (responseData['employee_first_name'] ?? '') +
            ' ' +
            (responseData['employee_last_name'] ?? ''),
        'badge_id': responseData['badge_id'] ?? '',
        'email': responseData['email'] ?? '',
        'phone': responseData['phone'] ?? '',
        'date_of_birth': responseData['dob'] ?? '',
        'gender': responseData['gender'] ?? '',
        'address': responseData['address'] ?? '',
        'country': responseData['country'] ?? '',
        'state': responseData['state'] ?? '',
        'city': responseData['city'] ?? '',
        'qualification': responseData['qualification'] ?? '',
        'experience': responseData['experience'] ?? '',
        'marital_status': responseData['marital_status'] ?? '',
        'children': responseData['children'] ?? '',
        'emergency_contact': responseData['emergency_contact'] ?? '',
        'emergency_contact_name': responseData['emergency_contact_name'] ?? '',
        'employee_work_info_id': responseData['employee_work_info_id'] ?? '',
        'employee_bank_details_id':
            responseData['employee_bank_details_id'] ?? '',
        'employee_profile': responseData['employee_profile'] ?? '',
        'job_position_name': responseData['job_position_name'] ?? ''
      };
    }
  }

  Future<void> fetchNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");

    List<Map<String, dynamic>> allNotifications = [];
    int page = 1;

    while (true) {
      var uri = Uri.parse(
          '$typedServerUrl/api/notifications/notifications/list/unread?page=$page');

      var response = await http.get(uri, headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });

      if (response.statusCode == 200) {
        List<Map<String, dynamic>> fetchedNotifications =
            List<Map<String, dynamic>>.from(jsonDecode(response.body)['results']
                .where((notification) => notification['deleted'] == false)
                .toList());

        if (fetchedNotifications.isEmpty) {
          break;
        }

        allNotifications.addAll(fetchedNotifications);

        if (jsonDecode(response.body)['next'] == null) {
          break;
        }

        page++;
      } else {
        throw Exception('Failed to load notifications');
      }
    }

    Set<String> uniqueMapStrings = allNotifications
        .map((notification) => jsonEncode(notification))
        .toSet();

    notifications = uniqueMapStrings
        .map((jsonString) => jsonDecode(jsonString))
        .toList()
        .cast<Map<String, dynamic>>();

    notificationsCount = notifications.length;

    setState(() {
      isLoading = false;
    });
  }

  Future<void> unreadNotificationsCount() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse(
        '$typedServerUrl/api/notifications/notifications/list/unread');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });

    if (response.statusCode == 200) {
      setState(() {
        notificationsCount = jsonDecode(response.body)['count'];
        isLoading = false;
      });
    }
  }

  Future<void> markReadNotification(int notificationId) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse(
        '$typedServerUrl/api/notifications/notifications/$notificationId/');
    var response = await http.post(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      setState(() {
        notifications.removeWhere((item) => item['id'] == notificationId);
        unreadNotificationsCount();
        fetchNotifications();
      });
    }
  }

  Future<void> markAllReadNotification() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri =
        Uri.parse('$typedServerUrl/api/notifications/notifications/bulk-read/');
    var response = await http.post(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      setState(() {
        notifications.clear();
        unreadNotificationsCount();
        fetchNotifications();
      });
    }
  }

  Future<void> clearAllUnreadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse(
        '$typedServerUrl/api/notifications/notifications/bulk-delete-unread/');
    var response = await http.delete(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      setState(() {
        notifications.clear();
        unreadNotificationsCount();
        fetchNotifications();
      });
    }
  }

  Future<void> clearToken(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    String? typedServerUrl = prefs.getString("typed_url");
    await prefs.remove('token');
    Navigator.pushNamed(context, '/login', arguments: typedServerUrl);
  }

  void _showUnreadNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Stack(
              children: [
                AlertDialog(
                  backgroundColor: Colors.white,
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Notifications",
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.05,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                      ),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            onPressed: () async {
                              await markAllReadNotification();
                              Navigator.pop(context);
                              _showUnreadNotifications(context);
                            },
                            icon: Icon(Icons.done_all,
                                color: Colors.red,
                                size:
                                    MediaQuery.of(context).size.width * 0.0357),
                            label: Text(
                              'Mark as Read',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: MediaQuery.of(context).size.width *
                                      0.0368),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              await clearAllUnreadNotifications();
                              Navigator.pop(context);
                              _showUnreadNotifications(context);
                            },
                            icon: Icon(Icons.clear,
                                color: Colors.red,
                                size:
                                    MediaQuery.of(context).size.width * 0.0357),
                            label: Text(
                              'Clear all',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: MediaQuery.of(context).size.width *
                                      0.0368),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16.0),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: MediaQuery.of(context).size.height * 0.3,
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.8,
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal:
                                  MediaQuery.of(context).size.width * 0.0357),
                          child: Center(
                            child: isLoading
                                ? Shimmer.fromColors(
                                    baseColor: Colors.grey[300]!,
                                    highlightColor: Colors.grey[100]!,
                                    child: ListView.builder(
                                      itemCount: 3,
                                      itemBuilder: (context, index) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8.0),
                                        child: Container(
                                          width: double.infinity,
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.0616,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  )
                                : notifications.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.notifications,
                                              color: Colors.black,
                                              size: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.2054,
                                            ),
                                            SizedBox(
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    0.0205),
                                            Text(
                                              "There are no notification records to display",
                                              style: TextStyle(
                                                fontSize: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.0268,
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : Column(
                                        children: [
                                          Expanded(
                                            child: ListView.builder(
                                              itemCount: notifications.length,
                                              itemBuilder: (context, index) {
                                                final record =
                                                    notifications[index];
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.all(4.0),
                                                  child: Column(
                                                    children: [
                                                      if (record['verb'] !=
                                                          null)
                                                        buildListItem(context,
                                                            record, index),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                          ),
                        ),
                      )
                    ],
                  ),
                  actions: <Widget>[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/notifications_list');
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              horizontal:
                                  MediaQuery.of(context).size.width * 0.0134,
                              vertical:
                                  MediaQuery.of(context).size.width * 0.0134),
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'View all notifications',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.0335),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget buildListItem(
      BuildContext context, Map<String, dynamic> record, int index) {
    final timestamp = DateTime.parse(record['timestamp']);
    final timeAgo = timeago.format(timestamp);
    final user = arguments['employee_name'];
    return Padding(
      padding: const EdgeInsets.all(0),
      child: GestureDetector(
        onTap: () async {
          setState(() {});
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red.shade100),
            borderRadius: BorderRadius.circular(8.0),
            color: Colors.red.shade100,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
                vertical: MediaQuery.of(context).size.height * 0.0082),
            child: Container(
              color: Colors.red.shade100,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, top: 6.0),
                    child: Container(
                      margin: EdgeInsets.only(
                          right: MediaQuery.of(context).size.width * 0.0357),
                      width: MediaQuery.of(context).size.width * 0.0223,
                      height: MediaQuery.of(context).size.width * 0.0223,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red.shade500,
                        border: Border.all(
                            color: Colors.grey,
                            width: MediaQuery.of(context).size.width * 0.0022),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record['verb'],
                          style: TextStyle(
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.0313,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          '$timeAgo by User $user',
                          style: TextStyle(
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.0268),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GestureDetector(
                      onTap: () async {
                        var notificationId = record['id'];
                        await markReadNotification(notificationId);
                        Navigator.pop(context);
                        _showUnreadNotifications(context);
                      },
                      child: Icon(
                        Icons.check,
                        color: Colors.red.shade500,
                        size: 20.0,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: ListTile(
            leading: Icon(icon, color: Colors.blue, size: 28),
            title: Text(title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              subtitle,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            trailing: const Icon(Icons.keyboard_arrow_right),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: Colors.white,
        title: const Text(
          'Modules',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          Visibility(
            visible: permissionGeoFencingMapViewCheck,
            child: IconButton(
              icon: const Icon(
                Icons.location_on,
                color: Colors.black,
              ),
              onPressed: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MapScreen(),
                  ),
                );
              },
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications,
                  color: Colors.black,
                ),
                onPressed: () {
                  markAllReadNotification();
                  Navigator.pushNamed(context, '/notifications_list');
                  setState(() {
                    fetchNotifications();
                    unreadNotificationsCount();
                  });
                },
              ),
              if (notificationsCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.012,
                      vertical: MediaQuery.of(context).size.width * 0.004,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: BoxConstraints(
                      minWidth: MediaQuery.of(context).size.width * 0.032,
                      minHeight: MediaQuery.of(context).size.height * 0.016,
                    ),
                    child: Center(
                      child: Text(
                        '$notificationsCount',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: MediaQuery.of(context).size.width * 0.018,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(
              Icons.logout,
              color: Colors.black,
            ),
            onPressed: () async {
              await clearToken(context);
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const SizedBox(height: 30),

            // Optional Welcome Message
            Text(
              'Welcome back!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),

            ),
            const SizedBox(height: 10),
            Text(
              'Manage your team and tasks from here.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),

            ),
            const SizedBox(height: 30),

            // Employees Card
            _buildDashboardCard(
              icon: Icons.people,
              title: 'Employees',
              subtitle: 'View and manage all your employees.',
              onTap: () {
                Navigator.pushNamed(context, '/employees_list',
                    arguments: permissionCheck);
              },
            ),

            // Attendance Card
            _buildDashboardCard(
              icon: Icons.checklist_rtl,
              title: 'Attendances',
              subtitle: 'Record and view employee attendance.',
              onTap: () {
                if (permissionCheck) {
                  Navigator.pushNamed(context, '/attendance_overview',
                      arguments: permissionCheck);
                } else {
                  Navigator.pushNamed(context, '/employee_hour_account',
                      arguments: permissionCheck);
                }
              },
            ),

            // Leaves Card
            _buildDashboardCard(
              icon: Icons.calendar_month_outlined,
              title: 'Leaves',
              subtitle: 'Record and view leave information.',
              onTap: () {
                if (permissionLeaveOverviewCheck) {
                  Navigator.pushNamed(context, '/leave_overview');
                } else {
                  Navigator.pushNamed(context, '/my_leave_request');
                }
              },
            ),
          ],
        ),
      ),
      extendBody: true,
      bottomNavigationBar: (bottomBarPages.length <= maxCount)
          ? AnimatedNotchBottomBar(
              notchBottomBarController: _controller,
              color: Colors.red,
              showLabel: true,
              notchColor: Colors.red,
              kBottomRadius: 28.0,
              kIconSize: 24.0,
              removeMargins: false,
              bottomBarWidth: MediaQuery.of(context).size.width * 1,
              durationInMilliSeconds: 500,
              bottomBarItems: const [
                BottomBarItem(
                  inActiveItem: Icon(
                    Icons.home_filled,
                    color: Colors.white,
                  ),
                  activeItem: Icon(
                    Icons.home_filled,
                    color: Colors.white,
                  ),
                ),
                BottomBarItem(
                  inActiveItem: Icon(
                    Icons.update_outlined,
                    color: Colors.white,
                  ),
                  activeItem: Icon(
                    Icons.update_outlined,
                    color: Colors.white,
                  ),
                ),
                BottomBarItem(
                  inActiveItem: Icon(
                    Icons.person,
                    color: Colors.white,
                  ),
                  activeItem: Icon(
                    Icons.person,
                    color: Colors.white,
                  ),
                ),
              ],
              onTap: (index) async {
                switch (index) {
                  case 0:
                    Future.delayed(const Duration(milliseconds: 1000), () {
                      Navigator.pushNamed(context, '/home');
                    });
                    break;
                  case 1:
                    Future.delayed(const Duration(milliseconds: 1000), () {
                      Navigator.pushNamed(
                          context, '/employee_checkin_checkout');
                    });
                    break;
                  case 2:
                    Future.delayed(const Duration(milliseconds: 1000), () {
                      Navigator.pushNamed(context, '/employees_form',
                          arguments: arguments);
                    });
                    break;
                }
              },
            )
          : null,
    );
  }

  void showSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: const Text('Please check your internet connectivity',
            style: TextStyle(color: Colors.white)),
        action: SnackBarAction(
          backgroundColor: Colors.red,
          label: 'close',
          textColor: Colors.white,
          onPressed: () async {
            setState(() => isAlertSet = false);
            isDeviceConnected = await InternetConnectionChecker().hasConnection;
            if (!isDeviceConnected && !isAlertSet) {
              showSnackBar();
              setState(() => isAlertSet = true);
            }
          },
        ),
        duration: const Duration(hours: 1),
      ),
    );
  }
}

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushNamed(context, '/home');
    });
    return Container(
      color: Colors.white,
      child: const Center(child: Text('Page 1')),
    );
  }
}

class Overview extends StatelessWidget {
  const Overview({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.white, child: const Center(child: Text('Page 2')));
  }
}

class User extends StatelessWidget {
  const User({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushNamed(context, '/user');
    });
    return Container(
      color: Colors.white,
      child: const Center(child: Text('Page 1')),
    );
  }
}
