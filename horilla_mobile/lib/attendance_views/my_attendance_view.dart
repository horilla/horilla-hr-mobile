import 'dart:convert';
import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../res/consts/app_colors.dart';

class MyAttendanceViews extends StatefulWidget {
  const MyAttendanceViews({super.key});

  @override
  _MyAttendanceViews createState() => _MyAttendanceViews();
}

class _MyAttendanceViews extends State<MyAttendanceViews>
    with SingleTickerProviderStateMixin {
  late String baseUrl = '';
  late Map<String, dynamic> arguments;
  final _pageController = PageController(initialPage: 0);
  final _controller = NotchBottomBarController(index: -1);
  final List<Widget> bottomBarPages = [
    const Home(),
    const Overview(),
    const User(),
  ];
  TextEditingController dateInputMyAttendances = TextEditingController();
  TextEditingController checkInTimeMyAttendances = TextEditingController();
  TextEditingController checkOutTimeMyAttendances = TextEditingController();
  int maxCount = 5;
  var shiftItems = [''];
  bool permissionCheck = false;
  List<Map<String, dynamic>> requestsShiftNames = [];
  String employeeName = '';
  String employeeProfile = '';
  String badgeId = '';
  String shiftName = '';
  String attendanceDate = '';
  String attendanceClockInDate = '';
  String attendanceClockIn = '';
  String attendanceClockOutDate = '';
  String attendanceClockOut = '';
  String attendanceWorkedHour = '';
  String minimumHour = '';
  late String getToken = '';


  @override
  void initState() {
    super.initState();
    prefetchData();
    getBaseUrl();
    fetchToken();
    dateInputMyAttendances.text = "";
    checkInTimeMyAttendances.text = "";
    checkOutTimeMyAttendances.text = "";
  }

  Future<void> fetchToken() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    print(token);
    print('rrrrrrrttttttt');
    setState(() {
      getToken = token ?? '';
      print('token: $getToken');
    });
  }

  Future<void> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    var typedServerUrl = prefs.getString("typed_url");
    setState(() {
      baseUrl = typedServerUrl ?? '';
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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

  Future<void> getAllShiftNames() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/base/employee-shift/');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      setState(() {
        requestsShiftNames = List<Map<String, dynamic>>.from(
          jsonDecode(response.body),
        );
        for (var shift in requestsShiftNames) {
          var shifts = shift['employee_shift'];
          shiftItems.add(shifts);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    employeeName = args['employee_name'] ?? 'None';
    badgeId = args['badge_id'] ?? '';
    shiftName = args['shift_name'] ?? 'None';
    attendanceDate = args['attendance_date'] ?? 'None';
    attendanceClockInDate = args['attendance_clock_in_date'] ?? 'None';
    attendanceClockIn = args['attendance_clock_in'] ?? 'None';
    attendanceClockOutDate = args['attendance_clock_out_date'] ?? 'None';
    attendanceClockOut = args['attendance_clock_out'] ?? 'None';
    attendanceWorkedHour = args['attendance_worked_hour'] ?? 'None';
    minimumHour = args['minimum_hour'] ?? 'None';
    employeeProfile = args['employee_profile'] ?? 'None';
    permissionCheck = args['permission_check'];
    return Scaffold(
      backgroundColor: whiteColor,
      appBar: AppBar(
        backgroundColor: whiteColor,
        automaticallyImplyLeading: false,
        title: const Text('My Attendances',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: const [],
      ),
      floatingActionButton: const Padding(
        padding: EdgeInsets.all(25.0),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        if (employeeProfile.isNotEmpty)
                          Positioned.fill(
                            child: ClipOval(
                              child: Image.network(
                                baseUrl + employeeProfile,
                                headers: {
                                  "Authorization": "Bearer $getToken",
                                },
                                fit: BoxFit.cover,
                                errorBuilder: (BuildContext context,
                                    Object exception, StackTrace? stackTrace) {
                                  return const Icon(Icons.person,
                                      color: Colors.grey);
                                },
                              ),
                            ),
                          ),
                        if (employeeProfile.isEmpty)
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
                  SizedBox(width: MediaQuery.of(context).size.width * 0.01),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employeeName,
                          style: const TextStyle(
                              fontSize: 16.0, fontWeight: FontWeight.bold),
                          maxLines: 2,
                        ),
                        Text(
                          badgeId,
                          style: const TextStyle(
                              fontSize: 12.0, fontWeight: FontWeight.normal),
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
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      ),
                      SizedBox(
                          width: MediaQuery.of(context).size.width * 0.008),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.005),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Fields',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    'Request',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Date',
                    style: TextStyle(color: grey700),
                  ),
                  Text(attendanceDate,
                      style: const TextStyle(color: Colors.black)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Check-In',
                    style: TextStyle(color: grey700),
                  ),
                  Text(attendanceClockIn,
                      style: const TextStyle(color: Colors.black)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Check-Out',
                    style: TextStyle(color: grey700),
                  ),
                  Text(attendanceClockOut,
                      style: const TextStyle(color: Colors.black)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Shift',
                    style: TextStyle(color: grey700),
                  ),
                  Text(shiftName, style: const TextStyle(color: Colors.black)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Minimum Hour',
                    style: TextStyle(color: grey700),
                  ),
                  Text(minimumHour,
                      style: const TextStyle(color: Colors.black)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Check-In Date',
                    style: TextStyle(color: grey700),
                  ),
                  Text(attendanceClockInDate,
                      style: const TextStyle(color: Colors.black)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Check-Out Date',
                    style: TextStyle(color: grey700),
                  ),
                  Text(attendanceClockOutDate,
                      style: const TextStyle(color: Colors.black)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'At Work',
                    style: TextStyle(color: grey700),
                  ),
                  Text(attendanceWorkedHour,
                      style: const TextStyle(color: Colors.black)),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
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
                    color: whiteColor,
                  ),
                  activeItem: Icon(
                    Icons.home_filled,
                    color: whiteColor,
                  ),
                ),
                BottomBarItem(
                  inActiveItem: Icon(
                    Icons.update_outlined,
                    color: whiteColor,
                  ),
                  activeItem: Icon(
                    Icons.update_outlined,
                    color: whiteColor,
                  ),
                ),
                BottomBarItem(
                  inActiveItem: Icon(
                    Icons.person,
                    color: whiteColor,
                  ),
                  activeItem: Icon(
                    Icons.person,
                    color: whiteColor,
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

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushNamed(context, '/home');
    });
    return Container(
      color: whiteColor,
      child: const Center(child: Text('Page 1')),
    );
  }
}

class Overview extends StatelessWidget {
  const Overview({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        color: whiteColor, child: const Center(child: Text('Page 2')));
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
      color: whiteColor,
      child: const Center(child: Text('Page 1')),
    );
  }
}
