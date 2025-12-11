import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:shimmer/shimmer.dart';
import 'package:html/parser.dart' as html_parser;
import '../res/consts/app_colors.dart';

class AttendanceOverview extends StatefulWidget {
  const AttendanceOverview({super.key});

  @override
  _AttendanceOverviewState createState() => _AttendanceOverviewState();
}

class _AttendanceOverviewState extends State<AttendanceOverview>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final _controller = NotchBottomBarController(index: -1);
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late String baseUrl = '';
  late Map<String, dynamic> arguments;
  late TabController _tabController;
  late String todayAttendance = '0';
  late String offlineEmpCount = '0';
  TextEditingController bodyController = TextEditingController();
  List<Map<String, dynamic>> requestsOfflineEmployees = [];
  List<Map<String, dynamic>> requestsOvertimeValidate = [];
  List<Map<String, dynamic>> requestsNonValidAttendance = [];
  List<Map<String, dynamic>> templateList = [];
  List<String> templateItems = [];
  String? selectedTemplate;
  String? bodyContent;
  String? nextPageUrl;
  int overtimeValidate = 0;
  int nonValidated = 0;
  int _currentPage = 0;
  final int _itemsPerPage = 5;
  final List<Widget> bottomBarPages = [];
  int maxCount = 5;
  int page = 1;
  int currentPage = 1;
  bool permissionCheck = false;
  bool isLoading = true;
  bool _isShimmerVisible = true;
  bool permissionOverview = true;
  bool permissionAttendance = false;
  bool permissionAttendanceRequest = false;
  bool permissionHourAccount = false;

  bool _drawerPermissionOverview = false;
  bool _drawerPermissionAttendance = false;
  bool _drawerPermissionAttendanceRequest = false;
  bool _drawerPermissionHourAccount = false;
  bool _isPermissionCheckComplete = false;
  late String getToken = '';

  @override
  void initState() {
    super.initState();
    bodyController.text = bodyContent ?? '';
    prefetchData();
    _scrollController.addListener(_scrollListener);
    _tabController = TabController(length: 2, vsync: this);
    getAllOfflineEmployees(1);
    getTodayAttendance();
    getOfflineEmployeeCount();
    getAllOvertimeValidateEmployees();
    getAllNonValidatedAttendance();
    getBaseUrl();
    _simulateLoading();
    loadPermissionsFromStorage();
    fetchToken();
  }

  Future loadPermissionsFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _drawerPermissionOverview = prefs.getBool("perm_overview") ?? false;
      _drawerPermissionAttendance = prefs.getBool("perm_attendance") ?? false;
      _drawerPermissionAttendanceRequest =
          prefs.getBool("perm_attendance_request") ?? false;
      _drawerPermissionHourAccount =
          prefs.getBool("perm_hour_account") ?? false;
      _isPermissionCheckComplete = true;
    });
  }

  Future<void> _simulateLoading() async {
    await Future.delayed(const Duration(seconds: 10));
    setState(() {});
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();

    bodyController.dispose();

    super.dispose();
  }

  Future<void> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    var typedServerUrl = prefs.getString("typed_url");
    setState(() {
      baseUrl = typedServerUrl ?? '';
    });
  }

  Future<void> permissionChecks() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri =
        Uri.parse('$typedServerUrl/api/attendance/permission-check/attendance');

    try {
      var response = await http.get(uri, headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });

      if (response.statusCode == 200) {
        setState(() {
          _drawerPermissionOverview = true;
          _drawerPermissionAttendance = true;
          _drawerPermissionAttendanceRequest = true;
          _drawerPermissionHourAccount = true;
        });
      } else {
        setState(() {
          _drawerPermissionAttendanceRequest = true;
          _drawerPermissionHourAccount = true;
        });
      }
    } catch (e) {
      print('Error checking permissions: $e');
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

  Future<void> fetchToken() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    setState(() {
      getToken = token ?? '';
    });
  }

  Future<void> getAllOfflineEmployees(int page) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse(
        '$typedServerUrl/api/attendance/offline-employees/list/?page=$page');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      setState(() {
        if (data['results'] is List) {
          List<dynamic> results = data['results'];
          List<Map<String, dynamic>> offlineEmployees = [];
          for (var result in results) {
            if (result is Map<String, dynamic>) {
              offlineEmployees.add(result);
            }
          }
          setState(() {
            requestsOfflineEmployees.addAll(offlineEmployees);
            _isShimmerVisible = false;
          });
        }
        nextPageUrl = data['next'];
      });
    }
  }

  Future<void> getTodayAttendance() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/attendance/today-attendance/');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      setState(() {
        todayAttendance =
            jsonDecode(response.body)['marked_attendances_ratio'].toString();
      });
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> getOfflineEmployeeCount() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri =
        Uri.parse('$typedServerUrl/api/attendance/offline-employees/count/');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      setState(() {
        offlineEmpCount = jsonDecode(response.body)['count'].toString();
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> getCurrentPageOfflineEmployees() {
    final int startIndex = _currentPage * _itemsPerPage;
    final int endIndex = startIndex + _itemsPerPage;
    if (startIndex >= requestsOfflineEmployees.length) {
      return [];
    }
    return requestsOfflineEmployees.sublist(
      startIndex,
      endIndex < requestsOfflineEmployees.length
          ? endIndex
          : requestsOfflineEmployees.length,
    );
  }

  void _previousPage() {
    setState(() {
      if (_currentPage > 0) {
        _currentPage--;
      }
    });
  }

  void _nextPage() {
    setState(() {
      if ((_currentPage + 1) * _itemsPerPage <
          requestsOfflineEmployees.length) {
        _currentPage++;
      }
    });
  }

  void _scrollListener() {
    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange) {
      currentPage++;
      getAllOvertimeValidateEmployees();
      getAllNonValidatedAttendance();
    }
  }

  Future<void> getAllOvertimeValidateEmployees() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse(
        '$typedServerUrl/api/attendance/attendance/list/ot?page=$currentPage');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      setState(() {
        requestsOvertimeValidate.addAll(
          List<Map<String, dynamic>>.from(
            jsonDecode(response.body)['results'],
          ),
        );
        overtimeValidate = jsonDecode(response.body)['count'];
      });
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> getAllNonValidatedAttendance() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse(
        '$typedServerUrl/api/attendance/attendance/list/non-validated?page=$currentPage');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      setState(() {
        requestsNonValidAttendance.addAll(
          List<Map<String, dynamic>>.from(
            jsonDecode(response.body)['results'],
          ),
        );
        nonValidated = jsonDecode(response.body)['count'];
      });
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      key: _scaffoldKey,
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: const Text(
          'Attendance Overview',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _isShimmerVisible
              ? _buildLoadingWidget()
              : _buildAttendanceOverview()),
      drawer: Drawer(
        child: ListView(
          padding: const EdgeInsets.all(0),
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(),
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: Image.asset('Assets/horilla-logo.png'),
                ),
              ),
            ),
            _isPermissionCheckComplete
                ? Column(
                    children: [
                      _drawerPermissionOverview
                          ? ListTile(
                              title: const Text('Overview'),
                              onTap: () {
                                Navigator.pushNamed(
                                    context, '/attendance_overview');
                              },
                            )
                          : const SizedBox.shrink(),
                      ListTile(
                        title: const Text('Attendance'),
                        onTap: () {
                          Navigator.pushNamed(
                              context, '/attendance_attendance');
                        },
                      ),
                      ListTile(
                        title: const Text('Attendance Request'),
                        onTap: () {
                          Navigator.pushNamed(context, '/attendance_request');
                        },
                      ),
                      ListTile(
                        title: const Text('Hour Account'),
                        onTap: () {
                          Navigator.pushNamed(
                              context, '/employee_hour_account');
                        },
                      ),
                    ],
                  )
                : Column(
                    children: [
                      shimmerListTile(),
                      shimmerListTile(),
                      shimmerListTile(),
                      shimmerListTile(),
                    ],
                  ),
          ],
        ),
      ),
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

  Widget _buildLoadingWidget() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double fontSize = screenWidth * 0.04;
    final double padding = screenWidth * 0.02;

    return Padding(
      padding: EdgeInsets.all(padding),
      child: ListView(
        children: [
          Shimmer.fromColors(
            baseColor: grey300,
            highlightColor: grey100,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.15,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 5,
                    mainAxisSpacing: 5,
                    childAspectRatio: 2,
                  ),
                  itemCount: 2,
                  itemBuilder: (context, index) {
                    String text = index == 0
                        ? '\nTODAY\'S\n ATTENDANCE\n$todayAttendance %'
                        : '\nOFFLINE\nEMPLOYEES\n$offlineEmpCount';
                    return Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        border: Border.all(color: Colors.grey[50]!),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Center(
                        child: Text(
                          text,
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.transparent,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Shimmer.fromColors(
            baseColor: grey300,
            highlightColor: grey100,
            child: Container(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[50]!),
                  borderRadius: BorderRadius.circular(8.0),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade400.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                height: screenHeight * 0.3,
              ),
            ),
          ),
          Container(
            color: Colors.white,
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.red,
                  labelColor: Colors.red,
                  unselectedLabelColor: Colors.grey,
                  isScrollable: true,
                  labelStyle: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: fontSize * 1.2),
                  tabs: [
                    Tab(text: 'Overtime Validate ($overtimeValidate)'),
                    Tab(text: 'Non Validated ($nonValidated)'),
                  ],
                ),
                SizedBox(
                  height: screenHeight * 0.5,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(padding),
                        child: ListView.builder(
                          itemCount: 3,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Shimmer.fromColors(
                                baseColor: grey300,
                                highlightColor: grey100,
                                child: Container(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border:
                                          Border.all(color: Colors.grey[50]!),
                                      borderRadius: BorderRadius.circular(8.0),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.shade400
                                              .withOpacity(0.3),
                                          spreadRadius: 2,
                                          blurRadius: 5,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Card(
                                      shape: RoundedRectangleBorder(
                                        side: const BorderSide(
                                            color: Colors.white, width: 0.0),
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                      ),
                                      color: Colors.white,
                                      elevation: 0.1,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Row(
                                              children: [
                                                SizedBox(
                                                  width: 40.0,
                                                  height: 40.0,
                                                ),
                                              ],
                                            ),
                                            SizedBox(
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    0.005),
                                            const SizedBox(height: 10),
                                            Container(
                                              height: 20.0,
                                            ),
                                            const SizedBox(height: 10),
                                            const SizedBox(
                                              height: 20.0,
                                              width: 80.0,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
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
    );
  }

  Widget _buildAttendanceOverview() {
    final double deviceWidth = MediaQuery.of(context).size.width;
    return Stack(
      children: [
        ListView(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.15,
              child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 5.0,
                      mainAxisSpacing: 5.0,
                      childAspectRatio: 2,
                    ),
                    itemCount: 2,
                    itemBuilder: (context, index) {
                      String headerText = index == 0
                          ? 'TODAY\'S\nATTENDANCE\n'
                          : 'OFFLINE\nEMPLOYEES\n';
                      String valueText = index == 0
                          ? ' $todayAttendance'
                          : ' $offlineEmpCount';
                      return _buildGridItem(context, headerText, valueText);
                    },
                  )),
            ),
            Container(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[50]!),
                  borderRadius: BorderRadius.circular(8.0),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade400.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: deviceWidth * 0.04),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Offline Employees',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: deviceWidth * 0.06,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(
                                top: MediaQuery.of(context).size.height * 0.02),
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
                          )
                        ],
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.3,
                      child: Column(
                        children: [
                          Expanded(
                            child: getCurrentPageOfflineEmployees().isEmpty
                                ? const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.person_off,
                                          color: Colors.black,
                                          size: 92,
                                        ),
                                        SizedBox(height: 20),
                                        Text(
                                          'There are no offline employees to display',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount:
                                        getCurrentPageOfflineEmployees().length,
                                    itemBuilder: (context, index) {
                                      final record =
                                          getCurrentPageOfflineEmployees()[
                                              index];
                                      final leaveStatus =
                                          record['leave_status'] ?? 'Unknown';
                                      return buildOfflineEmployeesTile(
                                          record,
                                          leaveStatus,
                                          baseUrl,
                                          getToken,
                                          context);
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Column(
              children: [
                TabBar(
                  controller: _tabController,
                  labelColor: Colors.red,
                  indicatorColor: Colors.red,
                  unselectedLabelColor: Colors.grey,
                  isScrollable: true,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 17),
                  tabs: [
                    Tab(text: 'Overtime Validate ($overtimeValidate)'),
                    Tab(text: 'Non Validated ($nonValidated)'),
                  ],
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      overtimeValidate == 0
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inventory_outlined,
                                    color: Colors.black,
                                    size: 92,
                                  ),
                                  SizedBox(height: 20),
                                  Text(
                                    "There are no attendance records to display",
                                    style: TextStyle(
                                        fontSize: 16.0,
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            )
                          : buildOvertimeValidate(requestsOvertimeValidate,
                              baseUrl, _scrollController, getToken),
                      nonValidated == 0
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inventory_outlined,
                                    color: Colors.black,
                                    size: 92,
                                  ),
                                  SizedBox(height: 20),
                                  Text(
                                    "There are no attendance records to display",
                                    style: TextStyle(
                                        fontSize: 16.0,
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            )
                          : buildNonValidatedAttendance(
                              requestsNonValidAttendance,
                              baseUrl,
                              _scrollController,
                              getToken),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

double responsiveFontSize(
    BuildContext context, double largeFontSize, double smallFontSize) {
  double screenWidth = MediaQuery.of(context).size.width;
  if (screenWidth < 600) {
    return smallFontSize;
  } else {
    return largeFontSize;
  }
}

Widget _buildGridItem(
    BuildContext context, String headerText, String valueText) {
  return Container(
    width: 100.0,
    height: 100.0,
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(10.0),
    ),
    child: Padding(
      padding: const EdgeInsets.all(10.0),
      child: RichText(
        textAlign: TextAlign.left,
        text: TextSpan(
          children: [
            TextSpan(
              text: '$headerText\n',
              style: TextStyle(
                fontSize: responsiveFontSize(context, 15.0, 12.0),
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            TextSpan(
              text: valueText,
              style: TextStyle(
                fontSize: responsiveFontSize(context, 22.0, 18.0),
                // Adjust font size for smaller screens
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

Widget buildOfflineEmployeesTile(
    record, leaveStatus, baseUrl, token, BuildContext context) {
  return Column(
    children: [
      ListTile(
        leading: CircleAvatar(
          radius: 20.0,
          backgroundColor: Colors.white,
          child: Stack(
            children: [
              if (record['employee_profile'] != null &&
                  record['employee_profile'].isNotEmpty)
                Positioned.fill(
                  child: ClipOval(
                    child: Image.network(
                      baseUrl + record['employee_profile'],
                      headers: {
                        "Authorization": "Bearer $token",
                      },
                      fit: BoxFit.cover,
                      errorBuilder: (BuildContext context, Object exception,
                          StackTrace? stackTrace) {
                        return const Icon(Icons.person);
                      },
                    ),
                  ),
                ),
              if (record['employee_profile'] == null ||
                  record['employee_profile'].isEmpty)
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
        title: Text(
          record['employee_first_name'] +
              ' ' +
              (record['employee_last_name'] ?? ''),
          style: const TextStyle(
            fontSize: 16.0,
            color: Colors.black,
          ),
        ),
        trailing: SizedBox(
          width: 120,
          child: Row(
            children: [
              Container(
                width: 80,
                height: 25,
                padding: const EdgeInsets.fromLTRB(10.0, 1.0, 10.0, 1.0),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Center(
                  child: Text(
                    leaveStatus,
                    style: const TextStyle(
                      fontSize: 13.0,
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: () {
                    _showEmailDialog(context, record, baseUrl);
                  },
                  child: const Icon(
                    Icons.email_outlined,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      Divider(height: 1.0, color: Colors.grey[400]?.withOpacity(0.2))
    ],
  );
}

void _showEmailDialog(
    BuildContext context, Map<String, dynamic> record, String baseUrl) async {
  String? selectedTemplate;
  Map<String, String> templateItems = {};
  String bodyContent = '';
  String subject = '';
  TextEditingController bodyController = TextEditingController();
  templateItems = await getTemplate();
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                CircleAvatar(
                  radius: 20.0,
                  backgroundColor: Colors.transparent,
                  child: ClipOval(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ClipOval(
                            child: Image.network(
                              baseUrl + record['employee_profile'],
                              // headers: {
                              //   "Authorization": "Bearer $token",
                              // },
                              fit: BoxFit.cover,
                              errorBuilder: (BuildContext context,
                                  Object exception, StackTrace? stackTrace) {
                                return const Icon(Icons.person,
                                    color: Colors.grey);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10.0),
                Column(
                  children: [
                    Text(
                        '${record['employee_first_name']} ${record['employee_last_name']}'),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                    DropdownButtonFormField<String>(
                      style: const TextStyle(
                        fontWeight: FontWeight.normal,
                        color: Colors.black,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Select Template',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedTemplate,
                      items: templateItems.isNotEmpty
                          ? templateItems.entries.map((entry) {
                              return DropdownMenuItem<String>(
                                value: entry.key,
                                child: Text(entry.value),
                              );
                            }).toList()
                          : [
                              const DropdownMenuItem(
                                value: null,
                                child: Text(" "),
                              )
                            ],
                      onChanged: (newValue) async {
                        setState(() {
                          selectedTemplate = newValue;
                        });

                        if (selectedTemplate != null) {
                          String fetchedBodyContent =
                              await getConvertedMailTemplate(
                            selectedTemplate!,
                            record['id'].toString(),
                          );
                          html_parser.parse(fetchedBodyContent);
                          setState(() {
                            bodyContent = fetchedBodyContent;
                            bodyController.text = bodyContent;
                          });
                        }
                      },
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Subject',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          subject = value;
                        });
                      },
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.03),

                    // Editable HTML field with the persistent controller
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Edit Body Content',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: null,
                      controller: bodyController,
                      onChanged: (value) {
                        setState(() {
                          bodyContent = value;
                        });
                      },
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                    Html(
                      data: bodyContent,
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                child: const Text(
                  'Send',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () async {
                  await sendEmail(
                      record['id'].toString(), subject, bodyContent);
                  Navigator.of(context).pop(); // Close the dialog
                },
              ),
            ],
          );
        },
      );
    },
  );
}

Future<String> getConvertedMailTemplate(
    String templateId, String recordId) async {
  final prefs = await SharedPreferences.getInstance();
  var token = prefs.getString("token");
  var typedServerUrl = prefs.getString("typed_url");

  var uri = Uri.parse('$typedServerUrl/api/attendance/converted-mail-template');

  var request = http.MultipartRequest('PUT', uri);

  request.headers.addAll({
    "Authorization": "Bearer $token",
  });

  request.fields['template_id'] = templateId;
  request.fields['employee_id'] = recordId;

  var streamedResponse = await request.send();

  var response = await http.Response.fromStream(streamedResponse);

  if (response.statusCode == 200) {
    var data = jsonDecode(response.body);
    return data;
  } else {
    return 'Error: ${response.statusCode}';
  }
}

Future<Map<String, String>> getTemplate() async {
  final prefs = await SharedPreferences.getInstance();
  var token = prefs.getString("token");
  var typedServerUrl = prefs.getString("typed_url");

  var uri = Uri.parse('$typedServerUrl/api/attendance/mail-templates');
  var response = await http.get(uri, headers: {
    "Content-Type": "application/json",
    "Authorization": "Bearer $token",
  });
  if (response.statusCode == 200) {
    List<Map<String, dynamic>> templateList =
        List<Map<String, dynamic>>.from(jsonDecode(response.body));

    Map<String, String> templateMap = {};

    for (var template in templateList) {
      if (template.containsKey('id') && template.containsKey('title')) {
        templateMap[template['id'].toString()] = template['title'].toString();
      } else {}
    }

    return templateMap;
  } else {
    return {};
  }
}

Future<void> sendEmail(
    String recordId, String subject, String fetchedBodyContent) async {
  final prefs = await SharedPreferences.getInstance();
  var token = prefs.getString("token");
  var typedServerUrl = prefs.getString("typed_url");

  var uri =
      Uri.parse('$typedServerUrl/api/attendance/offline-employee-mail-send');

  var request = http.MultipartRequest('POST', uri);

  request.headers['Authorization'] = 'Bearer $token';

  request.fields['employee_id'] = recordId;
  request.fields['subject'] = subject;
  request.fields['body'] = fetchedBodyContent;
  var response = await request.send();
  if (response.statusCode == 200) {
    print('Email Sent Successfully');
  } else {}
}

Widget buildOvertimeValidate(
    List<Map<String, dynamic>> requestsOvertimeValidate,
    baseUrl,
    scrollController,
    token) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: ListView.builder(
      controller: scrollController,
      itemCount: requestsOvertimeValidate.length,
      itemBuilder: (context, index) {
        Map<String, dynamic> record = requestsOvertimeValidate[index];
        return Column(
          children: [
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      backgroundColor: Colors.white,
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(" "),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      ),
                      content: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.95,
                        height: MediaQuery.of(context).size.height * 0.4,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      width: 40.0,
                                      height: 40.0,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.grey, width: 1.0),
                                      ),
                                      child: Stack(
                                        children: [
                                          if (record['employee_profile_url'] !=
                                                  null &&
                                              record['employee_profile_url']
                                                  .isNotEmpty)
                                            Positioned.fill(
                                              child: ClipOval(
                                                child: Image.network(
                                                  baseUrl +
                                                      record[
                                                          'employee_profile_url'],
                                                  headers: {
                                                    "Authorization":
                                                        "Bearer $token",
                                                  },
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (BuildContext
                                                          context,
                                                      Object exception,
                                                      StackTrace? stackTrace) {
                                                    return const Icon(
                                                        Icons.person,
                                                        color: Colors.grey);
                                                  },
                                                ),
                                              ),
                                            ),
                                          if (record['employee_profile_url'] ==
                                                  null ||
                                              record['employee_profile_url']
                                                  .isEmpty)
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
                                    SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.01),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            (record['employee_first_name'] ??
                                                    '') +
                                                (record['employee_last_name'] ??
                                                    ''),
                                            style: const TextStyle(
                                                fontSize: 15.0,
                                                fontWeight: FontWeight.bold),
                                            maxLines: 2,
                                          ),
                                          Text(
                                            record['badge_id'] != null
                                                ? '(${record['badge_id']})'
                                                : '',
                                            style: const TextStyle(
                                                fontSize: 12.0,
                                                fontWeight: FontWeight.normal),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius:
                                                BorderRadius.circular(4.0),
                                          ),
                                        ),
                                        SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.008),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius:
                                                BorderRadius.circular(4.0),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.03),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Attendance Date',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(record['attendance_date'] ?? 'None'),
                                  ],
                                ),
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.01),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Check In',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(record['attendance_clock_in'] ??
                                        'None'),
                                  ],
                                ),
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.01),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Check In Date',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(record['attendance_clock_in_date'] ??
                                        'None'),
                                  ],
                                ),
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.01),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Check Out ',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(record['attendance_clock_out'] ??
                                        'None'),
                                  ],
                                ),
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.01),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Check Out Date',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(record['attendance_clock_out_date'] ??
                                        'None'),
                                  ],
                                ),
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.01),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Shift',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(record['shift_name'] ?? 'None'),
                                  ],
                                ),
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.01),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Work Type',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      record['work_type'] ?? 'None',
                                      maxLines: 2,
                                    ),
                                  ],
                                ),
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.01),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'At Work',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(record['attendance_worked_hour'] ??
                                        'None'),
                                  ],
                                ),
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.01),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Min Hour',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(record['minimum_hour'] ?? 'None'),
                                  ],
                                ),
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.01),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[50]!),
                    borderRadius: BorderRadius.circular(8.0),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade400.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Colors.white, width: 0.0),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    color: Colors.white,
                    elevation: 0.1,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 35.0,
                                height: 35.0,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.grey, width: 1.0),
                                ),
                                child: Stack(
                                  children: [
                                    if (record['employee_profile_url'] !=
                                            null &&
                                        record['employee_profile_url']
                                            .isNotEmpty)
                                      Positioned.fill(
                                        child: ClipOval(
                                          child: Image.network(
                                            baseUrl +
                                                record['employee_profile_url'],
                                            headers: {
                                              "Authorization": "Bearer $token",
                                            },
                                            fit: BoxFit.cover,
                                            errorBuilder: (BuildContext context,
                                                Object exception,
                                                StackTrace? stackTrace) {
                                              return const Icon(Icons.person,
                                                  color: Colors.grey);
                                            },
                                          ),
                                        ),
                                      ),
                                    if (record['employee_profile_url'] ==
                                            null ||
                                        record['employee_profile_url'].isEmpty)
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
                              SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.01),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (record['employee_first_name'] ?? '') +
                                          (record['employee_last_name'] ?? ''),
                                      style: const TextStyle(
                                          fontSize: 15.0,
                                          fontWeight: FontWeight.bold),
                                      maxLines: 2,
                                    ),
                                    Text(
                                      record['badge_id'] != null
                                          ? '(${record['badge_id']})'
                                          : '',
                                      style: const TextStyle(
                                          fontSize: 12.0,
                                          fontWeight: FontWeight.normal),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.005),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Date'),
                              Text('${record['attendance_date']}'),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Check-In'),
                              Text('${record['attendance_clock_in_date']}'),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Check-Out'),
                              Text('${record['attendance_clock_out_date']}'),
                            ],
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.02),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

Widget buildNonValidatedAttendance(
    List<Map<String, dynamic>> requestsNonValidAttendance,
    baseUrl,
    token,
    scrollController) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: ListView.builder(
      controller: scrollController,
      itemCount: requestsNonValidAttendance.length,
      itemBuilder: (context, index) {
        Map<String, dynamic> record = requestsNonValidAttendance[index];
        return Column(
          children: [
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      backgroundColor: Colors.white,
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(" "),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      ),
                      content: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.95,
                        height: MediaQuery.of(context).size.height * 0.4,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      width: 40.0,
                                      height: 40.0,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.grey, width: 1.0),
                                      ),
                                      child: Stack(
                                        children: [
                                          if (record['employee_profile_url'] !=
                                                  null &&
                                              record['employee_profile_url']
                                                  .isNotEmpty)
                                            Positioned.fill(
                                              child: ClipOval(
                                                child: Image.network(
                                                  baseUrl +
                                                      record[
                                                          'employee_profile_url'],
                                                  headers: {
                                                    "Authorization":
                                                        "Bearer $token",
                                                  },
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (BuildContext
                                                          context,
                                                      Object exception,
                                                      StackTrace? stackTrace) {
                                                    return const Icon(
                                                        Icons.person,
                                                        color: Colors.grey);
                                                  },
                                                ),
                                              ),
                                            ),
                                          if (record['employee_profile_url'] ==
                                                  null ||
                                              record['employee_profile_url']
                                                  .isEmpty)
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
                                    SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.01),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            (record['employee_first_name'] ??
                                                    '') +
                                                (record['employee_last_name'] ??
                                                    ''),
                                            style: const TextStyle(
                                                fontSize: 15.0,
                                                fontWeight: FontWeight.bold),
                                            maxLines: 2,
                                          ),
                                          Text(
                                            record['badge_id'] != null
                                                ? '(${record['badge_id']})'
                                                : '',
                                            style: const TextStyle(
                                                fontSize: 12.0,
                                                fontWeight: FontWeight.normal),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius:
                                                BorderRadius.circular(4.0),
                                          ),
                                        ),
                                        SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.008),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius:
                                                BorderRadius.circular(4.0),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.03),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Attendance Date',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(record['attendance_date'] ?? 'None'),
                                  ],
                                ),
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.01),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Check In',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(record['attendance_clock_in'] ??
                                        'None'),
                                  ],
                                ),
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.01),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Check In Date',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(record['attendance_clock_in_date'] ??
                                        'None'),
                                  ],
                                ),
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.01),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Check Out ',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(record['attendance_clock_out'] ??
                                        'None'),
                                  ],
                                ),
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.01),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Check Out Date',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(record['attendance_clock_out_date'] ??
                                        'None'),
                                  ],
                                ),
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.01),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Shift',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(record['shift_name'] ?? 'None'),
                                  ],
                                ),
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.01),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Work Type',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(record['work_type'] ?? 'None'),
                                  ],
                                ),
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.01),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'At Work',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(record['attendance_worked_hour'] ??
                                        'None'),
                                  ],
                                ),
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.01),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Min Hour',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(record['minimum_hour'] ?? 'None'),
                                  ],
                                ),
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.01),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[50]!),
                    borderRadius: BorderRadius.circular(8.0),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade400.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Colors.white, width: 0.0),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    color: Colors.white,
                    elevation: 0.1,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 35.0,
                                height: 35.0,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.grey, width: 1.0),
                                ),
                                child: Stack(
                                  children: [
                                    if (record['employee_profile_url'] !=
                                            null &&
                                        record['employee_profile_url']
                                            .isNotEmpty)
                                      Positioned.fill(
                                        child: ClipOval(
                                          child: Image.network(
                                            baseUrl +
                                                record['employee_profile_url'],
                                            headers: {
                                              "Authorization": "Bearer $token",
                                            },
                                            fit: BoxFit.cover,
                                            errorBuilder: (BuildContext context,
                                                Object exception,
                                                StackTrace? stackTrace) {
                                              return const Icon(Icons.person,
                                                  color: Colors.grey);
                                            },
                                          ),
                                        ),
                                      ),
                                    if (record['employee_profile_url'] ==
                                            null ||
                                        record['employee_profile_url'].isEmpty)
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
                              SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.01),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (record['employee_first_name'] ?? '') +
                                          (record['employee_last_name'] ?? ''),
                                      style: const TextStyle(
                                          fontSize: 15.0,
                                          fontWeight: FontWeight.bold),
                                      maxLines: 2,
                                    ),
                                    Text(
                                      record['badge_id'] != null
                                          ? '(${record['badge_id']})'
                                          : '',
                                      style: const TextStyle(
                                          fontSize: 12.0,
                                          fontWeight: FontWeight.normal),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.005),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Date'),
                              Text('${record['attendance_date']}'),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Check-In'),
                              Text('${record['attendance_clock_in_date']}'),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Check-Out'),
                              Text('${record['attendance_clock_out_date']}'),
                            ],
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.02),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}
