import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'leave_request.dart';
import 'package:shimmer/shimmer.dart';
import '../../res/consts/app_colors.dart';

class LeaveOverview extends StatefulWidget {
  const LeaveOverview({super.key});

  @override
  _LeaveOverview createState() => _LeaveOverview();
}

class _LeaveOverview extends State<LeaveOverview>
    with SingleTickerProviderStateMixin {
  final _pageController = PageController(initialPage: 0);
  final _controller = NotchBottomBarController(index: -1);
  final List<Widget> bottomBarPages = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Map<String, dynamic>> newRequests = [];
  List<Map<String, dynamic>> requests = [];
  List<Map<String, dynamic>> requestsCount = [];
  List<Map<String, dynamic>> newApprovedRequests = [];
  int _currentPage = 0;
  final int _itemsPerPage = 5;
  int maxCount = 8;
  late int newRequestsCount = 0;
  late int newApprovedRequestsCount = 0;
  late String baseUrl = '';
  late Map<String, dynamic> arguments;
  bool isLoading = true;
  bool permissionLeaveTypeCheck = false;
  bool permissionLeaveAssignCheck = false;
  bool permissionLeaveRequestCheck = false;
  bool permissionLeaveOverviewCheck = false;
  bool permissionMyLeaveRequestCheck = false;
  bool permissionLeaveAllocationCheck = false;
  late String getToken = '';


  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    getAllLeaveRequest();
    getBaseUrl();
    fetchToken();
    prefetchData();
  }

  Future<void> fetchToken() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    setState(() {
      getToken = token ?? '';
    });
  }

  Future<void> checkPermissions() async {
    await permissionLeaveOverviewChecks();
    await permissionLeaveTypeChecks();
    await permissionLeaveRequestChecks();
    await permissionLeaveAssignChecks();
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

  Future<void> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    var typedServerUrl = prefs.getString("typed_url");
    setState(() {
      baseUrl = typedServerUrl ?? '';
    });
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
        'employee_id': responseData['id'],
        'employee_name': responseData['employee_first_name'] +
            ' ' +
            responseData['employee_last_name'],
        'badge_id': responseData['badge_id'],
        'email': responseData['email'],
        'phone': responseData['phone'],
        'date_of_birth': responseData['dob'],
        'gender': responseData['gender'],
        'address': responseData['address'],
        'country': responseData['country'],
        'state': responseData['state'],
        'city': responseData['city'],
        'qualification': responseData['qualification'],
        'experience': responseData['experience'],
        'marital_status': responseData['marital_status'],
        'children': responseData['children'],
        'emergency_contact': responseData['emergency_contact'],
        'emergency_contact_name': responseData['emergency_contact_name'],
        'employee_work_info_id': responseData['employee_work_info_id'],
        'employee_bank_details_id': responseData['employee_bank_details_id'],
        'employee_profile': responseData['employee_profile']
      };
    }
  }

  void _nextPage() {
    setState(() {
      if ((_currentPage + 1) * _itemsPerPage < requests.length) {
        _currentPage++;
      }
    });
  }

  void _previousPage() {
    setState(() {
      if (_currentPage > 0) {
        _currentPage--;
      }
    });
  }

  List<Map<String, dynamic>> getCurrentPageOfflineEmployees() {
    final int startIndex = _currentPage * _itemsPerPage;
    final int endIndex = startIndex + _itemsPerPage;
    if (startIndex >= requests.length) {
      return [];
    }
    return requests.sublist(
        startIndex, endIndex < requests.length ? endIndex : requests.length);
  }

  void handleConnectionError() {
    setState(() {
      isLoading = false;
    });
  }

  Future<void> getAllLeaveRequest() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var now = DateTime.now();
    var formattedDate =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    await fetchApprovedRequests(typedServerUrl!, token!, formattedDate, now);
    await fetchAllRequests(typedServerUrl, token);
  }

  Future<void> fetchApprovedRequests(String serverUrl, String token,
      String formattedDate, DateTime now) async {
    var uri = Uri.parse(
        '$serverUrl/api/leave/request/?from_date=$formattedDate&to_date=$formattedDate&status=approved');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      setState(() {
        var allRequests = List<Map<String, dynamic>>.from(
          jsonDecode(response.body)['results'],
        );
        requests = allRequests.where((request) {
          return true;
        }).toList();

        isLoading = false;
      });
    } else {
      handleConnectionError();
    }
  }

  Future<void> fetchAllRequests(String serverUrl, String token) async {
    var uri = Uri.parse('$serverUrl/api/leave/request');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });

    if (response.statusCode == 200) {
      setState(() {
        requestsCount = List<Map<String, dynamic>>.from(
          jsonDecode(response.body)['results'],
        );

        newRequests = requestsCount
            .where((request) => request['status'] == 'requested')
            .toList();

        newApprovedRequests = requestsCount
            .where((request) => request['status'] == 'approved')
            .toList();

        newRequestsCount = newRequests.length;
        newApprovedRequestsCount = newApprovedRequests.length;
        isLoading = false;
      });
    } else {
      handleConnectionError();
    }
  }

  List<Map<String, dynamic>> getCurrentPageRequests() {
    final int startIndex = _currentPage * _itemsPerPage;
    final int endIndex = startIndex + _itemsPerPage;
    if (startIndex >= requests.length) {
      return [];
    }
    return requests.sublist(
        startIndex, endIndex < requests.length ? endIndex : requests.length);
  }

  @override
  Widget build(BuildContext context) {
    final currentPageRequests = getCurrentPageRequests();

    return Scaffold(
      backgroundColor: Colors.white,
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: const Row(
          children: [
            Text('Leave Overview',
                style: TextStyle(
                  fontSize: 23.0,
                  fontWeight: FontWeight.bold,
                )),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: isLoading
            ? _buildShimmerEffect(context)
            : ListView(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LeaveRequest()),
                );
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= 600) {
                    return Row(
                      children: [
                        Expanded(
                          child: _buildGridItem(context, 'NEW\nREQUEST\n',
                              ' $newRequestsCount'),
                        ),
                        const SizedBox(width: 10.0),
                        Expanded(
                          child: _buildGridItem(
                              context,
                              'APPROVED\nREQUEST\n',
                              ' $newApprovedRequestsCount'),
                        ),
                      ],
                    );
                  } else {
                    return GridView.builder(
                      shrinkWrap: true,
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 5.0,
                        mainAxisSpacing: 5.0,
                      ),
                      itemCount: 2,
                      itemBuilder: (context, index) {
                        String headerText = index == 0
                            ? 'NEW\nREQUEST\n'
                            : 'APPROVED\nREQUEST\n';
                        String valueText = index == 0
                            ? ' $newRequestsCount'
                            : ' $newApprovedRequestsCount';
                        return _buildGridItem(
                            context, headerText, valueText);
                      },
                    );
                  }
                },
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.1),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 7,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal:
                        MediaQuery.of(context).size.width * 0.04),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'On Leave',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize:
                              MediaQuery.of(context).size.width *
                                  0.06,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                              top: MediaQuery.of(context).size.height *
                                  0.02),
                          child: Row(
                            children: [
                              Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 40,
                                  maxHeight: 40,
                                ),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.shade400
                                          .withOpacity(0.2),
                                      spreadRadius: 1,
                                      blurRadius: 1,
                                      offset: const Offset(0, 0),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.arrow_left),
                                  onPressed: _previousPage,
                                ),
                              ),
                              const SizedBox(width: 16.0),
                              Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 40,
                                  maxHeight: 40,
                                ),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.shade400
                                          .withOpacity(0.2),
                                      spreadRadius: 1,
                                      blurRadius: 1,
                                      offset: const Offset(0, 0),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.arrow_right),
                                  onPressed: _nextPage,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.35,
                    child: Column(
                      children: [
                        Expanded(
                          child: currentPageRequests.isEmpty
                              ? const Center(
                            child: Column(
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.calendar_month_outlined,
                                  color: Colors.black,
                                  size: 92,
                                ),
                                SizedBox(height: 20),
                                Text(
                                  'No Leave request for today',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          )
                              : ListView.builder(
                            shrinkWrap: true,
                            itemCount: currentPageRequests.length,
                            itemBuilder: (context, index) {
                              final record =
                              currentPageRequests[index];
                              final fullName = record['employee_id']
                              ['full_name'];
                              final badgeId =
                              record['employee_id']['badge_id'];
                              final image = record['employee_id']
                              ['employee_profile'];
                              final requestId = record['id'];

                              if (fullName != null) {
                                return buildLeaveTodayTile(
                                  context,
                                  fullName,
                                  image ?? "",
                                  baseUrl,
                                  getToken,
                                  badgeId ?? "",
                                  requestId,
                                );
                              } else {
                                return Container();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      drawer: Drawer(
        child: FutureBuilder<void>(
          future: checkPermissions(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListView(
                padding: const EdgeInsets.all(0),
                children: [
                  DrawerHeader(
                    decoration: const BoxDecoration(),
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: Image.asset(
                          'Assets/horilla-logo.png',
                        ),
                      ),
                    ),
                  ),
                  shimmerListTile(),
                  shimmerListTile(),
                  shimmerListTile(),
                  shimmerListTile(),
                  shimmerListTile(),
                  shimmerListTile(),
                ],
              );
            } else if (snapshot.hasError) {
              return const Center(child: Text('Error loading permissions.'));
            } else {
              return ListView(
                padding: const EdgeInsets.all(0),
                children: [
                  DrawerHeader(
                    decoration: const BoxDecoration(),
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: Image.asset(
                          'Assets/horilla-logo.png',
                        ),
                      ),
                    ),
                  ),
                  permissionLeaveOverviewCheck
                      ? ListTile(
                    title: const Text('Overview'),
                    onTap: () {
                      Navigator.pushNamed(context, '/leave_overview');
                    },
                  )
                      : const SizedBox.shrink(),

                  permissionMyLeaveRequestCheck
                      ? ListTile(
                    title: const Text('My Leave Request'),
                    onTap: () {
                      Navigator.pushNamed(context, '/my_leave_request');
                    },
                  )
                      : const SizedBox.shrink(),

                  permissionLeaveRequestCheck
                      ? ListTile(
                    title: const Text('Leave Request'),
                    onTap: () {
                      Navigator.pushNamed(context, '/leave_request');
                    },
                  )
                      : const SizedBox.shrink(),

                  permissionLeaveTypeCheck
                      ? ListTile(
                    title: const Text('Leave Type'),
                    onTap: () {
                      Navigator.pushNamed(context, '/leave_types');
                    },
                  )
                      : const SizedBox.shrink(),

                  permissionLeaveAllocationCheck
                      ? ListTile(
                    title: const Text('Leave Allocation Request'),
                    onTap: () {
                      Navigator.pushNamed(
                          context, '/leave_allocation_request');
                    },
                  )
                      : const SizedBox.shrink(),

                  permissionLeaveAssignCheck
                      ? ListTile(
                    title: const Text('All Assigned Leave'),
                    onTap: () {
                      Navigator.pushNamed(context, '/all_assigned_leave');
                    },
                  )
                      : const SizedBox.shrink(),

                ],
              );
            }
          },
        ),
      ),
      extendBody: true,
      bottomNavigationBar: (bottomBarPages.length <= maxCount)
          ? AnimatedNotchBottomBar(
        /// Provide NotchBottomBarController
        notchBottomBarController: _controller,
        color: Colors.red,
        showLabel: true,
        notchColor: Colors.red,
        kBottomRadius: 28.0,
        kIconSize: 24.0,

        /// restart app if you change removeMargins
        removeMargins: false,
        bottomBarWidth: MediaQuery.of(context).size.width * 1,
        durationInMilliSeconds: 300,
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
              Navigator.pushNamed(context, '/home');
              break;
            case 1:
              Navigator.pushNamed(context, '/employee_checkin_checkout');
              break;
            case 2:
              Navigator.pushNamed(context, '/employees_form',
                  arguments: arguments);
              break;
          }
        },
      )
          : null,
    );
  }
}

Widget shimmerListTile() {
  return Shimmer.fromColors(
    baseColor: grey300,
    highlightColor: grey100,
    child: ListTile(
      title: Container(
        width: double.infinity,
        height: 20.0,
        color: Colors.white,
      ),
    ),
  );
}

double responsiveFontSize(
    BuildContext context, double largeSize, double smallSize) {
  final double screenWidth = MediaQuery.of(context).size.width;
  if (screenWidth >= 600) {
    return largeSize;
  } else {
    return smallSize;
  }
}

Widget _buildGridItem(
    BuildContext context, String headerText, String valueText) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(15.0),
    ),
    child: Padding(
      padding: const EdgeInsets.only(top: 20.0, left: 20.0),
      child: RichText(
        textAlign: TextAlign.left,
        text: TextSpan(
          children: [
            TextSpan(
              text: '$headerText\n',
              style: TextStyle(
                fontSize: responsiveFontSize(context, 28.0, 20.0),
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            TextSpan(
              text: valueText,
              style: TextStyle(
                fontSize: responsiveFontSize(context, 36.0, 30.0),
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildShimmerEffect(BuildContext context) {
  return Shimmer.fromColors(
    baseColor: grey300,
    highlightColor: grey100,
    child: ListView(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 600) {
              return Row(
                children: [
                  Expanded(
                    child: _buildShimmerGridItem(context),
                  ),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: _buildShimmerGridItem(context),
                  ),
                ],
              );
            } else {
              return GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 5.0,
                  mainAxisSpacing: 5.0,
                ),
                itemCount: 2,
                itemBuilder: (context, index) {
                  return _buildShimmerGridItem(context);
                },
              );
            }
          },
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.1),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 2,
                blurRadius: 7,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.04),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildShimmerText(context),
                    Row(
                      children: [
                        _buildShimmerIconButton(context),
                        const SizedBox(width: 16.0),
                        _buildShimmerIconButton(context),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.35,
                child: _buildShimmerList(context),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildShimmerGridItem(BuildContext context) {
  return Container(
    margin: const EdgeInsets.all(5.0),
    decoration: BoxDecoration(
      color: Colors.grey[300],
      borderRadius: BorderRadius.circular(8.0),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Shimmer.fromColors(
          baseColor: grey300,
          highlightColor: grey100,
          child: Container(
            width: 100.0,
            height: 50.0,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 10.0),
        Shimmer.fromColors(
          baseColor: grey300,
          highlightColor: grey100,
          child: Container(
            width: 100.0,
            height: 20.0,
            color: Colors.grey,
          ),
        ),
      ],
    ),
  );
}

Widget _buildShimmerText(BuildContext context) {
  return Shimmer.fromColors(
    baseColor: grey300,
    highlightColor: grey100,
    child: Container(
      width: MediaQuery.of(context).size.width * 0.3,
      height: 20.0,
      color: Colors.grey,
    ),
  );
}

Widget _buildShimmerIconButton(BuildContext context) {
  return Shimmer.fromColors(
    baseColor: grey300,
    highlightColor: grey100,
    child: Container(
      width: 40.0,
      height: 40.0,
      decoration: const BoxDecoration(
        color: Colors.grey,
        shape: BoxShape.circle,
      ),
    ),
  );
}

Widget _buildShimmerList(BuildContext context) {
  return ListView.builder(
    itemCount: 5,
    itemBuilder: (context, index) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 5.0),
        child: Row(
          children: [
            _buildShimmerIconButton(context),
            const SizedBox(width: 10.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildShimmerText(context),
                  const SizedBox(height: 5.0),
                  _buildShimmerText(context),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget buildLeaveTodayTile(BuildContext context, String fullName, String image,
    String baseUrl,token, String badgeId, int requestId) {
  return GestureDetector(
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 1.0),
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Container(
            width: 40.0,
            height: 40.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey, width: 1.0),
            ),
            child: Stack(
              children: [
                if (image.isNotEmpty)
                  Positioned.fill(
                    child: ClipOval(
                      child: Image.network(
                        baseUrl + image,
                        headers: {
                          "Authorization": "Bearer $token",
                        },
                        fit: BoxFit.cover,
                        errorBuilder: (BuildContext context, Object exception,
                            StackTrace? stackTrace) {
                          return const Icon(Icons.person, color: Colors.grey);
                        },
                      ),
                    ),
                  ),
                if (image.isEmpty)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[400],
                      ),
                      child: const Icon(Icons.person),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: MediaQuery.of(context).size.width * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: const TextStyle(
                    fontSize: 16.0,
                    color: Colors.black,
                  ),
                ),
                Text(
                  badgeId,
                  style: const TextStyle(
                      fontSize: 12.0, fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
