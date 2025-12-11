import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:horilla/checkin_checkout/checkin_checkout_views/stopwatch.dart';
import 'package:permission_handler/permission_handler.dart' as AppSettings;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:shimmer/shimmer.dart';
import 'package:geolocator/geolocator.dart';
import '../../horilla_main/home.dart';
import 'face_detection.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../../res/consts/app_colors.dart';



class CheckInCheckOutFormPage extends StatefulWidget {
  const CheckInCheckOutFormPage({super.key});

  @override
  _CheckInCheckOutFormPageState createState() => _CheckInCheckOutFormPageState();
}

class _CheckInCheckOutFormPageState extends State<CheckInCheckOutFormPage> {
  List<Map<String, dynamic>> attendanceList = [];
  List<Map<String, dynamic>> attendanceLists = [];
  late String swipeDirection;
  late String baseUrl = '';
  late Timer t;
  late String requestsEmpMyFirstName = '';
  late String requestsEmpMyLastName = '';
  late String requestsEmpMyBadgeId = '';
  late String requestsEmpMyDepartment = '';
  late String requestsEmpProfile = '';
  late String requestsEmpMyWorkInfoId = '';
  late String requestsEmpMyShiftName = '';
  bool clockCheckBool = false;
  bool clockCheckedIn = false;
  bool isLoading = true;
  bool isCheckIn = false;
  bool _isProcessingDrag = false;
  String? checkInFormattedTime = '00:00';
  String elapsedTimeString = '00:00:00';
  String? checkOutFormattedTime = '00:00';
  String? checkInFormattedTimeTopR;
  String? workingTime = '00:00:00';
  String? clockIn;
  String? clockInTimes;
  String? duration;
  String? timeDisplay;
  final StopwatchManager stopwatchManager = StopwatchManager();
  final _controller = NotchBottomBarController(index: 1);
  int maxCount = 5;
  Map<String, dynamic> arguments = {};
  Duration elapsedTime = Duration.zero;
  Position? userLocation;
  Duration accumulatedDuration = Duration.zero;
  bool _locationSnackBarShown = false;
  bool _locationUnavailableSnackBarShown = false;
  late String getToken = '';



  @override
  void initState() {
    super.initState();
    fetchToken();
    swipeDirection = 'Swipe to Check-In';
    _initializeData();
    if (clockCheckedIn) {
      getCheckIn().then((_) {
        setState(() {
          if (clockIn != 'false' && duration != null) {
            Duration? initialDuration = parseDuration(duration!);
            if (initialDuration != null) {
              accumulatedDuration = initialDuration;
              stopwatchManager.startStopwatch(initialTime: initialDuration);
              elapsedTimeString = formatDuration(initialDuration);
              workingTime = formatDuration(initialDuration);
              _saveAccumulatedDuration(initialDuration);
            }
          }
        });
      });
    }
  }

  Future<void> fetchToken() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    setState(() {
      getToken = token ?? '';
      print('token: $getToken');
    });
  }

  Future<void> _initializeData() async {
    try {
      var face_detection = await getFaceDetection();
      final prefs = await SharedPreferences.getInstance();
      prefs.remove('face_detection');
      prefs.setBool("face_detection", face_detection);
      await _initializeLocation();
      await Future.wait<void>([
        prefetchData(),
        _loadClockState(),
        getBaseUrl(),
        getLoginEmployeeRecord(),
        getCheckIn(),
      ]);
      // Initialize stopwatch with server duration if checked in
      accumulatedDuration = await _loadAccumulatedDuration();
      if (clockIn != 'false' && duration != null) {
        Duration? initialDuration = parseDuration(duration!);
        if (initialDuration != null) {
          accumulatedDuration = initialDuration;
          print('Initializing stopwatch with duration: $initialDuration');
          stopwatchManager.startStopwatch(initialTime: initialDuration);
          elapsedTimeString = formatDuration(initialDuration);
          workingTime = formatDuration(initialDuration);
          await _saveAccumulatedDuration(initialDuration);
        }
      }
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error initializing data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to initialize data: $e')),
      );
    }
  }

  Future<void> _saveAccumulatedDuration(Duration duration) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('accumulated_duration_seconds', duration.inSeconds);
  }

  Future<void> _initializeLocation() async {
    final prefs = await SharedPreferences.getInstance();
    var geo_fencing = prefs.getBool("geo_fencing");
    if (geo_fencing == true) {
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled && geo_fencing == true) {
          if (!_locationSnackBarShown) {
            _locationSnackBarShown = true;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Location services are disabled. Please enable them.'),
                action: SnackBarAction(
                  label: 'Enable',
                  onPressed: () {
                    Geolocator.openLocationSettings();
                  },
                ),
              ),
            );
          }
          return;
        }

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied.')),
            );
            return;
          }
        }

        if (permission == LocationPermission.deniedForever) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Location permissions are permanently denied.'),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () {
                  AppSettings.openAppSettings();
                },
              ),
            ),
          );
          return;
        }

        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        setState(() {
          userLocation = position;
          print('Initialized userLocation: $userLocation');
        });
      } catch (e) {
        print('Error fetching location: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get location: $e')),
        );
      }
    }
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    await getCheckIn();
    if (clockIn != 'false') {
      isCheckIn = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          clockCheckedIn = true;
          clockCheckBool = true;
          DateTime now = DateTime.now();
          timeDisplay = clockIn;
          checkInFormattedTimeTopR = DateFormat('h:mm').format(now);
          Duration clockInTime = Duration.zero;
          String? clockTimeString = duration;
          if (clockTimeString != null) {
            List<String> timeComponents = clockTimeString.split(':');
            int hours = int.parse(timeComponents[0]);
            int minutes = int.parse(timeComponents[1]);
            int seconds = int.parse(timeComponents[2].split('.')[0]);
            clockInTime = Duration(hours: hours, minutes: minutes, seconds: seconds);
          }
          stopwatchManager.startStopwatch(initialTime: clockInTime);
          _saveClockState(clockCheckedIn, 1, checkInFormattedTime.toString());
          swipeDirection = 'Swipe to Check-out';
        });
      });
    } else {
      isCheckIn = false;
      clockCheckedIn = false;
      clockCheckBool = false;
      timeDisplay = clockInTimes;
      Duration clockInTime = Duration.zero;
      String? clockTimeString = duration;
      elapsedTimeString = duration ?? '';
      if (clockTimeString != null) {
        List<String> timeComponents = clockTimeString.split(':');
        int hours = int.parse(timeComponents[0]);
        int minutes = int.parse(timeComponents[1]);
        int seconds = int.parse(timeComponents[2].split('.')[0]);
        clockInTime = Duration(hours: hours, minutes: minutes, seconds: seconds);
        elapsedTime = clockInTime;
      }
      swipeDirection = 'Swipe to Check-In';
    }
  }

  Future<void> getCheckIn() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/attendance/checking-in');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      var responseBody = jsonDecode(response.body);
      if (responseBody['status'] == true) {
        setState(() {
          clockIn = true.toString();
          clockIn = responseBody['clock_in'];
          duration = responseBody['duration'];
        });
      } else {
        setState(() {
          clockIn = false.toString();
          clockInTimes = responseBody['clock_in_time'];
          duration = responseBody['duration'];
        });
      }
    }
  }

  Future<Duration> _loadAccumulatedDuration() async {
    final prefs = await SharedPreferences.getInstance();
    int seconds = prefs.getInt('accumulated_duration_seconds') ?? 0;
    return Duration(seconds: seconds);
  }

  Duration? parseDuration(String durationString) {
    try {
      List<String> parts = durationString.split(':');
      if (parts.length >= 3) {
        int hours = int.parse(parts[0]);
        int minutes = int.parse(parts[1]);
        String secondsPart = parts[2].split('.')[0];
        int seconds = int.parse(secondsPart);
        return Duration(hours: hours, minutes: minutes, seconds: seconds);
      }
      print('Invalid duration format: $durationString');
      return Duration.zero;
    } catch (e) {
      print('Error parsing duration "$durationString": $e');
      return Duration.zero;
    }
  }

  Future<void> prefetchData() async {
    final prefs = await SharedPreferences.getInstance();
    var geo_fencing = prefs.getBool("geo_fencing");
    if (geo_fencing == true) {
      userLocation = await fetchCurrentLocation();
    }
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
        'employee_name': responseData['employee_first_name'] + ' ' + responseData['employee_last_name'],
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

  _loadClockState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      clockCheckedIn = prefs.getBool('clockCheckedIn') ?? false;
      checkInFormattedTime = prefs.getString('checkin') ?? '00:00';
      checkOutFormattedTime = prefs.getString('checkout') ?? '00:00';
    });
  }

  _saveClockState(bool isCheckedIn, int option, [String? check]) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('clockCheckedIn', isCheckedIn);
    if (check != null && option == 2) {
      prefs.setString('checkout', check);
    } else {
      prefs.setString('checkin', check!);
    }
  }

  @override
  void dispose() {
    // t.cancel();
    super.dispose();
  }

  Future<void> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    var typedServerUrl = prefs.getString("typed_url");
    setState(() {
      baseUrl = typedServerUrl ?? '';
    });
  }

  Future<void> getLoginEmployeeRecord() async {
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
      var responseBody = jsonDecode(response.body);
      setState(() {
        requestsEmpMyFirstName = responseBody['employee_first_name'] ?? '';
        requestsEmpMyLastName = responseBody['employee_last_name'] ?? '';
        requestsEmpMyBadgeId = responseBody['badge_id'] ?? '';
        requestsEmpMyDepartment = responseBody['department_name'] ?? '';
        requestsEmpProfile = responseBody['employee_profile'] ?? '';
        requestsEmpMyWorkInfoId = responseBody['employee_work_info_id'] ?? '';
      });
      getLoginEmployeeWorkInfoRecord(requestsEmpMyWorkInfoId);
    }
  }

  Future<void> getLoginEmployeeWorkInfoRecord(String requestsEmpMyWorkInfoId) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/employee/employee-work-information/$requestsEmpMyWorkInfoId');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      var responseBody = jsonDecode(response.body);
      setState(() {
        var shiftName = responseBody['shift_name'];
        requestsEmpMyShiftName = shiftName ?? "None";
        isLoading = false;
      });
    }
  }

  Future<Position?> fetchCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      print('Error fetching location: $e');
      return null;
    }
  }

  Future<bool> getFaceDetection() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/facedetection/config/');

    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      bool isEnabled = data['start'] ?? false;
      return isEnabled;
    } else {
      print('Failed to get face detection setup');
      return false;
    }
  }


  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  String getErrorMessage(String responseBody) {
    try {
      final Map<String, dynamic> decoded = json.decode(responseBody);
      return decoded['message'] ?? 'Unknown error occurred';
    } catch (e) {
      return 'Error parsing server response';
    }
  }

  Future<void> postCheckout() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/attendance/clock-out/');
    var response = await http.post(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      setState(() {});
    }
  }

  Future<void> postCheckIn() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/attendance/clock-in/');
    var response = await http.post(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      setState(() {});
    }
  }

  void showCheckInFailedDialog(BuildContext context, String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Check-in Failed'),
          content: Text(errorMessage),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => HomePage()),
                );
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.red,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await clearToken();
              stopwatchManager.resetStopwatch();
              Navigator.pushNamed(context, '/login');
            },
          ),
        ],
      ),
      body: isLoading ? _buildLoadingWidget() : _buildCheckInCheckoutWidget(getToken),
      bottomNavigationBar: AnimatedNotchBottomBar(
        notchBottomBarController: _controller,
        color: Colors.red,
        showLabel: true,
        notchColor: Colors.red,
        kBottomRadius: 28.0,
        kIconSize: 24.0,
        removeMargins: false,
        bottomBarWidth: MediaQuery.of(context).size.width,
        durationInMilliSeconds: 500,
        bottomBarItems: const [
          BottomBarItem(
            inActiveItem: Icon(Icons.home_filled, color: Colors.white),
            activeItem: Icon(Icons.home_filled, color: Colors.white),
          ),
          BottomBarItem(
            inActiveItem: Icon(Icons.update_outlined, color: Colors.white),
            activeItem: Icon(Icons.update_outlined, color: Colors.white),
          ),
          BottomBarItem(
            inActiveItem: Icon(Icons.person, color: Colors.white),
            activeItem: Icon(Icons.person, color: Colors.white),
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
                Navigator.pushNamed(context, '/employee_checkin_checkout');
              });
              break;
            case 2:
              Future.delayed(const Duration(milliseconds: 1000), () {
                Navigator.pushNamed(context, '/employees_form', arguments: arguments);
              });
              break;
          }
        },
      ),
    );
  }

  void storeCheckoutTime() {
    elapsedTime = stopwatchManager.elapsed;
    elapsedTimeString = elapsedTime.toString().split('.').first.padLeft(8, '0');
  }

  Widget _buildLoadingWidget() {
    checkInFormattedTime = timeDisplay;
    return ListView(
      children: [
        if (clockCheckBool || clockCheckedIn)
          Container(
            color: Colors.red,
            height: MediaQuery.of(context).size.height * 0.25,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Clock In', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                      Text('00:00:00', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.access_alarm),
                            color: Colors.white,
                            iconSize: 40,
                          ),
                          StreamBuilder<int>(
                            stream: Stream.periodic(const Duration(milliseconds: 1), (_) {
                              return stopwatchManager.elapsed.inMilliseconds;
                            }),
                            builder: (context, snapshot) {
                              return Text(
                                '${Duration(milliseconds: snapshot.data ?? 0)}'.substring(0, 7),
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 25),
                              );
                            },
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Clocked In: Today at ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(
                            checkInFormattedTime ?? DateFormat('h:mm').format(DateTime.now()) + (DateTime.now().hour < 12 ? ' AM' : ' PM'),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            color: Colors.red,
            height: MediaQuery.of(context).size.height * 0.25,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Clock Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                      Text(elapsedTimeString, style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.access_alarm),
                            color: Colors.white,
                            iconSize: 40,
                          ),
                          Text(
                            elapsedTimeString,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 25),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.02),
        // Shimmer loading placeholder remains unchanged
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Shimmer.fromColors(
            baseColor: grey300,
            highlightColor: grey100,
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 1,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey[50]!),
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade400.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(width: 90.0, height: 90.0, decoration: BoxDecoration(color: Colors.grey[300], shape: BoxShape.circle)),
                              const SizedBox(width: 10.0),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(height: 20.0, color: Colors.grey[300]),
                                    const SizedBox(height: 5.0),
                                    Container(height: 120.0, width: 90.0, color: Colors.grey[300]),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5.0),
                          Container(height: 16.0, width: double.infinity, color: Colors.grey[300]),
                          const SizedBox(height: 5.0),
                          Container(height: 16.0, width: double.infinity, color: Colors.grey[300]),
                          const SizedBox(height: 5.0),
                          Container(height: 16.0, width: double.infinity, color: Colors.grey[300]),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        GestureDetector(
          onHorizontalDragUpdate: (details) {
            if (details.primaryDelta! < 0) {
              setState(() {
                clockCheckedIn = true;
                swipeDirection = 'Swipe to Check-In';
              });
            } else if (details.primaryDelta! > 0) {
              setState(() {
                clockCheckedIn = true;
                swipeDirection = 'Swipe to Check-out';
              });
            }
          },
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 0.0, bottom: 8.0),
            child: Shimmer.fromColors(
              baseColor: grey300,
              highlightColor: grey100,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.95,
                height: MediaQuery.of(context).size.height * 0.07,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(15.0), color: Colors.grey),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckInCheckoutWidget(token) {
    checkInFormattedTime = timeDisplay;
    return ListView(
      children: [
        if (clockCheckBool || clockCheckedIn)
          Container(
            color: Colors.red,
            height: MediaQuery.of(context).size.height * 0.25,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Clock In', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                        Text('00:00:00', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.access_alarm),
                              color: Colors.white,
                              iconSize: 40,
                            ),
                            StreamBuilder<int>(
                              stream: Stream.periodic(const Duration(milliseconds: 1), (_) {
                                return stopwatchManager.elapsed.inMilliseconds;
                              }),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  int milliseconds = snapshot.data!;
                                  Duration duration = Duration(milliseconds: milliseconds);
                                  String formattedTime =
                                      '${duration.inHours.toString().padLeft(2, '0')}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
                                  return Text(
                                    formattedTime,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 25),
                                  );
                                }
                                return const Text('00:00:00', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 25));
                              },
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Clocked In: Today at ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                            Text(
                              checkInFormattedTime ?? DateFormat('h:mm').format(DateTime.now()) + (DateTime.now().hour < 12 ? ' AM' : ' PM'),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Container(
            color: Colors.red,
            height: MediaQuery.of(context).size.height * 0.25,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Clock Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                      Text(elapsedTimeString, style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.access_alarm),
                            color: Colors.white,
                            iconSize: 40,
                          ),
                          Text(
                            elapsedTimeString,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 25),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.02),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300, width: 0.0),
              boxShadow: [
                BoxShadow(color: Colors.grey.shade50.withOpacity(0.3), spreadRadius: 7, blurRadius: 1, offset: const Offset(0, 1)),
              ],
            ),
            width: MediaQuery.of(context).size.width * 0.50,
            height: MediaQuery.of(context).size.height * 0.3,
            child: Card(
              shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.white, width: 0.0), borderRadius: BorderRadius.circular(10.0)),
              color: Colors.white,
              elevation: 0.1,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 40.0,
                          height: 40.0,
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey, width: 1.0)),
                          child: Stack(
                            children: [
                              if (requestsEmpProfile.isNotEmpty)
                                Positioned.fill(
                                  child: ClipOval(
                                    child: Image.network(
                                      baseUrl + requestsEmpProfile,
                                      headers: {
                                        "Authorization": "Bearer $token",
                                      },
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, exception, stackTrace) => const Icon(Icons.person, color: Colors.grey),
                                    ),
                                  ),
                                ),
                              if (requestsEmpProfile.isEmpty)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey[400]),
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
                                '$requestsEmpMyFirstName $requestsEmpMyLastName',
                                style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(requestsEmpMyBadgeId, style: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.normal)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Department'),
                          Text(requestsEmpMyDepartment),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Check-In'),
                          Text('$checkInFormattedTime'),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Shift'),
                          Text(requestsEmpMyShiftName),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.02),
        GestureDetector(
          onPanUpdate: (details) async {
            if (!_isProcessingDrag) {
              final prefs = await SharedPreferences.getInstance();
              var face_detection = prefs.getBool("face_detection");
              var geo_fencing = prefs.getBool("geo_fencing");
              if (face_detection == true) {
                if (details.delta.dx.abs() > details.delta.dy.abs() && details.delta.dx.abs() > 10) {
                  _isProcessingDrag = true;
                  if (userLocation == null) {
                    if (!_locationUnavailableSnackBarShown && geo_fencing == true) {
                      _locationUnavailableSnackBarShown = true;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Location unavailable. Cannot proceed.')),
                      );
                    }
                    _isProcessingDrag = false;
                  }
                  if (details.delta.dx < 0 && clockCheckedIn) {
                    // Check-out
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FaceScanner(
                          userLocation: userLocation,
                          userDetails: arguments,
                          attendanceState: 'CHECKED_IN',
                        ),
                      ),
                    );
                    if (result != null && result['checkedOut'] == true) {
                      setState(() {
                        isCheckIn = false;
                        clockCheckedIn = false;
                        stopwatchManager.stopStopwatch();
                        storeCheckoutTime();
                        Duration initialElapsedTime = stopwatchManager.elapsed;
                        workingTime = formatDuration(initialElapsedTime);
                        clockCheckBool = false;
                        DateTime now = DateTime.now();
                        checkOutFormattedTime = DateFormat('h:mm a').format(now);
                        swipeDirection = 'Swipe to Check-In';
                        _saveClockState(
                            clockCheckedIn, 2, checkOutFormattedTime.toString());
                      });
                    }
                  } else if (details.delta.dx > 0 && !clockCheckedIn) {
                    // Check-in
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FaceScanner(
                          userLocation: userLocation,
                          userDetails: arguments,
                          attendanceState: 'NOT_CHECKED_IN',
                        ),
                      ),
                    );
                    if (result != null && result['checkedIn'] == true) {
                      setState(() {
                        isCheckIn = true;
                        clockCheckedIn = true;
                        clockCheckBool = true;
                        DateTime now = DateTime.now();
                        checkInFormattedTime = DateFormat('h:mm a').format(now);
                        checkInFormattedTimeTopR = DateFormat('h:mm').format(now);
                        _saveClockState(
                            clockCheckedIn, 1, checkInFormattedTime.toString());

                        if (duration?.isNotEmpty ?? false) {
                          String durationString = duration.toString();

                          try {
                            List<String> parts = durationString.split(':');
                            if (parts.length == 3) {
                              int hours = int.parse(parts[0]);
                              int minutes = int.parse(parts[1]);
                              int seconds = int.parse(parts[2]);
                              Duration initialElapsedTime = Duration(
                                  hours: hours, minutes: minutes, seconds: seconds);
                              stopwatchManager.startStopwatch(
                                  initialTime: initialElapsedTime);
                            }
                          } catch (e) {}
                        } else {}

                        swipeDirection = 'Swipe to Check-out';
                      });
                    }
                  }
                }
              }
              else if (geo_fencing == true) {
                if (details.delta.dx.abs() > details.delta.dy.abs() && details.delta.dx.abs() > 10) {
                  _isProcessingDrag = true;
                  if (userLocation == null) {
                    if (!_locationUnavailableSnackBarShown) {
                      _locationUnavailableSnackBarShown = true;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Location unavailable. Cannot proceed.')),
                      );
                    }
                    _isProcessingDrag = false;
                    return;
                  }

                  if (details.delta.dx < 0 && clockCheckedIn) {
                    final prefs = await SharedPreferences.getInstance();
                    var token = prefs.getString("token");
                    var typedServerUrl = prefs.getString("typed_url");
                    var geo_fencing = prefs.getBool("geo_fencing");
                    var uri = Uri.parse('$typedServerUrl/api/attendance/clock-out/');
                    var response_geofence = await http.post(
                      uri,
                      headers: {
                        "Content-Type": "application/json",
                        "Authorization": "Bearer $token",
                      },
                      body: jsonEncode({
                        "latitude": userLocation!.latitude,
                        "longitude": userLocation!.longitude,
                      }),
                    );

                    if (response_geofence.statusCode == 200) {
                      setState(() {
                        isCheckIn = false;
                        clockCheckedIn = false;
                        stopwatchManager.stopStopwatch();
                        storeCheckoutTime();
                        clockCheckBool = false;
                        DateTime now = DateTime.now();
                        checkOutFormattedTime = DateFormat('h:mm a').format(now);
                        swipeDirection = 'Swipe to Check-In';
                        _saveClockState(clockCheckedIn, 2, checkOutFormattedTime.toString());
                      });
                    } else {
                      String errorMessage = getErrorMessage(response_geofence.body);
                      showCheckInFailedDialog(context, errorMessage);
                    }
                  } else if (details.delta.dx > 0 && !clockCheckedIn) {
                    final prefs = await SharedPreferences.getInstance();
                    var token = prefs.getString("token");
                    var typedServerUrl = prefs.getString("typed_url");
                    var geo_fencing = prefs.getBool("geo_fencing");
                    var uri = Uri.parse('$typedServerUrl/api/attendance/clock-in/');
                    var response_geofence = await http.post(
                      uri,
                      headers: {
                        "Content-Type": "application/json",
                        "Authorization": "Bearer $token",
                      },
                      body: jsonEncode({
                        "latitude": userLocation!.latitude,
                        "longitude": userLocation!.longitude,
                      }),
                    );

                    if (response_geofence.statusCode == 200) {
                      setState(() {
                        isCheckIn = true;
                        clockCheckedIn = true;
                        clockCheckBool = true;
                        DateTime now = DateTime.now();
                        checkInFormattedTime = DateFormat('h:mm a').format(now);
                        checkInFormattedTimeTopR = DateFormat('h:mm').format(now);
                        _saveClockState(
                            clockCheckedIn, 1, checkInFormattedTime.toString());

                        if (duration?.isNotEmpty ?? false) {
                          String durationString = duration.toString();

                          try {
                            List<String> parts = durationString.split(':');
                            if (parts.length == 3) {
                              int hours = int.parse(parts[0]);
                              int minutes = int.parse(parts[1]);
                              int seconds = int.parse(parts[2]);
                              Duration initialElapsedTime = Duration(
                                  hours: hours, minutes: minutes, seconds: seconds);
                              stopwatchManager.startStopwatch(
                                  initialTime: initialElapsedTime);
                            }
                          } catch (e) {}
                        } else {}

                        swipeDirection = 'Swipe to Check-out';
                      });
                    } else {
                      String errorMessage = getErrorMessage(response_geofence.body);
                      showCheckInFailedDialog(context, errorMessage);
                    }
                  }
                }
              }
              else {
                if (details.delta.dx.abs() > details.delta.dy.abs() &&
                    details.delta.dx.abs() > 10) {
                  _isProcessingDrag = true;
                  if (details.delta.dx < 0) {
                    setState(() {
                      postCheckout();
                      isCheckIn = false;
                      clockCheckedIn = false;
                      stopwatchManager.stopStopwatch();
                      storeCheckoutTime();
                      Duration initialElapsedTime = stopwatchManager.elapsed;
                      workingTime = formatDuration(initialElapsedTime);
                      clockCheckBool = false;
                      DateTime now = DateTime.now();
                      checkOutFormattedTime = DateFormat('h:mm a').format(now);
                      swipeDirection = 'Swipe to Check-In';
                      _saveClockState(
                          clockCheckedIn, 2, checkOutFormattedTime.toString());
                    });
                  } else if (details.delta.dx > 0) {
                    setState(() {
                      postCheckIn();
                      isCheckIn = true;
                      clockCheckedIn = true;
                      clockCheckBool = true;
                      DateTime now = DateTime.now();
                      checkInFormattedTime = DateFormat('h:mm a').format(now);
                      checkInFormattedTimeTopR = DateFormat('h:mm').format(now);
                      _saveClockState(
                          clockCheckedIn, 1, checkInFormattedTime.toString());

                      if (duration?.isNotEmpty ?? false) {
                        String durationString = duration.toString();

                        try {
                          List<String> parts = durationString.split(':');
                          if (parts.length == 3) {
                            int hours = int.parse(parts[0]);
                            int minutes = int.parse(parts[1]);
                            int seconds = int.parse(parts[2]);
                            Duration initialElapsedTime = Duration(
                                hours: hours, minutes: minutes, seconds: seconds);
                            stopwatchManager.startStopwatch(
                                initialTime: initialElapsedTime);
                          }
                        } catch (e) {}
                      } else {}

                      swipeDirection = 'Swipe to Check-out';
                    });
                  }
                }
              }
            }
          },
          onPanEnd: (details) {
            _isProcessingDrag = false;
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.95,
              height: MediaQuery.of(context).size.height * 0.07,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                color: clockCheckedIn ? Colors.red : Colors.green,
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Show forward arrow only when NOT checked in
                  if (!clockCheckedIn)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.12,
                        height: MediaQuery.of(context).size.height * 0.06,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10.0), color: Colors.white),
                        child: const Icon(Icons.arrow_forward, color: Colors.green, size: 30.0),
                      ),
                    ),

                  Expanded(
                    child: Center(
                      child: Text(
                        swipeDirection,
                        style: const TextStyle(color: Colors.white, fontSize: 15.0, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  // Show backward arrow only when checked in
                  if (clockCheckedIn)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.12,
                        height: MediaQuery.of(context).size.height * 0.06,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10.0), color: Colors.white),
                        child: const Icon(Icons.arrow_back, color: Colors.red, size: 30.0),
                      ),
                    )
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
}

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => Navigator.pushNamed(context, '/home'));
    return Container(color: Colors.white, child: const Center(child: Text('Page 1')));
  }
}

class Overview extends StatelessWidget {
  const Overview({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(color: Colors.white, child: const Center(child: Text('Page 2')));
  }
}

class User extends StatelessWidget {
  const User({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => Navigator.pushNamed(context, '/user'));
    return Container(color: Colors.white, child: const Center(child: Text('Page 1')));
  }
}
