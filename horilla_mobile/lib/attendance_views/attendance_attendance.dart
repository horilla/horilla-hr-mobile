import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../res/consts/app_colors.dart';

class AttendanceAttendance extends StatefulWidget {
  const AttendanceAttendance({super.key});

  @override
  _AttendanceAttendance createState() => _AttendanceAttendance();
}

class _AttendanceAttendance extends State<AttendanceAttendance>
    with SingleTickerProviderStateMixin {
  late Map<String, dynamic> arguments;
  late String baseUrl = '';
  TextEditingController workedHoursController = TextEditingController();
  TextEditingController minimumHourController = TextEditingController();
  TextEditingController checkInHoursController = TextEditingController();
  TextEditingController checkoutHoursController = TextEditingController();
  TextEditingController checkOutDateController = TextEditingController();
  TextEditingController attendanceDateController = TextEditingController();
  TextEditingController checkInDateController = TextEditingController();
  TextEditingController dateInput = TextEditingController();
  TextEditingController checkInTime = TextEditingController();
  TextEditingController checkOutTime = TextEditingController();
  TextEditingController dateInputOvertime = TextEditingController();
  TextEditingController checkInTimeOvertime = TextEditingController();
  TextEditingController checkOutTimeOvertime = TextEditingController();
  TextEditingController dateInputValidated = TextEditingController();
  TextEditingController checkInTimeValidated = TextEditingController();
  TextEditingController checkOutTimeValidated = TextEditingController();
  List<Map<String, dynamic>> requestsNonValidAttendance = [];
  List<Map<String, dynamic>> requestsMyAttendance = [];
  List<Map<String, dynamic>> requestsOvertimeAttendance = [];
  List<Map<String, dynamic>> requestsValidatedAttendance = [];
  List<Map<String, dynamic>> requestsShiftNames = [];
  List<Map<String, dynamic>> filteredNonValidAttendance = [];
  List<Map<String, dynamic>> filteredMyAttendance = [];

  List<Map<String, dynamic>> filteredOvertimeAttendance = [];
  List<Map<String, dynamic>> filteredValidatedAttendance = [];
  List<String> shiftDetails = [];
  String searchText = '';
  String? _errorMessage;
  String workHoursSpent = '';
  String editWorkHoursSpent = '';
  String minimumHoursSpent = '';
  String editMinimumHoursSpent = '';
  String checkInHoursSpent = '';
  String editCheckInHoursSpent = '';
  String editCheckOutHoursSpent = '';
  String checkOutHoursSpent = '';
  String? createEmployee;
  String? createShift;
  String? editShift;
  String? selectedEmployeeId;
  String? selectedEditEmployeeId;
  String? selectedShiftId;
  String? selectedEditShiftId;
  String? editEmployee;
  var employeeItems = [''];
  var shiftItems = [''];
  int maxCount = 5;
  final List<Widget> bottomBarPages = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  final _controller = NotchBottomBarController(index: -1);
  final TextEditingController _typeAheadController = TextEditingController();
  final TextEditingController _typeAheadCreateController =
  TextEditingController();
  final TextEditingController _typeAheadCreateShiftController =
  TextEditingController();
  bool _validateEmployee = false;
  bool _validateDate = false;
  bool _editValidateDate = false;
  bool _validateShift = false;
  bool _validateCheckInDate = false;
  bool _validateCheckIn = false;
  bool showDeleteMessage = false;
  bool _validateCheckOutDate = false;
  bool _validateWorkingHours = false;
  bool _validateMinimumHours = false;
  bool _validateCheckOut = false;
  bool permissionCheck = false;
  bool managerCheck = false;
  bool attendanceTypeCheck = false;
  bool isAction = true;
  bool createAttendance = false;
  bool isSaveClick = true;
  bool isLoading = true;
  bool permissionOverview = true;
  bool permissionAttendance = false;
  bool permissionAttendanceRequest = false;
  bool permissionHourAccount = false;
  Map<String, String> employeeIdMap = {};
  Map<String, String> shiftIdMap = {};
  int currentPage = 1;
  int toValidate = 0;
  int myAttendances = 0;
  int overtime = 0;
  int validated = 0;
  Timer? _debounce;
  bool isFetchingMore = false;
  bool hasMoreMyAttendance = true;
  bool hasMoreNonValidated = true;
  bool hasMoreOvertime = true;
  bool hasMoreValidated = true;


  bool _permissionOverview = false;
  bool _permissionAttendance = false;
  bool _permissionAttendanceRequest = false;
  bool _permissionHourAccount = false;
  bool _permissionsLoaded = false;
  late String getToken = '';


  @override
  void initState() {
    super.initState();
    currentPage = 1;
    prefetchData();
    _simulateLoading();
    _scrollController.addListener(_scrollListener);
    getMyAttendance(reset: true);
    getAllNonValidatedAttendance(reset: true);
    getAllOvertimeAttendance(reset: true);
    getAllValidatedAttendance(reset: true);
    getEmployees();
    getShiftDetails();
    attendanceTypeChecks();
    managerChecks();
    getBaseUrl();
    fetchToken();
    loadPermissionsFromStorage();

    // Load permissions once
    permissionChecks().then((_) {
      setState(() {
        _permissionsLoaded = true;
      });
    });

    // Initialize controllers
    dateInput.text = "";
    checkInTime.text = "";
    checkOutTime.text = "";
    dateInputOvertime.text = "";
    checkInTimeOvertime.text = "";
    checkOutTimeOvertime.text = "";
    dateInputValidated.text = "";
    checkInTimeValidated.text = "";
    checkOutTimeValidated.text = "";
  }

  Future<void> _simulateLoading() async {
    await Future.delayed(const Duration(seconds: 5));
    setState(() {});
  }

  Future loadPermissionsFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _permissionOverview = prefs.getBool("perm_overview") ?? false;
      _permissionAttendance = prefs.getBool("perm_attendance") ?? false;
      _permissionAttendanceRequest = prefs.getBool("perm_attendance_request") ?? false;
      _permissionHourAccount = prefs.getBool("perm_hour_account") ?? false;
      _permissionsLoaded = true;
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    var typedServerUrl = prefs.getString("typed_url");
    setState(() {
      baseUrl = typedServerUrl ?? '';
    });
  }

  Future<void> fetchToken() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    setState(() {
      getToken = token ?? '';
      print('token: $getToken');
    });
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100 &&
        !isFetchingMore) {
      setState(() => isFetchingMore = true);
      currentPage++;
      Future.wait([
        getMyAttendance(),
        getAllNonValidatedAttendance(),
        getAllOvertimeAttendance(),
        getAllValidatedAttendance()
      ]).then((_) {
        setState(() => isFetchingMore = false);
      });
    }
  }

  void showCreateAnimation() {
    String jsonContent = '''
{
  "imagePath": "Assets/gif22.gif"
}
''';
    Map<String, dynamic> jsonData = json.decode(jsonContent);
    String imagePath = jsonData['imagePath'];

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.3,
            width: MediaQuery.of(context).size.width * 0.85,
            child: SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(imagePath),
                    const SizedBox(height: 16),
                    Text(
                      "Attendance Created Successfully",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: redColor),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop();
    });
  }

  void showUpdateAnimation() {
    String jsonContent = '''
{
  "imagePath": "Assets/gif22.gif"
}
''';
    Map<String, dynamic> jsonData = json.decode(jsonContent);
    String imagePath = jsonData['imagePath'];

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.3,
            width: MediaQuery.of(context).size.width * 0.85,
            child: SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(imagePath),
                    const SizedBox(height: 16),
                    Text(
                      "Attendance Updated Successfully",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: redColor),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop();
    });
  }

  void showDeleteAnimation() {
    String jsonContent = '''
{
  "imagePath": "Assets/gif22.gif"
}
''';
    Map<String, dynamic> jsonData = json.decode(jsonContent);
    String imagePath = jsonData['imagePath'];

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.3,
            width: MediaQuery.of(context).size.width * 0.85,
            child: SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(imagePath),
                    const SizedBox(height: 16),
                    Text(
                      "Attendance Deleted Successfully",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: redColor),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop();
    });
  }

  void showValidateAnimation() {
    String jsonContent = '''
{
  "imagePath": "Assets/gif22.gif"
}
''';
    Map<String, dynamic> jsonData = json.decode(jsonContent);
    String imagePath = jsonData['imagePath'];

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.3,
            width: MediaQuery.of(context).size.width * 0.85,
            child: SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(imagePath),
                    const SizedBox(height: 16),
                    Text(
                      "Attendance Validated Successfully",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: redColor),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop();
    });
  }


  Future getMyAttendance({bool reset = false}) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");

    if (reset) {
      currentPage = 1;
      requestsMyAttendance.clear();
      hasMoreMyAttendance = true;
    }
    if (!hasMoreMyAttendance) return; // 🚫 No more data, skip

    var uri = Uri.parse(
        '$typedServerUrl/api/attendance/my-attendance?page=$currentPage&search=$searchText');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token"
    });

    if (response.statusCode == 200) {
      final results = List<Map<String, dynamic>>.from(
          jsonDecode(response.body)['results'] ?? []);

      setState(() {
        requestsMyAttendance.addAll(results);
        requestsMyAttendance = requestsMyAttendance
            .map((m) => jsonEncode(m))
            .toSet()
            .map((s) => jsonDecode(s) as Map<String, dynamic>)
            .toList();
        myAttendances = jsonDecode(response.body)['count'] ?? 0;
        filteredMyAttendance = filterMyAttendance(searchText);
        isLoading = false;
      });
    }
    else if (response.statusCode == 404) {
      hasMoreMyAttendance = false;
      return;
    }
  }

  Future getAllNonValidatedAttendance({bool reset = false}) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");

    if (reset) {
      currentPage = 1;
      requestsNonValidAttendance.clear();
      hasMoreNonValidated = true;
    }
    if (!hasMoreNonValidated) return;



    var uri = Uri.parse(
        '$typedServerUrl/api/attendance/attendance/list/non-validated?page=$currentPage&search=$searchText');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token"
    });

    if (response.statusCode == 200) {
      final results = List<Map<String, dynamic>>.from(
          jsonDecode(response.body)['results'] ?? []);


      setState(() {
        requestsNonValidAttendance.addAll(results);
        requestsNonValidAttendance = requestsNonValidAttendance
            .map((m) => jsonEncode(m))
            .toSet()
            .map((s) => jsonDecode(s) as Map<String, dynamic>)
            .toList();
        toValidate = jsonDecode(response.body)['count'] ?? 0;
        filteredNonValidAttendance = filterNonValidAttendance(searchText);
        isLoading = false;
      });
    }
    else if (response.statusCode == 404) {
      hasMoreNonValidated = false;
      return;
    }
  }

  Future getAllOvertimeAttendance({bool reset = false}) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");

    if (reset) {
      currentPage = 1;
      requestsOvertimeAttendance.clear();
      hasMoreOvertime = true;
    }
    if (!hasMoreOvertime) return;

    var uri = Uri.parse(
        '$typedServerUrl/api/attendance/attendance/list/ot?page=$currentPage&search=$searchText');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token"
    });

    if (response.statusCode == 200) {
      final results = List<Map<String, dynamic>>.from(
          jsonDecode(response.body)['results'] ?? []);

      setState(() {
        requestsOvertimeAttendance.addAll(results);
        requestsOvertimeAttendance = requestsOvertimeAttendance
            .map((m) => jsonEncode(m))
            .toSet()
            .map((s) => jsonDecode(s) as Map<String, dynamic>)
            .toList();
        overtime = jsonDecode(response.body)['count'] ?? 0;
        filteredOvertimeAttendance = filterOvertimeAttendance(searchText);
        isLoading = false;
      });
    }
    else if (response.statusCode == 404) {
      hasMoreOvertime = false;
      return;
    }
  }

  Future getAllValidatedAttendance({bool reset = false}) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");

    if (reset) {
      currentPage = 1;
      requestsValidatedAttendance.clear();
      hasMoreValidated = true;
    }
    if (!hasMoreValidated) return;
    print('current page: $currentPage');


    var uri = Uri.parse(
        '$typedServerUrl/api/attendance/attendance/list/validated?page=$currentPage&search=$searchText');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token"
    });

    if (response.statusCode == 200) {
      final results = List<Map<String, dynamic>>.from(
          jsonDecode(response.body)['results'] ?? []);

      setState(() {
        requestsValidatedAttendance.addAll(results);
        requestsValidatedAttendance = requestsValidatedAttendance
            .map((m) => jsonEncode(m))
            .toSet()
            .map((s) => jsonDecode(s) as Map<String, dynamic>)
            .toList();
        validated = jsonDecode(response.body)['count'] ?? 0;
        filteredValidatedAttendance = filterValidateRecords(searchText);
        isLoading = false;
      });
    }
    else if (response.statusCode == 404) {
      hasMoreValidated = false;
      return;
    }
  }


  List<Map<String, dynamic>> filterNonValidAttendance(String searchText) {
    if (searchText.isEmpty) {
      return requestsNonValidAttendance;
    } else {
      return requestsNonValidAttendance.where((record) {
        final firstName = record['employee_first_name']?.toString() ?? '';
        final lastName = record['employee_last_name']?.toString() ?? '';
        final fullName = (firstName + ' ' + lastName).toLowerCase();
        return fullName.contains(searchText.toLowerCase());
      }).toList();
    }
  }

  List<Map<String, dynamic>> filterMyAttendance(String searchText) {
    if (searchText.isEmpty) {
      return requestsMyAttendance;
    } else {
      return requestsMyAttendance.where((record) {
        final firstName = record['employee_first_name']?.toString() ?? '';
        final lastName = record['employee_last_name']?.toString() ?? '';
        final fullName = (firstName + ' ' + lastName).toLowerCase();
        return fullName.contains(searchText.toLowerCase());
      }).toList();
    }
  }

  List<Map<String, dynamic>> filterOvertimeAttendance(String searchText) {
    if (searchText.isEmpty) {
      return requestsOvertimeAttendance;
    } else {
      return requestsOvertimeAttendance.where((record) {
        final firstName = record['employee_first_name']?.toString() ?? '';
        final lastName = record['employee_last_name']?.toString() ?? '';
        final fullName = (firstName + ' ' + lastName).toLowerCase();
        return fullName.contains(searchText.toLowerCase());
      }).toList();
    }
  }

  List<Map<String, dynamic>> filterValidateRecords(String searchText) {
    if (searchText.isEmpty) {
      return requestsValidatedAttendance;
    } else {
      return requestsValidatedAttendance.where((record) {
        final firstName = record['employee_first_name']?.toString() ?? '';
        final lastName = record['employee_last_name']?.toString() ?? '';
        final fullName = (firstName + ' ' + lastName).toLowerCase();
        return fullName.contains(searchText.toLowerCase());
      }).toList();
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

  Future permissionChecks() async {
    if (_permissionsLoaded) return;

    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");

    try {
      var uri = Uri.parse('$typedServerUrl/api/attendance/permission-check/attendance');
      var response = await http.get(uri, headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });

      if (response.statusCode == 200) {
        setState(() {
          _permissionOverview = true;   // ✅ Allowed
          _permissionAttendance = true;
          _permissionAttendanceRequest = true;
          _permissionHourAccount = true;
          _permissionsLoaded = true;
        });
      } else {
        setState(() {
          _permissionOverview = false;
          _permissionAttendance = true;
          _permissionAttendanceRequest = true;
          _permissionHourAccount = true;
          _permissionsLoaded = true;
        });
      }

      // Save to local storage
      await prefs.setBool("perm_overview", _permissionOverview);
      await prefs.setBool("perm_attendance", _permissionAttendance);
      await prefs.setBool("perm_attendance_request", _permissionAttendanceRequest);
      await prefs.setBool("perm_hour_account", _permissionHourAccount);

    } catch (e) {
      debugPrint('Error checking permissions: $e');
      // On error, maybe hide Overview
      setState(() {
        _permissionOverview = false;
        _permissionAttendance = true;
        _permissionAttendanceRequest = true;
        _permissionHourAccount = true;
        _permissionsLoaded = true;
      });
    }
  }


  void managerChecks() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/employee/manager-check/');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      managerCheck = true;
    }
  }

  void attendanceTypeChecks() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/attendance/attendance-type-check/');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      print(response.body);
      attendanceTypeCheck = true;
    }
  }

  Future<void> getShiftDetails() async {
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
        for (var rec in jsonDecode(response.body)) {
          String shift = "${rec['employee_shift']}";
          String employeeId = "${rec['id']}";
          shiftDetails.add(rec['employee_shift']);
          shiftIdMap[shift] = employeeId;
        }
      });
    }
  }

  Future<void> getEmployees() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");

    employeeItems.clear();
    employeeIdMap.clear();

    for (var page = 1;; page++) {
      print('Fetching employee page: $page');
      var uri = Uri.parse('$typedServerUrl/api/employee/employee-selector?page=$page');
      var response = await http.get(uri, headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'];

        // ✅ Break when no more employees are returned
        if (results.isEmpty) break;

        setState(() {
          for (var employee in results) {
            final firstName = employee['employee_first_name'] ?? '';
            final lastName = employee['employee_last_name'] ?? '';
            final fullName = '$firstName $lastName'.trim();
            final employeeId = "${employee['id']}";
            employeeItems.add(fullName);
            employeeIdMap[fullName] = employeeId;
          }
        });
      } else {
        print("Error fetching employees: ${response.statusCode}");
        break;
      }
    }
  }

  Future<void> createNewAttendance(Map<String, dynamic> createdDetails) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/attendance/attendance/');
    String employeeIdString = createdDetails['employee_id'];
    employeeIdString.split(',');
    var response = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "employee_id": createdDetails['employee_id'],
        "attendance_date": createdDetails['attendance_date'],
        "shift_id": createdDetails['shift_id'],
        "attendance_clock_in_date": createdDetails['attendance_clock_in_date'],
        "attendance_clock_in": createdDetails['attendance_clock_in'],
        "attendance_clock_out_date":
        createdDetails['attendance_clock_out_date'],
        "attendance_clock_out": createdDetails['attendance_clock_out'],
        "attendance_worked_hour": createdDetails['attendance_worked_hour'],
        "minimum_hour": createdDetails['minimum_hour'],
      }),
    );

    if (response.statusCode == 200) {
      isSaveClick = false;
      _errorMessage = null;
      createAttendance = true;
      currentPage = 0;
      getMyAttendance();
      getAllNonValidatedAttendance();
      getAllOvertimeAttendance();
      getAllValidatedAttendance();
      setState(() {});
    } else {
      isSaveClick = true;
      var responseData = jsonDecode(response.body);
      if (responseData.containsKey('non_field_errors')) {
        _errorMessage = responseData['non_field_errors'].join('\n');
        setState(() {});
      }
      if (responseData.containsKey('attendance_date')) {
        _errorMessage = responseData['attendance_date'].join('\n');
        setState(() {});
      }
      if (responseData.containsKey('attendance_clock_in_date')) {
        _errorMessage = responseData['attendance_clock_in_date'].join('\n');
        setState(() {});
      }
      if (responseData.containsKey('attendance_clock_in')) {
        _errorMessage = responseData['attendance_clock_in'].join('\n');
        setState(() {});
      }
      if (responseData.containsKey('attendance_clock_out_date')) {
        _errorMessage = responseData['attendance_clock_out_date'].join('\n');
        setState(() {});
      }
      if (responseData.containsKey('attendance_clock_out')) {
        _errorMessage = responseData['attendance_clock_out'].join('\n');
        setState(() {});
      }
      if (responseData.containsKey('attendance_worked_hour')) {
        _errorMessage = responseData['attendance_worked_hour'].join('\n');
        setState(() {});
      }
      if (responseData.containsKey('minimum_hour')) {
        _errorMessage = responseData['minimum_hour'].join('\n');
        setState(() {});
      }
      setState(() {});
    }
  }

  Future<void> updateAttendance(Map<String, dynamic> updatedDetails) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    String attendanceId = updatedDetails['id'].toString();
    var uri =
    Uri.parse('$typedServerUrl/api/attendance/attendance/$attendanceId');
    var response = await http.put(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "employee_id": updatedDetails['employee_id'],
        "attendance_date": updatedDetails['attendance_date'],
        "shift_id": updatedDetails['shift_id'],
        "attendance_clock_in_date": updatedDetails['attendance_clock_in_date'],
        "attendance_clock_in": updatedDetails['attendance_clock_in'],
        "attendance_clock_out_date":
        updatedDetails['attendance_clock_out_date'],
        "attendance_clock_out": updatedDetails['attendance_clock_out'],
        "attendance_worked_hour": updatedDetails['attendance_worked_hour'],
        "minimum_hour": updatedDetails['minimum_hour'],
      }),
    );
    if (response.statusCode == 200) {
      isSaveClick = false;
      _errorMessage = null;
      currentPage = 0;
      getMyAttendance();
      getAllNonValidatedAttendance();
      getAllOvertimeAttendance();
      setState(() {});
    } else {
      isSaveClick = true;
      var responseData = jsonDecode(response.body);
      if (responseData.containsKey('non_field_errors')) {
        _errorMessage = responseData['non_field_errors'].join('\n');
        setState(() {});
      }
      if (responseData.containsKey('attendance_date')) {
        _errorMessage = responseData['attendance_date'].join('\n');
        setState(() {});
      }
      if (responseData.containsKey('attendance_clock_in_date')) {
        _errorMessage = responseData['attendance_clock_in_date'].join('\n');
        setState(() {});
      }
      if (responseData.containsKey('attendance_clock_in')) {
        _errorMessage = responseData['attendance_clock_in'].join('\n');
        setState(() {});
      }
      if (responseData.containsKey('attendance_clock_out_date')) {
        _errorMessage = responseData['attendance_clock_out_date'].join('\n');
        setState(() {});
      }
      if (responseData.containsKey('attendance_clock_out')) {
        _errorMessage = responseData['attendance_clock_out'].join('\n');
        setState(() {});
      }
      if (responseData.containsKey('attendance_worked_hour')) {
        _errorMessage = responseData['attendance_worked_hour'].join('\n');
        setState(() {});
      }
      if (responseData.containsKey('minimum_hour')) {
        _errorMessage = responseData['minimum_hour'].join('\n');
        setState(() {});
      }
      setState(() {});
    }
  }

  Future<void> updateOvertimeAttendance(
      Map<String, dynamic> updatedDetails) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    String attendanceId = updatedDetails['id'].toString();
    var uri =
    Uri.parse('$typedServerUrl/api/attendance/attendance/$attendanceId');
    var response = await http.put(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "employee_id": updatedDetails['employee_id'],
        "attendance_date": updatedDetails['attendance_date'],
        "shift_id": updatedDetails['shift_id'],
        "attendance_clock_in_date": updatedDetails['attendance_clock_in_date'],
        "attendance_clock_in": updatedDetails['attendance_clock_in'],
        "attendance_clock_out_date":
        updatedDetails['attendance_clock_out_date'],
        "attendance_clock_out": updatedDetails['attendance_clock_out'],
        "attendance_worked_hour": updatedDetails['attendance_worked_hour'],
        "minimum_hour": updatedDetails['minimum_hour'],
      }),
    );
    if (response.statusCode == 200) {
      isSaveClick = false;
      _errorMessage = null;
      currentPage = 0;
      getAllOvertimeAttendance();
      setState(() {});
    } else {
      isSaveClick = true;
      var responseData = jsonDecode(response.body);
      if (responseData.containsKey('non_field_errors')) {
        _errorMessage = responseData['non_field_errors'].join('\n');
        setState(() {});
      }
      if (responseData.containsKey('attendance_date')) {
        _errorMessage = responseData['attendance_date'].join('\n');
        setState(() {});
      }
      if (responseData.containsKey('attendance_clock_in_date')) {
        _errorMessage = responseData['attendance_clock_in_date'].join('\n');
        setState(() {});
      }
      if (responseData.containsKey('attendance_clock_in')) {
        _errorMessage = responseData['attendance_clock_in'].join('\n');
        setState(() {});
      }
      if (responseData.containsKey('attendance_clock_out_date')) {
        _errorMessage = responseData['attendance_clock_out_date'].join('\n');
        setState(() {});
      }
      if (responseData.containsKey('attendance_clock_out')) {
        _errorMessage = responseData['attendance_clock_out'].join('\n');
        setState(() {});
      }
      if (responseData.containsKey('attendance_worked_hour')) {
        _errorMessage = responseData['attendance_worked_hour'].join('\n');
        setState(() {});
      }
      if (responseData.containsKey('minimum_hour')) {
        _errorMessage = responseData['minimum_hour'].join('\n');
        setState(() {});
      }
      setState(() {});
    }
  }

  Future<void> deleteAttendance(Map<String, dynamic> deletedDetails) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    String attendanceId = deletedDetails['id'].toString();
    var uri =
    Uri.parse('$typedServerUrl/api/attendance/attendance/$attendanceId');
    var response = await http.delete(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      isSaveClick = false;
      currentPage = 0;
      getAllOvertimeAttendance();
      setState(() {});
    }
    else {
      isSaveClick = true;
    }
  }

  Future<void> deleteNonValidatedAttendance(
      Map<String, dynamic> deletedDetails) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    String attendanceId = deletedDetails['id'].toString();
    var uri =
    Uri.parse('$typedServerUrl/api/attendance/attendance/$attendanceId');
    var response = await http.delete(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      isSaveClick = false;
      currentPage = 0;
      getMyAttendance();
      getAllNonValidatedAttendance();
      setState(() {});
      showDeleteAnimation();
    }
    else {
      isSaveClick = true;
    }
  }

  Future<void> validateAttendance(Map<String, dynamic> deletedDetails) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    String attendanceId = deletedDetails['id'].toString();
    var uri = Uri.parse(
        '$typedServerUrl/api/attendance/attendance-validate/$attendanceId');
    var response = await http.put(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      isSaveClick = false;
      currentPage = 0;
      getAllNonValidatedAttendance();
      setState(() {});
    }
    else {
      isSaveClick = true;
    }
  }

  Future<void> validateOverTime(Map<String, dynamic> deletedDetails) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    String attendanceId = deletedDetails['id'].toString();
    var uri = Uri.parse(
        '$typedServerUrl/api/attendance/overtime-approve/$attendanceId');
    var response = await http.put(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      isSaveClick = false;
      currentPage = 0;
      getAllOvertimeAttendance();
      setState(() {});
    }
    else {
      isSaveClick = true;
    }
  }

  Future<String?> showCustomDatePicker(
      BuildContext context, DateTime initialDate) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: infoColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      return "${selectedDate.year}-${selectedDate.month}-${selectedDate.day}";
    }
    return null;
  }

  void _showValidateAttendance(
      BuildContext context, Map<String, dynamic> record) {
    TextEditingController editCheckInDateController =
    TextEditingController(text: record['attendance_clock_in_date']);
    TextEditingController editCheckInHoursController =
    TextEditingController(text: record['attendance_clock_in']);
    TextEditingController editCheckOutDateController =
    TextEditingController(text: record['attendance_clock_out_date']);
    TextEditingController editCheckOutHoursController =
    TextEditingController(text: record['attendance_clock_out']);
    TextEditingController editWorkedHoursController =
    TextEditingController(text: record['attendance_worked_hour']);
    TextEditingController editMinimumHourController =
    TextEditingController(text: record['minimum_hour']);
    TextEditingController editAttendanceDateController =
    TextEditingController(text: record['attendance_date']);
    TextEditingController typeAheadEditShiftController =
    TextEditingController(text: record['shift_name']);
    _typeAheadController.text = (record['employee_first_name'] ?? "") +
        " " +
        (record['employee_last_name'] ?? "");
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Stack(
              children: [
                AlertDialog(
                  backgroundColor: whiteColor,
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Edit Attendance",
                        style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            color: blackColor),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                  content: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.95,
                    height: MediaQuery.of(context).size.height * 0.50,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                _errorMessage ?? '',
                                style: TextStyle(
                                    color: redColor,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.03),
                          Text(
                            'Employee',
                            style: TextStyle(color: blackColor),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          TypeAheadField<String>(
                            textFieldConfiguration: TextFieldConfiguration(
                              controller: _typeAheadController,
                              decoration: InputDecoration(
                                labelText: 'Search Employee',
                                labelStyle: TextStyle(color: labelTextColor),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10.0),
                                border: const OutlineInputBorder(),
                              ),
                            ),
                            suggestionsCallback: (pattern) {
                              return employeeItems
                                  .where((item) => item
                                  .toLowerCase()
                                  .contains(pattern.toLowerCase()))
                                  .toList();
                            },
                            itemBuilder: (context, String suggestion) {
                              return ListTile(
                                title: Text(suggestion),
                              );
                            },
                            onSuggestionSelected: (String suggestion) {
                              setState(() {
                                editEmployee = suggestion;
                                selectedEditEmployeeId =
                                employeeIdMap[suggestion];
                                _validateEmployee = false;
                              });
                              _typeAheadController.text = suggestion;
                            },
                            noItemsFoundBuilder: (context) => const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'No Employees Found',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                            errorBuilder: (context, error) => Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Error: $error',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            hideOnEmpty: true,
                            hideOnError: false,
                            suggestionsBoxDecoration: SuggestionsBoxDecoration(
                              constraints: BoxConstraints(
                                  maxHeight: MediaQuery.of(context).size.height * 0.23), // Limit height
                            ),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.03),
                          Text(
                            "Attendance Date",
                            style: TextStyle(color: blackColor),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          TextField(
                            readOnly: true,
                            controller: editAttendanceDateController,
                            onTap: () async {
                              final selectedDate = await showCustomDatePicker(
                                  context, DateTime.now());
                              if (selectedDate != null) {
                                DateTime parsedDate = DateFormat('yyyy-MM-dd')
                                    .parse(selectedDate);
                                setState(() {
                                  editAttendanceDateController.text =
                                      DateFormat('yyyy-MM-dd')
                                          .format(parsedDate);
                                  _editValidateDate = false;
                                });
                              }
                            },
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              errorText: _editValidateDate
                                  ? 'Please select a Attendance date'
                                  : null,
                              contentPadding:
                              const EdgeInsets.symmetric(horizontal: 10.0),
                            ),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.03),
                          Text(
                            "Shift",
                            style: TextStyle(color: blackColor),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          TypeAheadField<String>(
                            textFieldConfiguration: TextFieldConfiguration(
                              controller: typeAheadEditShiftController,
                              decoration: InputDecoration(
                                labelText: 'Search Shift',
                                labelStyle: TextStyle(color: labelTextColor),
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10.0),
                              ),
                            ),
                            suggestionsCallback: (pattern) {
                              return shiftDetails
                                  .where((item) => item
                                  .toLowerCase()
                                  .contains(pattern.toLowerCase()))
                                  .toList();
                            },
                            itemBuilder: (context, String suggestion) {
                              return ListTile(
                                title: Text(suggestion),
                              );
                            },
                            onSuggestionSelected: (String suggestion) {
                              setState(() {
                                editShift = suggestion;
                                selectedEditShiftId = shiftIdMap[suggestion];
                              });
                              typeAheadEditShiftController.text = suggestion;
                            },
                            noItemsFoundBuilder: (context) => const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'No Shift Found',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                            errorBuilder: (context, error) => Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Error: $error',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            hideOnEmpty: true,
                            hideOnError: false,
                            suggestionsBoxDecoration: SuggestionsBoxDecoration(
                              constraints: BoxConstraints(
                                  maxHeight: MediaQuery.of(context).size.height * 0.23), // Limit height
                            ),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.03),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Check-In Date',
                                      style: TextStyle(color: blackColor),
                                    ),
                                    SizedBox(
                                        height:
                                        MediaQuery.of(context).size.height *
                                            0.01),
                                    TextField(
                                      readOnly: true,
                                      controller: editCheckInDateController,
                                      onTap: () async {
                                        final selectedDate =
                                        await showCustomDatePicker(
                                            context, DateTime.now());
                                        if (selectedDate != null) {
                                          DateTime parsedDate =
                                          DateFormat('yyyy-MM-dd')
                                              .parse(selectedDate);
                                          setState(() {
                                            editCheckInDateController.text =
                                                DateFormat('yyyy-MM-dd')
                                                    .format(parsedDate);
                                          });
                                        }
                                      },
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 10.0),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                  width:
                                  MediaQuery.of(context).size.width * 0.03),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Check-In',
                                      style: TextStyle(color: blackColor),
                                    ),
                                    SizedBox(
                                        height:
                                        MediaQuery.of(context).size.height *
                                            0.01),
                                    TextField(
                                      controller: editCheckInHoursController,
                                      keyboardType: TextInputType.datetime,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(4),
                                        _TimeInputFormatter(),
                                      ],
                                      onChanged: (valueTime) {
                                        editCheckInHoursSpent = valueTime;
                                      },
                                      decoration: InputDecoration(
                                        border: const OutlineInputBorder(),
                                        contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 10.0),
                                        prefixIcon: IconButton(
                                          icon: const Icon(Icons.access_time),
                                          onPressed: () async {
                                            final TimeOfDay? picked =
                                            await showTimePicker(
                                              context: context,
                                              initialTime: TimeOfDay.now(),
                                            );
                                            if (picked != null) {
                                              editCheckInHoursController.text =
                                              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                              editCheckInHoursSpent =
                                              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.03),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Check-Out Date',
                                      style: TextStyle(color: blackColor),
                                    ),
                                    SizedBox(
                                        height:
                                        MediaQuery.of(context).size.height *
                                            0.01),
                                    TextField(
                                      readOnly: true,
                                      controller: editCheckOutDateController,
                                      onTap: () async {
                                        final selectedDate =
                                        await showCustomDatePicker(
                                            context, DateTime.now());
                                        if (selectedDate != null) {
                                          DateTime parsedDate =
                                          DateFormat('yyyy-MM-dd')
                                              .parse(selectedDate);
                                          setState(() {
                                            editCheckOutDateController.text =
                                                DateFormat('yyyy-MM-dd')
                                                    .format(parsedDate);
                                          });
                                        }
                                      },
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 10.0),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                  width:
                                  MediaQuery.of(context).size.width * 0.03),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Check-Out',
                                      style: TextStyle(color: blackColor),
                                    ),
                                    SizedBox(
                                        height:
                                        MediaQuery.of(context).size.height *
                                            0.01),
                                    TextField(
                                      controller: editCheckOutHoursController,
                                      keyboardType: TextInputType.datetime,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(4),
                                        _TimeInputFormatter(),
                                      ],
                                      onChanged: (valueTime) {
                                        editCheckOutHoursSpent = valueTime;
                                      },
                                      decoration: InputDecoration(
                                        border: const OutlineInputBorder(),
                                        contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 10.0),
                                        prefixIcon: IconButton(
                                          icon: const Icon(Icons.access_time),
                                          onPressed: () async {
                                            final TimeOfDay? picked =
                                            await showTimePicker(
                                              context: context,
                                              initialTime: TimeOfDay.now(),
                                            );
                                            if (picked != null) {
                                              editCheckOutHoursController.text =
                                              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                              editCheckOutHoursSpent =
                                              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.03),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Working Hours',
                                      style: TextStyle(color: blackColor),
                                    ),
                                    SizedBox(
                                        height:
                                        MediaQuery.of(context).size.height *
                                            0.01),
                                    TextField(
                                      controller: editWorkedHoursController,
                                      keyboardType: TextInputType.datetime,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(4),
                                        _TimeInputFormatter(),
                                      ],
                                      onChanged: (valueTime) {
                                        editWorkHoursSpent = valueTime;
                                      },
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 10.0),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                  width:
                                  MediaQuery.of(context).size.width * 0.03),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Minimum Hour',
                                      style: TextStyle(color: blackColor),
                                    ),
                                    SizedBox(
                                        height:
                                        MediaQuery.of(context).size.height *
                                            0.01),
                                    TextField(
                                      controller: editMinimumHourController,
                                      keyboardType: TextInputType.datetime,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(4),
                                        _TimeInputFormatter(),
                                      ],
                                      onChanged: (valueTime) {
                                        editMinimumHoursSpent = valueTime;
                                      },
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 10.0),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: <Widget>[
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () async {
                          if (isSaveClick == true) {
                            isSaveClick = false;
                            setState(() {
                              _errorMessage = null;
                            });
                            if (editAttendanceDateController.text.isEmpty) {
                              setState(() {
                                isSaveClick = true;
                                _editValidateDate = true;
                                Navigator.of(context).pop(true);
                                _showValidateAttendance(context, record);
                              });
                            } else {
                              isAction = true;
                              Map<String, dynamic> updatedDetails = {
                                'id': record['id'],
                                "employee_id": selectedEditEmployeeId ??
                                    record['employee_id'].toString(),
                                "attendance_date":
                                editAttendanceDateController.text,
                                'shift_id': selectedEditShiftId ??
                                    record['shift_id'].toString(),
                                'attendance_clock_in_date':
                                editCheckInDateController.text.isEmpty
                                    ? record['attendance_clock_in_date']
                                    : editCheckInDateController.text,
                                'attendance_clock_in':
                                editCheckInHoursSpent.isEmpty
                                    ? record['attendance_clock_in']
                                    : editCheckInHoursSpent,
                                'attendance_clock_out_date':
                                editCheckOutDateController.text.isEmpty
                                    ? record['attendance_clock_out_date']
                                    : editCheckOutDateController.text,
                                'attendance_clock_out':
                                editCheckOutHoursSpent.isEmpty
                                    ? record['attendance_clock_out']
                                    : editCheckOutHoursSpent,
                                'attendance_worked_hour':
                                editWorkHoursSpent.isEmpty
                                    ? record['attendance_worked_hour']
                                    : editWorkHoursSpent,
                                'minimum_hour': editMinimumHoursSpent.isEmpty
                                    ? record['minimum_hour']
                                    : editMinimumHoursSpent,
                              };
                              await updateAttendance(updatedDetails);
                              setState(() {
                                isAction = false;
                              });
                              if (_errorMessage == null ||
                                  _errorMessage!.isEmpty) {
                                Navigator.of(context).pop(true);
                                showUpdateAnimation();
                              } else {
                                Navigator.of(context).pop(true);
                                _showValidateAttendance(context, record);
                              }
                            }
                          }
                        },
                        style: ButtonStyle(
                          backgroundColor:
                          MaterialStateProperty.all<Color>(redColor),
                          shape:
                          MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6.0),
                            ),
                          ),
                        ),
                        child: Text('Save',
                            style: TextStyle(color: whiteColor)),
                      ),
                    ),
                  ],
                ),
                if (isAction)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _showValidateOvertimeAttendance(
      BuildContext context, Map<String, dynamic> record) {
    TextEditingController editCheckInDateController =
    TextEditingController(text: record['attendance_clock_in_date']);
    TextEditingController editCheckInHoursController =
    TextEditingController(text: record['attendance_clock_in']);
    TextEditingController editCheckOutDateController =
    TextEditingController(text: record['attendance_clock_out_date']);
    TextEditingController editCheckOutHoursController =
    TextEditingController(text: record['attendance_clock_out']);
    TextEditingController editWorkedHoursController =
    TextEditingController(text: record['attendance_worked_hour']);
    TextEditingController editMinimumHourController =
    TextEditingController(text: record['minimum_hour']);
    TextEditingController editAttendanceDateController =
    TextEditingController(text: record['attendance_date']);
    TextEditingController typeAheadEditShiftController =
    TextEditingController(text: record['shift_name']);
    _typeAheadController.text = (record['employee_first_name'] ?? "") +
        " " +
        (record['employee_last_name'] ?? "");
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Stack(
              children: [
                AlertDialog(
                  backgroundColor: whiteColor,
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Edit Attendance",
                        style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            color: blackColor),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                  content: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.95,
                    height: MediaQuery.of(context).size.height * 0.50,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                _errorMessage ?? '',
                                style: TextStyle(
                                    color: redColor,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.03),
                          Text(
                            'Employee',
                            style: TextStyle(color: blackColor),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          TypeAheadField<String>(
                            textFieldConfiguration: TextFieldConfiguration(
                              controller: _typeAheadController,
                              decoration: InputDecoration(
                                labelText: 'Search Employee',
                                labelStyle: TextStyle(color: labelTextColor),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10.0),
                                border: const OutlineInputBorder(),
                              ),
                            ),
                            suggestionsCallback: (pattern) {
                              return employeeItems
                                  .where((item) => item
                                  .toLowerCase()
                                  .contains(pattern.toLowerCase()))
                                  .toList();
                            },
                            itemBuilder: (context, String suggestion) {
                              return ListTile(
                                title: Text(suggestion),
                              );
                            },
                            onSuggestionSelected: (String suggestion) {
                              setState(() {
                                editEmployee = suggestion;
                                selectedEditEmployeeId =
                                employeeIdMap[suggestion];
                                _validateEmployee = false;
                              });
                              _typeAheadController.text = suggestion;
                            },
                            noItemsFoundBuilder: (context) => const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'No Employees Found',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                            errorBuilder: (context, error) => Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Error: $error',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            hideOnEmpty: true,
                            hideOnError: false,
                            suggestionsBoxDecoration: SuggestionsBoxDecoration(
                              constraints: BoxConstraints(
                                  maxHeight: MediaQuery.of(context).size.height * 0.23), // Limit height
                            ),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.03),
                          Text(
                            "Attendance Date",
                            style: TextStyle(color: blackColor),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          TextField(
                            readOnly: true,
                            controller: editAttendanceDateController,
                            onTap: () async {
                              final selectedDate = await showCustomDatePicker(
                                  context, DateTime.now());
                              if (selectedDate != null) {
                                DateTime parsedDate = DateFormat('yyyy-MM-dd')
                                    .parse(selectedDate);
                                setState(() {
                                  editAttendanceDateController.text =
                                      DateFormat('yyyy-MM-dd')
                                          .format(parsedDate);
                                  _editValidateDate = false;
                                });
                              }
                            },
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              errorText: _editValidateDate
                                  ? 'Please select a Attendance date'
                                  : null,
                              contentPadding:
                              const EdgeInsets.symmetric(horizontal: 10.0),
                            ),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.03),
                          Text(
                            "Shift",
                            style: TextStyle(color: blackColor),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          TypeAheadField<String>(
                            textFieldConfiguration: TextFieldConfiguration(
                              controller: typeAheadEditShiftController,
                              decoration: InputDecoration(
                                labelText: 'Search Shift',
                                labelStyle: TextStyle(color: labelTextColor),
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10.0),
                              ),
                            ),
                            suggestionsCallback: (pattern) {
                              return shiftDetails
                                  .where((item) => item
                                  .toLowerCase()
                                  .contains(pattern.toLowerCase()))
                                  .toList();
                            },
                            itemBuilder: (context, String suggestion) {
                              return ListTile(
                                title: Text(suggestion),
                              );
                            },
                            onSuggestionSelected: (String suggestion) {
                              setState(() {
                                editShift = suggestion;
                                selectedEditShiftId = shiftIdMap[suggestion];
                              });
                              typeAheadEditShiftController.text = suggestion;
                            },
                            noItemsFoundBuilder: (context) => const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'No Shift Found',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                            errorBuilder: (context, error) => Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Error: $error',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            hideOnEmpty: true,
                            hideOnError: false,
                            suggestionsBoxDecoration: SuggestionsBoxDecoration(
                              constraints: BoxConstraints(
                                  maxHeight: MediaQuery.of(context).size.height * 0.23), // Limit height
                            ),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.03),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Check-In Date',
                                      style: TextStyle(color: blackColor),
                                    ),
                                    SizedBox(
                                        height:
                                        MediaQuery.of(context).size.height *
                                            0.01),
                                    TextField(
                                      readOnly: true,
                                      controller: editCheckInDateController,
                                      onTap: () async {
                                        final selectedDate =
                                        await showCustomDatePicker(
                                            context, DateTime.now());
                                        if (selectedDate != null) {
                                          DateTime parsedDate =
                                          DateFormat('yyyy-MM-dd')
                                              .parse(selectedDate);
                                          setState(() {
                                            editCheckInDateController.text =
                                                DateFormat('yyyy-MM-dd')
                                                    .format(parsedDate);
                                          });
                                        }
                                      },
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 10.0),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                  width:
                                  MediaQuery.of(context).size.width * 0.03),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Check-In',
                                      style: TextStyle(color: blackColor),
                                    ),
                                    SizedBox(
                                        height:
                                        MediaQuery.of(context).size.height *
                                            0.01),
                                    TextField(
                                      controller: editCheckInHoursController,
                                      keyboardType: TextInputType.datetime,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(4),
                                        _TimeInputFormatter(),
                                      ],
                                      onChanged: (valueTime) {
                                        editCheckInHoursSpent = valueTime;
                                      },
                                      decoration: InputDecoration(
                                        border: const OutlineInputBorder(),
                                        contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 10.0),
                                        prefixIcon: IconButton(
                                          icon: const Icon(Icons.access_time),
                                          onPressed: () async {
                                            final TimeOfDay? picked =
                                            await showTimePicker(
                                              context: context,
                                              initialTime: TimeOfDay.now(),
                                            );
                                            if (picked != null) {
                                              editCheckInHoursController.text =
                                              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                              editCheckInHoursSpent =
                                              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.03),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Check-Out Date',
                                      style: TextStyle(color: blackColor),
                                    ),
                                    SizedBox(
                                        height:
                                        MediaQuery.of(context).size.height *
                                            0.01),
                                    TextField(
                                      readOnly: true,
                                      controller: editCheckOutDateController,
                                      onTap: () async {
                                        final selectedDate =
                                        await showCustomDatePicker(
                                            context, DateTime.now());
                                        if (selectedDate != null) {
                                          DateTime parsedDate =
                                          DateFormat('yyyy-MM-dd')
                                              .parse(selectedDate);
                                          setState(() {
                                            editCheckOutDateController.text =
                                                DateFormat('yyyy-MM-dd')
                                                    .format(parsedDate);
                                          });
                                        }
                                      },
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 10.0),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                  width:
                                  MediaQuery.of(context).size.width * 0.03),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Check-Out',
                                      style: TextStyle(color: blackColor),
                                    ),
                                    SizedBox(
                                        height:
                                        MediaQuery.of(context).size.height *
                                            0.01),
                                    TextField(
                                      controller: editCheckOutHoursController,
                                      keyboardType: TextInputType.datetime,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(4),
                                        _TimeInputFormatter(),
                                      ],
                                      onChanged: (valueTime) {
                                        editCheckOutHoursSpent = valueTime;
                                      },
                                      decoration: InputDecoration(
                                        border: const OutlineInputBorder(),
                                        contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 10.0),
                                        prefixIcon: IconButton(
                                          icon: const Icon(Icons.access_time),
                                          onPressed: () async {
                                            final TimeOfDay? picked =
                                            await showTimePicker(
                                              context: context,
                                              initialTime: TimeOfDay.now(),
                                            );
                                            if (picked != null) {
                                              editCheckOutHoursController.text =
                                              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                              editCheckOutHoursSpent =
                                              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.03),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Working Hours',
                                      style: TextStyle(color: blackColor),
                                    ),
                                    SizedBox(
                                        height:
                                        MediaQuery.of(context).size.height *
                                            0.01),
                                    TextField(
                                      controller: editWorkedHoursController,
                                      keyboardType: TextInputType.datetime,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(4),
                                        _TimeInputFormatter(),
                                      ],
                                      onChanged: (valueTime) {
                                        editWorkHoursSpent = valueTime;
                                      },
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 10.0),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                  width:
                                  MediaQuery.of(context).size.width * 0.03),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Minimum Hour',
                                      style: TextStyle(color: blackColor),
                                    ),
                                    SizedBox(
                                        height:
                                        MediaQuery.of(context).size.height *
                                            0.01),
                                    TextField(
                                      controller: editMinimumHourController,
                                      keyboardType: TextInputType.datetime,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(4),
                                        _TimeInputFormatter(),
                                      ],
                                      onChanged: (valueTime) {
                                        editMinimumHoursSpent = valueTime;
                                      },
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 10.0),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: <Widget>[
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () async {
                          if (isSaveClick == true) {
                            isSaveClick = false;
                            setState(() {
                              _errorMessage = null;
                              isAction = true;
                            });
                            if (editAttendanceDateController.text.isEmpty) {
                              setState(() {
                                isSaveClick = true;
                                _editValidateDate = true;
                                Navigator.of(context).pop(true);
                                _showValidateOvertimeAttendance(
                                    context, record);
                              });
                            } else {
                              Map<String, dynamic> updatedDetails = {
                                'id': record['id'],
                                "employee_id": selectedEditEmployeeId ??
                                    record['employee_id'].toString(),
                                "attendance_date":
                                editAttendanceDateController.text,
                                'shift_id': selectedEditShiftId ??
                                    record['shift_id'].toString(),
                                'attendance_clock_in_date':
                                editCheckInDateController.text.isEmpty
                                    ? record['attendance_clock_in_date']
                                    : editCheckInDateController.text,
                                'attendance_clock_in':
                                editCheckInHoursSpent.isEmpty
                                    ? record['attendance_clock_in']
                                    : editCheckInHoursSpent,
                                'attendance_clock_out_date':
                                editCheckOutDateController.text.isEmpty
                                    ? record['attendance_clock_out_date']
                                    : editCheckOutDateController.text,
                                'attendance_clock_out':
                                editCheckOutHoursSpent.isEmpty
                                    ? record['attendance_clock_out']
                                    : editCheckOutHoursSpent,
                                'attendance_worked_hour':
                                editWorkHoursSpent.isEmpty
                                    ? record['attendance_worked_hour']
                                    : editWorkHoursSpent,
                                'minimum_hour': editMinimumHoursSpent.isEmpty
                                    ? record['minimum_hour']
                                    : editMinimumHoursSpent,
                              };
                              await updateOvertimeAttendance(updatedDetails);
                              setState(() {
                                isAction = false;
                              });
                              if (_errorMessage == null ||
                                  _errorMessage!.isEmpty) {
                                Navigator.of(context).pop(true);
                                showUpdateAnimation();
                              } else {
                                Navigator.of(context).pop(true);
                                _showValidateOvertimeAttendance(
                                    context, record);
                              }
                            }
                          }
                        },
                        style: ButtonStyle(
                          backgroundColor:
                          MaterialStateProperty.all<Color>(redColor),
                          shape:
                          MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6.0),
                            ),
                          ),
                        ),
                        child: Text('Save',
                            style: TextStyle(color: whiteColor)),
                      ),
                    ),
                  ],
                ),
                if (isAction)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void showCreateAttendanceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Stack(
              children: [
                AlertDialog(
                  backgroundColor: whiteColor,
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Add Attendance",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: blackColor),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                  content: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    width: MediaQuery.of(context).size.width * 0.95,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                _errorMessage ?? '',
                                style: TextStyle(
                                    color: redColor,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.03),
                          Text(
                            'Employee',
                            style: TextStyle(color: blackColor),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          TypeAheadField<String>(
                            textFieldConfiguration: TextFieldConfiguration(
                              controller: _typeAheadCreateController,
                              decoration: InputDecoration(
                                labelText: 'Search Employee',
                                labelStyle: TextStyle(color: labelTextColor),
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10.0),
                                errorText: _validateEmployee
                                    ? 'Please Select an Employee'
                                    : null,
                              ),
                            ),
                            suggestionsCallback: (pattern) {
                              return employeeItems
                                  .where((item) => item
                                  .toLowerCase()
                                  .contains(pattern.toLowerCase()))
                                  .toList();
                            },
                            itemBuilder: (context, String suggestion) {
                              return ListTile(
                                title: Text(suggestion),
                              );
                            },
                            onSuggestionSelected: (String suggestion) {
                              setState(() {
                                createEmployee = suggestion;
                                selectedEmployeeId = employeeIdMap[suggestion];
                                _validateEmployee = false;
                              });
                              _typeAheadCreateController.text = suggestion;
                            },
                            noItemsFoundBuilder: (context) => const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'No Employees Found',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                            errorBuilder: (context, error) => Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Error: $error',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            hideOnEmpty: true,
                            hideOnError: false,
                            suggestionsBoxDecoration: SuggestionsBoxDecoration(
                              constraints: BoxConstraints(
                                  maxHeight: MediaQuery.of(context).size.height * 0.23), // Limit height
                            ),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.03),
                          Text(
                            "Attendance Date",
                            style: TextStyle(color: blackColor),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          TextField(
                            readOnly: true,
                            controller: attendanceDateController,
                            onTap: () async {
                              final selectedDate = await showCustomDatePicker(
                                  context, DateTime.now());
                              if (selectedDate != null) {
                                DateTime parsedDate = DateFormat('yyyy-MM-dd')
                                    .parse(selectedDate);
                                setState(() {
                                  attendanceDateController.text =
                                      DateFormat('yyyy-MM-dd')
                                          .format(parsedDate);
                                });
                              }
                            },
                            decoration: InputDecoration(
                              labelText: "Attendance Date",
                              labelStyle: TextStyle(color: labelTextColor),
                              border: const OutlineInputBorder(),
                              errorText: _validateDate
                                  ? 'Please select a Attendance date'
                                  : null,
                              contentPadding:
                              const EdgeInsets.symmetric(horizontal: 10.0),
                            ),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.03),
                          Text(
                            "Shift",
                            style: TextStyle(color: blackColor),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          TypeAheadField<String>(
                            textFieldConfiguration: TextFieldConfiguration(
                              controller: _typeAheadCreateShiftController,
                              decoration: InputDecoration(
                                labelText: 'Search Shift',
                                labelStyle: TextStyle(color: labelTextColor),
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10.0),
                                errorText: _validateShift
                                    ? 'Please Select a Shift'
                                    : null,
                              ),
                            ),
                            suggestionsCallback: (pattern) {
                              return shiftDetails
                                  .where((item) => item
                                  .toLowerCase()
                                  .contains(pattern.toLowerCase()))
                                  .toList();
                            },
                            itemBuilder: (context, String suggestion) {
                              return ListTile(
                                title: Text(suggestion),
                              );
                            },
                            onSuggestionSelected: (String suggestion) {
                              setState(() {
                                createShift = suggestion;
                                selectedShiftId = shiftIdMap[suggestion];
                                _validateShift = false;
                              });
                              _typeAheadCreateShiftController.text = suggestion;
                            },
                            noItemsFoundBuilder: (context) => const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'No Shift Found',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                            errorBuilder: (context, error) => Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Error: $error',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            hideOnEmpty: true,
                            hideOnError: false,
                            suggestionsBoxDecoration: SuggestionsBoxDecoration(
                              constraints: BoxConstraints(
                                  maxHeight: MediaQuery.of(context).size.height * 0.23), // Limit height
                            ),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.03),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Check-In Date',
                                      style: TextStyle(color: blackColor),
                                    ),
                                    SizedBox(
                                        height:
                                        MediaQuery.of(context).size.height *
                                            0.01),
                                    TextField(
                                      readOnly: true,
                                      controller: checkInDateController,
                                      onTap: () async {
                                        final selectedDate =
                                        await showCustomDatePicker(
                                            context, DateTime.now());
                                        if (selectedDate != null) {
                                          DateTime parsedDate =
                                          DateFormat('yyyy-MM-dd')
                                              .parse(selectedDate);
                                          setState(() {
                                            checkInDateController.text =
                                                DateFormat('yyyy-MM-dd')
                                                    .format(parsedDate);
                                            _validateCheckInDate = false;
                                          });
                                        }
                                      },
                                      decoration: InputDecoration(
                                        labelText: "Check-In Date",
                                        labelStyle:
                                        TextStyle(color: labelTextColor),
                                        border: const OutlineInputBorder(),
                                        errorText: _validateCheckInDate
                                            ? 'Please Choose Check-In Date'
                                            : null,
                                        contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 10.0),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                  width:
                                  MediaQuery.of(context).size.width * 0.03),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Check-In',
                                      style: TextStyle(color: blackColor),
                                    ),
                                    SizedBox(
                                        height:
                                        MediaQuery.of(context).size.height *
                                            0.01),
                                    TextField(
                                      controller: checkInHoursController,
                                      keyboardType: TextInputType.datetime,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(4),
                                        _TimeInputFormatter(),
                                      ],
                                      onChanged: (valueTime) {
                                        checkInHoursSpent = valueTime;
                                        _validateCheckIn = false;
                                      },
                                      decoration: InputDecoration(
                                        labelText: '00:00',
                                        labelStyle:
                                        TextStyle(color: labelTextColor),
                                        border: const OutlineInputBorder(),
                                        errorText: _validateCheckIn
                                            ? 'Please Choose a Check-In'
                                            : null,
                                        contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 10.0),
                                        prefixIcon: IconButton(
                                          icon: const Icon(Icons.access_time),
                                          onPressed: () async {
                                            final TimeOfDay? picked =
                                            await showTimePicker(
                                              context: context,
                                              initialTime: TimeOfDay.now(),
                                            );
                                            if (picked != null) {
                                              checkInHoursController.text =
                                              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                              checkInHoursSpent =
                                              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                            }
                                            _validateCheckIn = false;
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.03),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Check-Out Date',
                                      style: TextStyle(color: blackColor),
                                    ),
                                    SizedBox(
                                        height:
                                        MediaQuery.of(context).size.height *
                                            0.01),
                                    TextField(
                                      readOnly: true,
                                      controller: checkOutDateController,
                                      onTap: () async {
                                        final selectedDate =
                                        await showCustomDatePicker(
                                            context, DateTime.now());
                                        if (selectedDate != null) {
                                          DateTime parsedDate =
                                          DateFormat('yyyy-MM-dd')
                                              .parse(selectedDate);
                                          setState(() {
                                            checkOutDateController.text =
                                                DateFormat('yyyy-MM-dd')
                                                    .format(parsedDate);
                                            _validateCheckOutDate = false;
                                          });
                                        }
                                      },
                                      decoration: InputDecoration(
                                        labelText: "Check-Out Date",
                                        errorText: _validateCheckOutDate
                                            ? 'Please Choose a Check-Out Date'
                                            : null,
                                        labelStyle:
                                        TextStyle(color: labelTextColor),
                                        border: const OutlineInputBorder(),
                                        contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 10.0),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                  width:
                                  MediaQuery.of(context).size.width * 0.03),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Check-Out',
                                      style: TextStyle(color: blackColor),
                                    ),
                                    SizedBox(
                                        height:
                                        MediaQuery.of(context).size.height *
                                            0.01),
                                    TextField(
                                      controller: checkoutHoursController,
                                      keyboardType: TextInputType.datetime,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(4),
                                        _TimeInputFormatter(),
                                      ],
                                      onChanged: (valueTime) {
                                        checkOutHoursSpent = valueTime;
                                        _validateCheckOut = false;
                                      },
                                      decoration: InputDecoration(
                                        labelText: '00:00',
                                        labelStyle:
                                        TextStyle(color: labelTextColor),
                                        border: const OutlineInputBorder(),
                                        errorText: _validateCheckOut
                                            ? 'Please Choose a Check-Out'
                                            : null,
                                        contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 10.0),
                                        prefixIcon: IconButton(
                                          icon: const Icon(Icons.access_time),
                                          onPressed: () async {
                                            final TimeOfDay? picked =
                                            await showTimePicker(
                                              context: context,
                                              initialTime: TimeOfDay.now(),
                                            );
                                            if (picked != null) {
                                              checkoutHoursController.text =
                                              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                              checkOutHoursSpent =
                                              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                            }
                                            _validateCheckOut = false;
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.03),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Working Hours',
                                      style: TextStyle(color: blackColor),
                                    ),
                                    SizedBox(
                                        height:
                                        MediaQuery.of(context).size.height *
                                            0.01),
                                    TextField(
                                      controller: workedHoursController,
                                      keyboardType: TextInputType.datetime,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(4),
                                        _TimeInputFormatter(),
                                      ],
                                      onChanged: (valueTime) {
                                        workHoursSpent = valueTime;
                                        _validateWorkingHours = false;
                                      },
                                      decoration: InputDecoration(
                                        labelText: '00:00',
                                        labelStyle:
                                        TextStyle(color: labelTextColor),
                                        border: const OutlineInputBorder(),
                                        contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 10.0),
                                        errorText: _validateWorkingHours
                                            ? 'Please add Working Hours'
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                  width:
                                  MediaQuery.of(context).size.width * 0.03),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Minimum Hour',
                                      style: TextStyle(color: blackColor),
                                    ),
                                    SizedBox(
                                        height:
                                        MediaQuery.of(context).size.height *
                                            0.01),
                                    TextField(
                                      controller: minimumHourController,
                                      keyboardType: TextInputType.datetime,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(4),
                                        _TimeInputFormatter(),
                                      ],
                                      onChanged: (valueTime) {
                                        minimumHoursSpent = valueTime;
                                        _validateMinimumHours = false;
                                      },
                                      decoration: InputDecoration(
                                        labelText: '00:00',
                                        labelStyle:
                                        TextStyle(color: labelTextColor),
                                        border: const OutlineInputBorder(),
                                        contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 10.0),
                                        errorText: _validateMinimumHours
                                            ? 'Please add Minimum Hours'
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.04),
                        ],
                      ),
                    ),
                  ),
                  actions: <Widget>[
                    SizedBox(
                      width: double.infinity, // Make button width infinite
                      child: TextButton(
                        onPressed: () async {
                          if (isSaveClick == true) {
                            isSaveClick = false;
                            setState(() {
                              isAction = true;
                            });
                            if (createEmployee == null) {
                              setState(() {
                                isAction = false;
                                isSaveClick = true;
                                _validateCheckOutDate = false;
                                _validateCheckOut = false;
                                _validateEmployee = true;
                                _validateDate = false;
                                _validateShift = false;
                                _validateCheckInDate = false;
                                _validateCheckIn = false;
                                _validateWorkingHours = false;
                                _validateMinimumHours = false;
                                Navigator.of(context).pop(true);
                                showCreateAttendanceDialog(context);
                              });
                            } else if (attendanceDateController.text.isEmpty) {
                              setState(() {
                                isAction = false;
                                isSaveClick = true;
                                _validateCheckOutDate = false;
                                _validateCheckOut = false;
                                _validateDate = true;
                                _validateEmployee = false;
                                _validateShift = false;
                                _validateCheckInDate = false;
                                _validateCheckIn = false;
                                _validateWorkingHours = false;
                                _validateMinimumHours = false;
                                Navigator.of(context).pop(true);
                                showCreateAttendanceDialog(context);
                              });
                            } else if (createShift == null) {
                              setState(() {
                                isAction = false;
                                isSaveClick = true;
                                _validateCheckOutDate = false;
                                _validateCheckOut = false;
                                _validateShift = true;
                                _validateDate = false;
                                _validateEmployee = false;
                                _validateCheckInDate = false;
                                _validateCheckIn = false;
                                _validateWorkingHours = false;
                                _validateMinimumHours = false;
                                Navigator.of(context).pop(true);
                                showCreateAttendanceDialog(context);
                              });
                            } else if (checkInDateController.text.isEmpty) {
                              setState(() {
                                isAction = false;
                                isSaveClick = true;
                                _validateCheckOutDate = false;
                                _validateCheckOut = false;
                                _validateCheckInDate = true;
                                _validateShift = false;
                                _validateDate = false;
                                _validateEmployee = false;
                                _validateCheckIn = false;
                                _validateWorkingHours = false;
                                _validateMinimumHours = false;
                                Navigator.of(context).pop(true);
                                showCreateAttendanceDialog(context);
                              });
                            } else if (checkInHoursController.text.isEmpty) {
                              setState(() {
                                isAction = false;
                                isSaveClick = true;
                                _validateCheckOutDate = false;
                                _validateCheckOut = false;
                                _validateShift = false;
                                _validateDate = false;
                                _validateEmployee = false;
                                _validateCheckInDate = false;
                                _validateCheckIn = true;
                                _validateWorkingHours = false;
                                _validateMinimumHours = false;
                                Navigator.of(context).pop(true);
                                showCreateAttendanceDialog(context);
                              });
                            } else if (checkOutDateController.text.isEmpty) {
                              setState(() {
                                isAction = false;
                                isSaveClick = true;
                                _validateCheckOutDate = true;
                                _validateCheckOut = false;
                                _validateShift = false;
                                _validateDate = false;
                                _validateEmployee = false;
                                _validateCheckInDate = false;
                                _validateCheckIn = false;
                                _validateWorkingHours = false;
                                _validateMinimumHours = false;
                                Navigator.of(context).pop(true);
                                showCreateAttendanceDialog(context);
                              });
                            } else if (checkoutHoursController.text.isEmpty) {
                              setState(() {
                                isAction = false;
                                isSaveClick = true;
                                _validateCheckOutDate = false;
                                _validateCheckOut = true;
                                _validateShift = false;
                                _validateDate = false;
                                _validateEmployee = false;
                                _validateCheckInDate = false;
                                _validateCheckIn = false;
                                _validateWorkingHours = false;
                                _validateMinimumHours = false;
                                Navigator.of(context).pop(true);
                                showCreateAttendanceDialog(context);
                              });
                            } else if (workedHoursController.text.isEmpty) {
                              setState(() {
                                isAction = false;
                                isSaveClick = true;
                                _validateWorkingHours = true;
                                _validateShift = false;
                                _validateDate = false;
                                _validateEmployee = false;
                                _validateCheckInDate = false;
                                _validateCheckIn = false;
                                _validateCheckOutDate = false;
                                _validateCheckOut = false;
                                _validateMinimumHours = false;
                                Navigator.of(context).pop(true);
                                showCreateAttendanceDialog(context);
                              });
                            } else if (minimumHourController.text.isEmpty) {
                              setState(() {
                                isAction = false;
                                isSaveClick = true;
                                _validateMinimumHours = true;
                                _validateShift = false;
                                _validateDate = false;
                                _validateEmployee = false;
                                _validateCheckInDate = false;
                                _validateCheckIn = false;
                                _validateCheckOutDate = false;
                                _validateWorkingHours = false;
                                Navigator.of(context).pop(true);
                                showCreateAttendanceDialog(context);
                              });
                            } else {
                              String defaultAttendanceDate =
                              DateFormat('yyyy-MM-dd')
                                  .format(DateTime.now());
                              String defaultCheckInDate =
                              DateFormat('yyyy-MM-dd')
                                  .format(DateTime.now());
                              String defaultTime = '00:00';
                              Map<String, dynamic> createdDetails = {
                                "employee_id": selectedEmployeeId ?? '',
                                "attendance_date":
                                attendanceDateController.text.isNotEmpty
                                    ? attendanceDateController.text
                                    : defaultAttendanceDate,
                                'shift_id': selectedShiftId ?? '',
                                'attendance_clock_in_date':
                                checkInDateController.text.isNotEmpty
                                    ? checkInDateController.text
                                    : defaultCheckInDate,
                                'attendance_clock_in':
                                checkInHoursSpent.isNotEmpty
                                    ? checkInHoursSpent
                                    : defaultTime,
                                'attendance_clock_out_date':
                                checkOutDateController.text.isNotEmpty
                                    ? checkOutDateController.text
                                    : defaultCheckInDate,
                                'attendance_clock_out':
                                checkOutHoursSpent.isNotEmpty
                                    ? checkOutHoursSpent
                                    : defaultTime,
                                'attendance_worked_hour':
                                workHoursSpent.isNotEmpty
                                    ? workHoursSpent
                                    : defaultTime,
                                'minimum_hour': minimumHoursSpent.isNotEmpty
                                    ? minimumHoursSpent
                                    : defaultTime,
                              };
                              await createNewAttendance(createdDetails);
                              setState(() {
                                isAction = false;
                              });
                              if (_errorMessage == null ||
                                  _errorMessage!.isEmpty) {
                                Navigator.of(context).pop(true);
                                showCreateAnimation();
                              } else {
                                Navigator.of(context).pop(true);
                                showCreateAttendanceDialog(context);
                              }
                            }
                          }
                        },
                        style: ButtonStyle(
                          backgroundColor:
                          MaterialStateProperty.all<Color>(redColor),
                          shape:
                          MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6.0),
                            ),
                          ),
                        ),
                        child: Text('Save',
                            style: TextStyle(color: whiteColor)),
                      ),
                    ),
                  ],
                ),
                if (isAction)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: whiteColor,
        key: _scaffoldKey,
        appBar: AppBar(
          backgroundColor: whiteColor,
          leading: IconButton(
            icon: const Icon(Icons.menu), // Menu icon
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
          title: Text('Attendance',
              style:
              TextStyle(color: blackColor, fontWeight: FontWeight.bold)),
          actions: [
            Padding(
              padding: const EdgeInsets.all(12.0), // Adjust the value as needed
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isSaveClick = true;
                          _errorMessage = null;
                          createEmployee = null;
                          createShift = null;
                          isAction = false;
                          _validateMinimumHours = false;
                          _validateShift = false;
                          _validateDate = false;
                          _validateEmployee = false;
                          _validateCheckInDate = false;
                          _validateCheckIn = false;
                          _validateCheckOutDate = false;
                          _validateWorkingHours = false;
                          _typeAheadCreateController.clear();
                          attendanceDateController.clear();
                          _typeAheadCreateShiftController.clear();
                          checkInDateController.clear();
                          checkInHoursController.clear();
                          checkOutDateController.clear();
                          checkoutHoursController.clear();
                          workedHoursController.clear();
                          minimumHourController.clear();
                        });
                        showCreateAttendanceDialog(context);
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(75, 50),
                        backgroundColor: whiteColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0),
                          side: BorderSide(color: redColor),
                        ),
                      ),
                      child: Text('CREATE',
                          style: TextStyle(color: redColor)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: isLoading ? _buildLoadingWidget() : _buildEmployeeDetailsWidget(),
        drawer: _permissionsLoaded
            ? Drawer(
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
              // Only show Overview if permission is true
              if (_permissionOverview)
                ListTile(
                  title: const Text('Overview'),
                  onTap: () { Navigator.pushNamed(context, '/attendance_overview'); },
                ),
              // Always show Attendance (default permission is true)
              ListTile(
                title: const Text('Attendance'),
                onTap: () {
                  Navigator.pushNamed(context, '/attendance_attendance');
                },
              ),
              // Only show if permission is true
              if (_permissionAttendanceRequest)
                ListTile(
                  title: const Text('Attendance Request'),
                  onTap: () {
                    Navigator.pushNamed(context, '/attendance_request');
                  },
                ),
              // Only show if permission is true
              if (_permissionHourAccount)
                ListTile(
                  title: const Text('Hour Account'),
                  onTap: () {
                    Navigator.pushNamed(context, '/employee_hour_account');
                  },
                ),
            ],
          ),
        )
            : Drawer( // Loading state
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
              shimmerListTile(),
              shimmerListTile(),
              shimmerListTile(),
              shimmerListTile(),
            ],
          ),
        ),
        bottomNavigationBar: (bottomBarPages.length <= maxCount)
            ? AnimatedNotchBottomBar(
          /// Provide NotchBottomBarController
          notchBottomBarController: _controller,
          color: redColor,
          showLabel: true,
          notchColor: redColor,
          kBottomRadius: 28.0,
          kIconSize: 24.0,

          /// restart app if you change removeMargins
          removeMargins: false,
          bottomBarWidth: MediaQuery.of(context).size.width * 1,
          durationInMilliSeconds: 300,
          bottomBarItems: [
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
              // itemLabel: 'Profile',
            ),
          ],

          onTap: (index) async {
            switch (index) {
              case 0:
                Navigator.pushNamed(context, '/home');
                break;
              case 1:
                Navigator.pushNamed(
                    context, '/employee_checkin_checkout');
                break;
              case 2:
                Navigator.pushNamed(context, '/employees_form',
                    arguments: arguments);
                break;
            }
          },
        )
            : null,
      ),
      // ),
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
          color: whiteColor,
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: Card(
                  margin: const EdgeInsets.all(8),
                  elevation: 0,
                  child: Shimmer.fromColors(
                    baseColor: grey300,
                    highlightColor: grey100,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4.0),
                        border: Border.all(color: grey300),
                        color: whiteColor,
                      ),
                      child: const TextField(
                        decoration: InputDecoration(
                          hintText: 'Search',
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.search),
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 12.0, horizontal: 4.0),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.02),
        _buildTabBarShimmer(),
        SizedBox(height: MediaQuery.of(context).size.height * 0.03),
        Expanded(
          child: TabBarView(
            children: [
              buildMyAttendanceLoadingAttendanceContent(
                  requestsMyAttendance, _scrollController, searchText),
              buildValidateLoadingAttendanceContent(
                  requestsNonValidAttendance, _scrollController, searchText),
              buildOvertimeLoadingAttendanceContent(
                  requestsOvertimeAttendance, _scrollController, searchText),
              buildValidatedLoadingAttendanceContent(
                  requestsValidatedAttendance, _scrollController, searchText),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBarShimmer() {
    return Shimmer.fromColors(
      baseColor: grey300,
      highlightColor: grey100,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(4, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8.0),
              height: 30.0,
              width: 120.0,
              decoration: BoxDecoration(
                color: whiteColor,
                borderRadius: BorderRadius.circular(16.0),
              ),
            );
          }),
        ),
      ),
    );
  }


  Widget _buildEmployeeDetailsWidget() {
    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Card(
                      margin: const EdgeInsets.all(8),
                      elevation: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: grey100),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextField(
                          onChanged: (employeeSearchValue) {
                            if (_debounce?.isActive ?? false) {
                              _debounce!.cancel();
                            }
                            _debounce = Timer(const Duration(milliseconds: 500), () {
                              setState(() {
                                searchText = employeeSearchValue;
                                // Reset to page 1 when searching
                                currentPage = 1;
                                requestsMyAttendance.clear();
                                requestsNonValidAttendance.clear();
                                requestsOvertimeAttendance.clear();
                                requestsValidatedAttendance.clear();

                                // Fetch data with search filter
                                getMyAttendance(reset: true);
                                getAllNonValidatedAttendance(reset: true);
                                getAllOvertimeAttendance(reset: true);
                                getAllValidatedAttendance(reset: true);
                              });
                            });
                          },
                          decoration: InputDecoration(
                            hintStyle: TextStyle(color: grey700, fontSize: 14),
                            hintText: 'Search',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: grey100,
                            prefixIcon: Transform.scale(
                              scale: 0.8,
                              child: Icon(Icons.search, color: grey700),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 12.0, horizontal: 4.0),
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            TabBar(
              indicatorColor: redColor,
              labelColor: redColor,
              unselectedLabelColor: iconSecondaryColor,
              isScrollable: true,
              tabs: [
                Tab(text: 'My Attendances ($myAttendances)'),
               if (attendanceTypeCheck == true)...[
                 Tab(text: 'To Validate ($toValidate)'),
                 Tab(text: 'Overtime ($overtime)'),
                 Tab(text: 'Validated ($validated)'),
               ]
              ],
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
            Expanded(
              child: TabBarView(
                children: [
                  myAttendances == 0
                      ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_outlined,
                            color: blackColor,
                            size: 92,
                          ),
                          SizedBox(height: 20),
                          Text(
                            "There are no attendance records to display",
                            style: TextStyle(
                                fontSize: 16.0,
                                color: blackColor,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  )
                      : buildMyAttendanceContent(
                      requestsMyAttendance,
                      _scrollController,
                      searchText),
                  if (attendanceTypeCheck == true)...[
                    toValidate == 0
                        ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_outlined,
                              color: blackColor,
                              size: 92,
                            ),
                            SizedBox(height: 20),
                            Text(
                              "There are no attendance records to display",
                              style: TextStyle(
                                  fontSize: 16.0,
                                  color: blackColor,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    )
                        : buildValidateAttendanceContent(
                        requestsNonValidAttendance,
                        _scrollController,
                        searchText),
                    overtime == 0
                        ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_outlined,
                              color: blackColor,
                              size: 92,
                            ),
                            SizedBox(height: 20),
                            Text(
                              "There are no attendance records to display",
                              style: TextStyle(
                                  fontSize: 16.0,
                                  color: blackColor,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    )
                        : buildOvertimeAttendanceContent(
                        requestsOvertimeAttendance,
                        _scrollController,
                        searchText),
                    validated == 0
                        ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_outlined,
                              color: blackColor,
                              size: 92,
                            ),
                            SizedBox(height: 20),
                            Text(
                              "There are no attendance records to display",
                              style: TextStyle(
                                  fontSize: 16.0,
                                  color: blackColor,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    )
                        : buildValidatedAttendanceContent(
                        requestsValidatedAttendance,
                        _scrollController,
                        searchText),
                  ]
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildMyAttendanceLoadingAttendanceContent(
      List<Map<String, dynamic>> requestsMyAttendance,
      scrollController,
      searchText) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: 10,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: grey300,
            highlightColor: grey100,
            child: Container(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: whiteColor,
                  border: Border.all(color: grey100),
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(
                      color: disabledColor.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Card(
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: whiteColor, width: 0.0),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  color: whiteColor,
                  elevation: 0.1,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40.0,
                              height: 40.0,
                              color: grey300,
                            ),
                          ],
                        ),
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.005),
                        Container(
                          height: 20.0,
                          color: grey300,
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 20.0,
                          width: 80.0,
                          color: grey300,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildValidateLoadingAttendanceContent(
      List<Map<String, dynamic>> requestsNonValidAttendance,
      scrollController,
      searchText) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: 10,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: grey300,
            highlightColor: grey100,
            child: Container(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: whiteColor,
                  border: Border.all(color: grey100),
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(
                      color: disabledColor.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Card(
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: whiteColor, width: 0.0),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  color: whiteColor,
                  elevation: 0.1,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40.0,
                              height: 40.0,
                              color: grey300,
                            ),
                          ],
                        ),
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.005),
                        Container(
                          height: 20.0,
                          color: grey300,
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 20.0,
                          width: 80.0,
                          color: grey300,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildOvertimeLoadingAttendanceContent(
      List<Map<String, dynamic>> requestsNonValidAttendance,
      scrollController,
      searchText) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: 10,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: grey300,
            highlightColor: grey100,
            child: Container(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: whiteColor,
                  border: Border.all(color: grey100),
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(
                      color: disabledColor.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Card(
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: whiteColor, width: 0.0),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  color: whiteColor,
                  elevation: 0.1,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40.0,
                              height: 40.0,
                              color: grey300,
                            ),
                          ],
                        ),
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.005),
                        Container(
                          height: 20.0,
                          color: grey300,
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 20.0,
                          width: 80.0,
                          color: grey300,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildValidatedLoadingAttendanceContent(
      List<Map<String, dynamic>> requestsNonValidAttendance,
      scrollController,
      searchText) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: 10,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: grey300,
            highlightColor: grey100,
            child: Container(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: whiteColor,
                  border: Border.all(color: grey100),
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(
                      color: disabledColor.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Card(
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: whiteColor, width: 0.0),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  color: whiteColor,
                  elevation: 0.1,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40.0,
                              height: 40.0,
                              color: grey300,
                            ),
                          ],
                        ),
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.005),
                        Container(
                          height: 20.0,
                          color: grey300,
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 20.0,
                          width: 80.0,
                          color: grey300,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }


  Widget buildMyAttendanceContent(
      List<Map<String, dynamic>> requestsMyAttendance,
      scrollController,
      searchText) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView.builder(
        controller: scrollController,
        shrinkWrap: true,
        itemCount: (searchText.isEmpty
            ? requestsMyAttendance.length
            : filteredMyAttendance.length) +
            1, // extra item for loader
        itemBuilder: (context, index) {
          if (index ==
              (searchText.isEmpty
                  ? requestsMyAttendance.length
                  : filteredMyAttendance.length)) {
            return isFetchingMore
                ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            )
                : const SizedBox();
          }

          final record = searchText.isEmpty
              ? requestsMyAttendance[index]
              : filteredMyAttendance[index];
          final firstName = record['employee_first_name'] ?? '';
          final lastName = record['employee_last_name'] ?? '';
          final fullName =
              (firstName.isEmpty ? '' : firstName) + (lastName.isEmpty ? '' : ' $lastName');
          final profile = record['employee_profile'];
          return buildMyAttendance(record, fullName, profile ?? "", baseUrl, getToken);
        },
      ),
    );
  }

  Widget buildValidateAttendanceContent(
      List<Map<String, dynamic>> requestsNonValidAttendance,
      scrollController,
      searchText) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView.builder(
        controller: scrollController,
        shrinkWrap: true,
        itemCount: searchText.isEmpty
            ? requestsNonValidAttendance.length
            : filteredNonValidAttendance.length,
        itemBuilder: (context, index) {
          final record = searchText.isEmpty
              ? requestsNonValidAttendance[index]
              : filteredNonValidAttendance[index];

          final firstName = record['employee_first_name'] ?? '';
          final lastName = record['employee_last_name'] ?? '';
          final fullName = (firstName.isEmpty ? '' : firstName) +
              (lastName.isEmpty ? '' : ' $lastName');
          final profile = record['employee_profile'];
          return buildNonValidatedAttendance(
              record, fullName, profile ?? "", baseUrl, getToken);
        },
      ),
    );
  }

  Widget buildOvertimeAttendanceContent(
      List<Map<String, dynamic>> requestsOvertimeAttendance,
      scrollController,
      searchText) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView.builder(
        controller: scrollController,
        shrinkWrap: true,
        itemCount: searchText.isEmpty
            ? requestsOvertimeAttendance.length
            : filteredOvertimeAttendance.length,
        itemBuilder: (context, index) {
          final record = searchText.isEmpty
              ? requestsOvertimeAttendance[index]
              : filteredOvertimeAttendance[index];

          final firstName = record['employee_first_name'] ?? '';
          final lastName = record['employee_last_name'] ?? '';
          final fullName = (firstName.isEmpty ? '' : firstName) +
              (lastName.isEmpty ? '' : ' $lastName');
          final profile = record['employee_profile'];
          return buildOvertimeAttendance(
              record, fullName, profile ?? "", baseUrl, getToken);
        },
      ),
    );
  }

  Widget buildValidatedAttendanceContent(
      List<Map<String, dynamic>> requestsValidatedAttendance,
      scrollController,
      searchText) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView.builder(
        controller: scrollController,
        shrinkWrap: true,
        itemCount: searchText.isEmpty
            ? requestsValidatedAttendance.length
            : filteredValidatedAttendance.length,
        itemBuilder: (context, index) {
          final record = searchText.isEmpty
              ? requestsValidatedAttendance[index]
              : filteredValidatedAttendance[index];
          final firstName = record['employee_first_name'] ?? '';
          final lastName = record['employee_last_name'] ?? '';
          final fullName = (firstName.isEmpty ? '' : firstName) +
              (lastName.isEmpty ? '' : ' $lastName');
          final profile = record['employee_profile'];
          return buildValidatedAttendance(
              record, fullName, profile ?? "", baseUrl, getToken);
        },
      ),
    );
  }

  Widget buildMyAttendance(
      Map<String, dynamic> record, fullName, String profile, baseUrl, token) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: whiteColor,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(" "),
                  IconButton(
                    icon: Icon(Icons.close, color: iconSecondaryColor),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.95,
                height: MediaQuery.of(context).size.height * 0.5,
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
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border:
                              Border.all(color: grey300, width: 1.0),
                            ),
                            child: Stack(
                              children: [
                                if (record['employee_profile_url'] != null &&
                                    record['employee_profile_url'].isNotEmpty)
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
                                          return Icon(Icons.person,
                                              color: iconSecondaryColor);
                                        },
                                      ),
                                    ),
                                  ),
                                if (record['employee_profile_url'] == null ||
                                    record['employee_profile_url'].isEmpty)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: disabledColor,
                                      ),
                                      child: const Icon(Icons.person),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(
                              width: MediaQuery.of(context).size.width * 0.01),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fullName ?? '',
                                  style: const TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold),
                                  maxLines: 2,
                                ),
                                Text(
                                  record['badge_id'] != null
                                      ? '${record['badge_id']}'
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
                                  color: borderLightColor,
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                              ),
                              SizedBox(
                                  width: MediaQuery.of(context).size.width *
                                      0.008),
                              Container(
                                decoration: BoxDecoration(
                                  color: borderLightColor,
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.05),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Date',
                            style: TextStyle(color: grey700),
                          ),
                          Text('${record['attendance_date'] ?? 'None'}'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Check-In',
                            style: TextStyle(color: grey700),
                          ),
                          Text('${record['attendance_clock_in'] ?? 'None'}'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Check-Out',
                            style: TextStyle(color: grey700),
                          ),
                          Text('${record['attendance_clock_out'] ?? 'None'}'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Shift',
                            style: TextStyle(color: grey700),
                          ),
                          Text('${record['shift_name'] ?? 'None'}'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Minimum Hour',
                            style: TextStyle(color: grey700),
                          ),
                          Text('${record['minimum_hour'] ?? 'None'}'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Check-In Date',
                            style: TextStyle(color: grey700),
                          ),
                          Text(
                              '${record['attendance_clock_in_date'] ?? 'None'}'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Check-Out Date',
                            style: TextStyle(color: grey700),
                          ),
                          Text(
                              '${record['attendance_clock_out_date'] ?? 'None'}'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'At Work',
                            style: TextStyle(color: grey700),
                          ),
                          Text('${record['attendance_worked_hour'] ?? 'None'}'),
                        ],
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.01),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.all(8.0),
        color: whiteColor,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: grey100),
            borderRadius: BorderRadius.circular(8.0),
            color: whiteColor,
            boxShadow: [
              BoxShadow(
                color: disabledColor.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Card(
            shape: RoundedRectangleBorder(
              side: BorderSide(color: whiteColor, width: 0.0),
              borderRadius: BorderRadius.circular(10.0),
            ),
            color: whiteColor,
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
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: iconSecondaryColor,
                              width: 1.0), // Optional border
                        ),
                        child: Stack(
                          children: [
                            if (record['employee_profile_url'] != null &&
                                record['employee_profile_url'].isNotEmpty)
                              Positioned.fill(
                                child: ClipOval(
                                  child: Image.network(
                                    baseUrl + record['employee_profile_url'],
                                    headers: {
                                      "Authorization": "Bearer $token",
                                    },
                                    fit: BoxFit.cover,
                                    errorBuilder: (BuildContext context,
                                        Object exception,
                                        StackTrace? stackTrace) {
                                      return Icon(Icons.person,
                                          color: iconSecondaryColor); // Fallback icon
                                    },
                                  ),
                                ),
                              ),
                            if (record['employee_profile_url'] == null ||
                                record['employee_profile_url'].isEmpty)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: disabledColor,
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
                              fullName ?? '',
                              style: const TextStyle(
                                  fontSize: 16.0, fontWeight: FontWeight.bold),
                              maxLines: 2,
                            ),
                            Text(
                              record['badge_id'] != null
                                  ? '${record['badge_id']}'
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
                  SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Date',
                        style: TextStyle(color: grey700),
                      ),
                      Text('${record['attendance_date'] ?? 'None'}'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Check-In',
                        style: TextStyle(color: grey700),
                      ),
                      Text('${record['attendance_clock_in'] ?? 'None'}'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Check-Out',
                        style: TextStyle(color: grey700),
                      ),
                      Text('${record['attendance_clock_out'] ?? 'None'}'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Worked Hours',
                        style: TextStyle(color: grey700),
                      ),
                      Text('${record['attendance_worked_hour'] ?? 'None'}'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Minimum Hours',
                        style: TextStyle(color: grey700),
                      ),
                      Text('${record['minimum_hour'] ?? 'None'}'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Shift',
                        style: TextStyle(color: grey700),
                      ),
                      Text('${record['shift_name'] ?? 'None'}'),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildNonValidatedAttendance(
      Map<String, dynamic> record, fullName, String profile, baseUrl, token) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: whiteColor,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(" "),
                  IconButton(
                    icon: Icon(Icons.close, color: iconSecondaryColor),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.95,
                height: MediaQuery.of(context).size.height * 0.5,
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
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border:
                              Border.all(color: grey300, width: 1.0),
                            ),
                            child: Stack(
                              children: [
                                if (record['employee_profile_url'] != null &&
                                    record['employee_profile_url'].isNotEmpty)
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
                                          return Icon(Icons.person,
                                              color: iconSecondaryColor);
                                        },
                                      ),
                                    ),
                                  ),
                                if (record['employee_profile_url'] == null ||
                                    record['employee_profile_url'].isEmpty)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: disabledColor,
                                      ),
                                      child: const Icon(Icons.person),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(
                              width: MediaQuery.of(context).size.width * 0.01),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fullName ?? '',
                                  style: const TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold),
                                  maxLines: 2,
                                ),
                                Text(
                                  record['badge_id'] != null
                                      ? '${record['badge_id']}'
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
                                  color: borderLightColor,
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                              ),
                              SizedBox(
                                  width: MediaQuery.of(context).size.width *
                                      0.008),
                              Container(
                                decoration: BoxDecoration(
                                  color: borderLightColor,
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.05),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Date',
                            style: TextStyle(color: grey700),
                          ),
                          Text('${record['attendance_date'] ?? 'None'}'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Check-In',
                            style: TextStyle(color: grey700),
                          ),
                          Text('${record['attendance_clock_in'] ?? 'None'}'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Check-Out',
                            style: TextStyle(color: grey700),
                          ),
                          Text('${record['attendance_clock_out'] ?? 'None'}'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Shift',
                            style: TextStyle(color: grey700),
                          ),
                          Text('${record['shift_name'] ?? 'None'}'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Minimum Hour',
                            style: TextStyle(color: grey700),
                          ),
                          Text('${record['minimum_hour'] ?? 'None'}'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Check-In Date',
                            style: TextStyle(color: grey700),
                          ),
                          Text(
                              '${record['attendance_clock_in_date'] ?? 'None'}'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Check-Out Date',
                            style: TextStyle(color: grey700),
                          ),
                          Text(
                              '${record['attendance_clock_out_date'] ?? 'None'}'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'At Work',
                            style: TextStyle(color: grey700),
                          ),
                          Text('${record['attendance_worked_hour'] ?? 'None'}'),
                        ],
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.01),
                    ],
                  ),
                ),
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      isSaveClick = true;
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor: whiteColor,
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Confirmation",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: blackColor),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    Navigator.of(context).pop(true);
                                  },
                                ),
                              ],
                            ),
                            content: SizedBox(
                              height: MediaQuery.of(context).size.height * 0.1,
                              child: Center(
                                child: Text(
                                  "Are you sure you want to Validate this Attendance?",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: blackColor,
                                    fontSize: 17,
                                  ),
                                ),
                              ),
                            ),
                            actions: [
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () async {
                                   if (isSaveClick == true) {
                                     isSaveClick = false;
                                     Map<String, dynamic> validatedDetails = {
                                       "id": record['id'],
                                     };
                                     await validateAttendance(validatedDetails);
                                     Navigator.of(context).pop();
                                     Navigator.of(context).pop();
                                     showValidateAnimation();
                                   }
                                  },
                                  style: ButtonStyle(
                                    backgroundColor:
                                    MaterialStateProperty.all<Color>(
                                        successColor),
                                    shape: MaterialStateProperty.all<
                                        RoundedRectangleBorder>(
                                      RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(8.0),
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    "Continue",
                                    style: TextStyle(color: whiteColor),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: successColor,
                      // Red color for assign button
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.20,
                        vertical: MediaQuery.of(context).size.height * 0.001,
                      ),
                    ),
                    child: Text(
                      "Validate",
                      style: TextStyle(fontSize: 18, color: whiteColor),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.all(8.0),
        color: whiteColor,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: grey100),
            borderRadius: BorderRadius.circular(8.0),
            color: whiteColor,
            boxShadow: [
              BoxShadow(
                color: disabledColor.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Card(
            shape: RoundedRectangleBorder(
              side: BorderSide(color: whiteColor, width: 0.0),
              borderRadius: BorderRadius.circular(10.0),
            ),
            color: whiteColor,
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
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: iconSecondaryColor,
                              width: 1.0), // Optional border
                        ),
                        child: Stack(
                          children: [
                            if (record['employee_profile_url'] != null &&
                                record['employee_profile_url'].isNotEmpty)
                              Positioned.fill(
                                child: ClipOval(
                                  child: Image.network(
                                    baseUrl + record['employee_profile_url'],
                                    headers: {
                                      "Authorization": "Bearer $token",
                                    },
                                    fit: BoxFit.cover,
                                    errorBuilder: (BuildContext context,
                                        Object exception,
                                        StackTrace? stackTrace) {
                                      return Icon(Icons.person,
                                          color: iconSecondaryColor); // Fallback icon
                                    },
                                  ),
                                ),
                              ),
                            if (record['employee_profile_url'] == null ||
                                record['employee_profile_url'].isEmpty)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: disabledColor,
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
                              fullName ?? '',
                              style: const TextStyle(
                                  fontSize: 16.0, fontWeight: FontWeight.bold),
                              maxLines: 2,
                            ),
                            Text(
                              record['badge_id'] != null
                                  ? '${record['badge_id']}'
                                  : '',
                              style: const TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.normal),
                            ),
                          ],
                        ),
                      ),
                      managerCheck != null
                          ? Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(15.0),
                                bottomLeft: Radius.circular(15.0),
                              ),
                              color: infoColor.withOpacity(0.3),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 0.0),
                              child: IconButton(
                                icon: Icon(
                                  Icons.edit,
                                  size: 18.0,
                                  color: infoColor,
                                ),
                                onPressed: () {
                                  setState(() {
                                    isSaveClick = true;
                                    _errorMessage = null;
                                    isAction = false;
                                  });
                                  _showValidateAttendance(
                                      context, record);
                                },
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(15.0),
                                bottomRight: Radius.circular(15.0),
                              ),
                              color: errorBackgroundColor,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 0.0),
                              child: IconButton(
                                icon: Icon(
                                  Icons.delete,
                                  size: 18.0,
                                  color: redColor,
                                ),
                                onPressed: () async {
                                  isSaveClick = true;
                                  await showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        backgroundColor: whiteColor,
                                        title: Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment
                                              .spaceBetween,
                                          children: [
                                            Text(
                                              "Confirmation",
                                              style: TextStyle(
                                                fontWeight:
                                                FontWeight.bold,
                                                color: blackColor,
                                              ),
                                            ),
                                            IconButton(
                                              icon:
                                              const Icon(Icons.close),
                                              onPressed: () {
                                                Navigator.of(context)
                                                    .pop(true);
                                              },
                                            ),
                                          ],
                                        ),
                                        content: SizedBox(
                                          height: MediaQuery.of(context)
                                              .size
                                              .height *
                                              0.1,
                                          child: Center(
                                            child: Text(
                                              "Are you sure you want to delete this attendance?",
                                              style: TextStyle(
                                                fontWeight:
                                                FontWeight.bold,
                                                color: blackColor,
                                                fontSize: 17,
                                              ),
                                            ),
                                          ),
                                        ),
                                        actions: [
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              onPressed: () async {
                                                if (isSaveClick == true) {
                                                  isSaveClick = false;
                                                  Map<String, dynamic>
                                                  deletedDetails = {
                                                    'id': record['id'],
                                                  };
                                                  await deleteNonValidatedAttendance(
                                                      deletedDetails);
                                                  Navigator.of(context)
                                                      .pop(true);
                                                  showDeleteAnimation();
                                                }
                                              },
                                              style: ButtonStyle(
                                                backgroundColor:
                                                MaterialStateProperty
                                                    .all<Color>(
                                                    redColor),
                                                shape: MaterialStateProperty
                                                    .all<
                                                    RoundedRectangleBorder>(
                                                  RoundedRectangleBorder(
                                                    borderRadius:
                                                    BorderRadius
                                                        .circular(
                                                        8.0),
                                                  ),
                                                ),
                                              ),
                                              child: Text(
                                                "Continue",
                                                style: TextStyle(
                                                    color: whiteColor),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      )
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(15.0),
                                bottomLeft: Radius.circular(15.0),
                              ),
                              color: infoColor.withOpacity(0.3), // Blue background for edit icon
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 0.0),
                              child: IconButton(
                                icon: Icon(
                                  Icons.edit,
                                  size: 18.0, // Reduce icon size
                                  color: infoColor, // Set icon color
                                ),
                                onPressed: () {
                                  setState(() {
                                    isSaveClick = true;
                                    _errorMessage = null;
                                    isAction = false;
                                  });
                                  _showValidateAttendance(
                                      context, record);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Date',
                        style: TextStyle(color: grey700),
                      ),
                      Text('${record['attendance_date'] ?? 'None'}'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Check-In',
                        style: TextStyle(color: grey700),
                      ),
                      Text('${record['attendance_clock_in'] ?? 'None'}'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Shift',
                        style: TextStyle(color: grey700),
                      ),
                      Text('${record['shift_name'] ?? 'None'}'),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          isSaveClick = true;
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                backgroundColor: whiteColor,
                                title: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Confirmation",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: blackColor),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () {
                                        Navigator.of(context)
                                            .pop(true); // Close the dialog
                                      },
                                    ),
                                  ],
                                ),
                                content: SizedBox(
                                  height:
                                  MediaQuery.of(context).size.height * 0.1,
                                  child: Center(
                                    child: Text(
                                      "Are you sure you want to Validate this Attendance?",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: blackColor,
                                        fontSize: 17,
                                      ),
                                    ),
                                  ),
                                ),
                                actions: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        if (isSaveClick == true) {
                                          isSaveClick = false;
                                          Map<String, dynamic> validatedDetails =
                                          {
                                            "id": record['id'],
                                          };
                                          await validateAttendance(
                                              validatedDetails);
                                          Navigator.of(context).pop(true);
                                          showValidateAnimation();
                                        }
                                      },
                                      style: ButtonStyle(
                                        backgroundColor:
                                        MaterialStateProperty.all<Color>(
                                            successColor),
                                        shape: MaterialStateProperty.all<
                                            RoundedRectangleBorder>(
                                          RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.circular(8.0),
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        "Continue",
                                        style: TextStyle(color: whiteColor),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: successColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal:
                            MediaQuery.of(context).size.width * 0.30,
                            vertical: MediaQuery.of(context).size.height * 0.01,
                          ),
                        ),
                        child: Text(
                          'Validate',
                          style: TextStyle(fontSize: 18, color: whiteColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildOvertimeAttendance(
      Map<String, dynamic> record, fullName, String profile, baseUrl, token) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: whiteColor,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(""),
                  IconButton(
                    icon: Icon(Icons.close, color: iconSecondaryColor),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.95,
                height: MediaQuery.of(context).size.height * 0.5,
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
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border:
                              Border.all(color: grey300, width: 1.0),
                            ),
                            child: Stack(
                              children: [
                                if (record['employee_profile_url'] != null &&
                                    record['employee_profile_url'].isNotEmpty)
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
                                          return Icon(Icons.person,
                                              color: iconSecondaryColor);
                                        },
                                      ),
                                    ),
                                  ),
                                if (record['employee_profile_url'] == null ||
                                    record['employee_profile_url'].isEmpty)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: disabledColor,
                                      ),
                                      child: const Icon(Icons.person),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(
                              width: MediaQuery.of(context).size.width * 0.01),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fullName ?? '',
                                  style: const TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold),
                                  maxLines: 2,
                                ),
                                Text(
                                  record['badge_id'] != null
                                      ? '${record['badge_id']}'
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
                                  color: borderLightColor,
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                              ),
                              SizedBox(
                                  width: MediaQuery.of(context).size.width *
                                      0.008),
                              Container(
                                decoration: BoxDecoration(
                                  color: borderLightColor,
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.05),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Date',
                            style: TextStyle(color: grey700),
                          ),
                          Text('${record['attendance_date'] ?? 'None'}'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Check-In',
                            style: TextStyle(color: grey700),
                          ),
                          Text('${record['attendance_clock_in'] ?? 'None'}'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Check-Out',
                            style: TextStyle(color: grey700),
                          ),
                          Text('${record['attendance_clock_out'] ?? 'None'}'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Shift',
                            style: TextStyle(color: grey700),
                          ),
                          Text('${record['shift_name'] ?? 'None'}'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Minimum Hour',
                            style: TextStyle(color: grey700),
                          ),
                          Text('${record['minimum_hour'] ?? 'None'}'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Check-In Date',
                            style: TextStyle(color: grey700),
                          ),
                          Text(
                              '${record['attendance_clock_in_date'] ?? 'None'}'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Check-Out Date',
                            style: TextStyle(color: grey700),
                          ),
                          Text(
                              '${record['attendance_clock_out_date'] ?? 'None'}'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'At Work',
                            style: TextStyle(color: grey700),
                          ),
                          Text('${record['attendance_worked_hour'] ?? 'None'}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: !record['attendance_overtime_approve']
                      ? ElevatedButton(
                    onPressed: () async {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor: whiteColor,
                            title: Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Confirmation",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: blackColor),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    Navigator.of(context).pop(true);
                                  },
                                ),
                              ],
                            ),
                            content: SizedBox(
                              height: MediaQuery.of(context).size.height *
                                  0.1,
                              child: Center(
                                child: Text(
                                  'Are you sure you want to Validate this Attendance?',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: blackColor,
                                    fontSize: 17,
                                  ),
                                ),
                              ),
                            ),
                            actions: [
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    Map<String, dynamic>
                                    validatedDetails = {
                                      "id": record['id'],
                                    };
                                    await validateOverTime(
                                        validatedDetails);
                                    Navigator.of(context).pop();
                                    Navigator.of(context).pop();
                                    showValidateAnimation();
                                  },
                                  style: ButtonStyle(
                                    backgroundColor:
                                    MaterialStateProperty.all<Color>(
                                        successColor),
                                    shape: MaterialStateProperty.all<
                                        RoundedRectangleBorder>(
                                      RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(6.0),
                                      ),
                                    ),
                                  ),
                                  child: Text('Validate',
                                      style:
                                      TextStyle(color: whiteColor)),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: successColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal:
                        MediaQuery.of(context).size.width * 0.20,
                        vertical:
                        MediaQuery.of(context).size.height * 0.001,
                      ),
                    ),
                    child: Text(
                      "Validate",
                      style: TextStyle(fontSize: 18, color: whiteColor),
                    ),
                  )
                      : const SizedBox.shrink(),
                ),
              ],
            );
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.all(8.0),
        color: whiteColor,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: grey100),
            borderRadius: BorderRadius.circular(8.0),
            color: whiteColor,
            boxShadow: [
              BoxShadow(
                color: disabledColor.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Card(
            shape: RoundedRectangleBorder(
              side: BorderSide(color: whiteColor, width: 0.0),
              borderRadius: BorderRadius.circular(10.0),
            ),
            color: whiteColor,
            elevation: 0.1, //
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
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: grey300, width: 1.0),
                        ),
                        child: Stack(
                          children: [
                            if (record['employee_profile_url'] != null &&
                                record['employee_profile_url'].isNotEmpty)
                              Positioned.fill(
                                child: ClipOval(
                                  child: Image.network(
                                    baseUrl + record['employee_profile_url'],
                                    headers: {
                                      "Authorization": "Bearer $token",
                                    },
                                    fit: BoxFit.cover,
                                    errorBuilder: (BuildContext context,
                                        Object exception,
                                        StackTrace? stackTrace) {
                                      return Icon(Icons.person,
                                          color: iconSecondaryColor);
                                    },
                                  ),
                                ),
                              ),
                            if (record['employee_profile_url'] == null ||
                                record['employee_profile_url'].isEmpty)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: disabledColor,
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
                              fullName ?? '',
                              style: const TextStyle(
                                  fontSize: 16.0, fontWeight: FontWeight.bold),
                              maxLines: 2,
                            ),
                            Text(
                              record['badge_id'] != null
                                  ? '${record['badge_id']}'
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
                          Visibility(
                            visible: !record['attendance_overtime_approve'],
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(15.0),
                                  bottomLeft: Radius.circular(15.0),
                                ),
                                color: infoColor.withOpacity(0.3),
                              ),
                              child: Padding(
                                padding:
                                const EdgeInsets.symmetric(vertical: 0.0),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.edit,
                                    size: 18.0,
                                    color: infoColor,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      isSaveClick = true;
                                      _errorMessage = null;
                                      isAction = false;
                                    });
                                    _showValidateOvertimeAttendance(
                                        context, record);
                                  },
                                ),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: !record['attendance_overtime_approve'],
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(15.0),
                                  bottomRight: Radius.circular(15.0),
                                ),
                                color: errorBackgroundColor,
                              ),
                              child: Padding(
                                padding:
                                const EdgeInsets.symmetric(vertical: 0.0),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    size: 18.0, // Reduce icon size
                                    color: redColor, // Set icon color
                                  ),
                                  onPressed: () async {
                                    isSaveClick = true;
                                    await showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          backgroundColor: whiteColor,
                                          title: Row(
                                            mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "Confirmation",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: blackColor,
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.close),
                                                onPressed: () {
                                                  Navigator.of(context).pop(
                                                      true); // Close the dialog
                                                },
                                              ),
                                            ],
                                          ),
                                          content: SizedBox(
                                            height: MediaQuery.of(context)
                                                .size
                                                .height *
                                                0.1,
                                            child: Center(
                                              child: Text(
                                                "Are you sure you want to delete this attendance?",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: blackColor,
                                                  fontSize: 17,
                                                ),
                                              ),
                                            ),
                                          ),
                                          actions: [
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                onPressed: () async {
                                                  if (isSaveClick == true) {
                                                    isSaveClick = false;
                                                    Map<String, dynamic>
                                                    deletedDetails = {
                                                      'id': record['id'],
                                                    };
                                                    await deleteAttendance(
                                                        deletedDetails);
                                                    Navigator.of(context)
                                                        .pop(true);
                                                    showDeleteAnimation();
                                                  }
                                                },
                                                style: ButtonStyle(
                                                  backgroundColor:
                                                  MaterialStateProperty.all<
                                                      Color>(redColor),
                                                  shape:
                                                  MaterialStateProperty.all<
                                                      RoundedRectangleBorder>(
                                                    RoundedRectangleBorder(
                                                      borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                    ),
                                                  ),
                                                ),
                                                child: Text(
                                                  "Continue",
                                                  style: TextStyle(
                                                      color: whiteColor),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Date',
                        style: TextStyle(color: grey700),
                      ),
                      Text('${record['attendance_date'] ?? 'None'}'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Check-In',
                        style: TextStyle(color: grey700),
                      ),
                      Text('${record['attendance_clock_in'] ?? 'None'}'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Shift',
                        style: TextStyle(color: grey700),
                      ),
                      Text('${record['shift_name'] ?? 'None'}'),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                  Visibility(
                    visible: !record['attendance_overtime_approve'],
                    // Hide if attendance is validated
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            isSaveClick = true;
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  backgroundColor: whiteColor,
                                  title: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Confirmation",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: blackColor),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close),
                                        onPressed: () {
                                          Navigator.of(context).pop(true);
                                        },
                                      ),
                                    ],
                                  ),
                                  content: SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.1,
                                    child: Center(
                                      child: Text(
                                        'Do you want to Validate this Attendance?',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: blackColor,
                                          fontSize: 17,
                                        ),
                                      ),
                                    ),
                                  ),
                                  actions: [
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          if (isSaveClick == true) {
                                            isSaveClick = false;
                                            Map<String, dynamic>
                                            validatedDetails = {
                                              "id": record['id'],
                                            };
                                            await validateOverTime(
                                                validatedDetails);
                                            Navigator.of(context).pop(true);
                                            showValidateAnimation();
                                          }
                                        },
                                        style: ButtonStyle(
                                          backgroundColor:
                                          MaterialStateProperty.all<Color>(
                                              successColor),
                                          shape: MaterialStateProperty.all<
                                              RoundedRectangleBorder>(
                                            RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius.circular(6.0),
                                            ),
                                          ),
                                        ),
                                        child: Text('Continue',
                                            style:
                                            TextStyle(color: whiteColor)),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: successColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal:
                              MediaQuery.of(context).size.width * 0.30,
                              vertical:
                              MediaQuery.of(context).size.height * 0.01,
                            ),
                          ),
                          child: Text(
                            'Validate',
                            style: TextStyle(fontSize: 18, color: whiteColor),
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
      ),
    );
  }

  Widget buildValidatedAttendance(
      Map<String, dynamic> record, fullName, String profile, baseUrl, token) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: whiteColor,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(" "),
                  IconButton(
                    icon: Icon(Icons.close, color: iconSecondaryColor),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.95,
                height: MediaQuery.of(context).size.height * 0.5,
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
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border:
                              Border.all(color: grey300, width: 1.0),
                            ),
                            child: Stack(
                              children: [
                                if (record['employee_profile_url'] != null &&
                                    record['employee_profile_url'].isNotEmpty)
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
                                          return Icon(Icons.person,
                                              color: iconSecondaryColor);
                                        },
                                      ),
                                    ),
                                  ),
                                if (record['employee_profile_url'] == null ||
                                    record['employee_profile_url'].isEmpty)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: disabledColor,
                                      ),
                                      child: const Icon(Icons.person),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(
                              width: MediaQuery.of(context).size.width * 0.01),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fullName ?? '',
                                  style: const TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold),
                                  maxLines: 2,
                                ),
                                Text(
                                  record['badge_id'] != null
                                      ? '${record['badge_id']}'
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
                                  color: borderLightColor,
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                              ),
                              SizedBox(
                                  width: MediaQuery.of(context).size.width *
                                      0.008),
                              Container(
                                decoration: BoxDecoration(
                                  color: borderLightColor,
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.05),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Date',
                            style: TextStyle(color: grey700),
                          ),
                          Text('${record['attendance_date'] ?? 'None'}'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Check-In',
                            style: TextStyle(color: grey700),
                          ),
                          Text('${record['attendance_clock_in'] ?? 'None'}'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Check-Out',
                            style: TextStyle(color: grey700),
                          ),
                          Text('${record['attendance_clock_out'] ?? 'None'}'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Shift',
                            style: TextStyle(color: grey700),
                          ),
                          Text('${record['shift_name'] ?? 'None'}'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Minimum Hour',
                            style: TextStyle(color: grey700),
                          ),
                          Text('${record['minimum_hour'] ?? 'None'}'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Check-In Date',
                            style: TextStyle(color: grey700),
                          ),
                          Text(
                              '${record['attendance_clock_in_date'] ?? 'None'}'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Check-Out Date',
                            style: TextStyle(color: grey700),
                          ),
                          Text(
                              '${record['attendance_clock_out_date'] ?? 'None'}'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'At Work',
                            style: TextStyle(color: grey700),
                          ),
                          Text('${record['attendance_worked_hour'] ?? 'None'}'),
                        ],
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.01),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.all(8.0),
        color: whiteColor,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: grey100),
            borderRadius: BorderRadius.circular(8.0),
            color: whiteColor,
            boxShadow: [
              BoxShadow(
                color: disabledColor.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Card(
            shape: RoundedRectangleBorder(
              side: BorderSide(color: whiteColor, width: 0.0),
              borderRadius: BorderRadius.circular(10.0),
            ),
            color: whiteColor,
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
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: grey300, width: 1.0),
                        ),
                        child: Stack(
                          children: [
                            if (record['employee_profile_url'] != null &&
                                record['employee_profile_url'].isNotEmpty)
                              Positioned.fill(
                                child: ClipOval(
                                  child: Image.network(
                                    baseUrl + record['employee_profile_url'],
                                    headers: {
                                      "Authorization": "Bearer $token",
                                    },
                                    fit: BoxFit.cover,
                                    errorBuilder: (BuildContext context,
                                        Object exception,
                                        StackTrace? stackTrace) {
                                      return Icon(Icons.person,
                                          color: iconSecondaryColor);
                                    },
                                  ),
                                ),
                              ),
                            if (record['employee_profile_url'] == null ||
                                record['employee_profile_url'].isEmpty)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: disabledColor,
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
                              fullName ?? '',
                              style: const TextStyle(
                                  fontSize: 16.0, fontWeight: FontWeight.bold),
                              maxLines: 2,
                            ),
                            Text(
                              record['badge_id'] != null
                                  ? '${record['badge_id']}'
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
                  SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Date',
                        style: TextStyle(color: grey700),
                      ),
                      Text(record['attendance_date'] ?? 'None'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Check-In',
                        style: TextStyle(color: grey700),
                      ),
                      Text(record['attendance_clock_in'] ?? 'None'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Shift',
                        style: TextStyle(color: grey700),
                      ),
                      Text(record['shift_name'] ?? 'None'),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;

    if (text.length == 1 && int.tryParse(text)! > 2) {
      return TextEditingValue(
          text: '0$text:', selection: const TextSelection.collapsed(offset: 3));
    } else if (text.length == 3) {
      return TextEditingValue(
          text: '${text.substring(0, 2)}:${text.substring(2)}',
          selection: const TextSelection.collapsed(offset: 4));
    } else if (text.length == 4) {
      return TextEditingValue(
          text: '${text.substring(0, 2)}:${text.substring(2)}',
          selection: const TextSelection.collapsed(offset: 5));
    } else if (text.length > 5) {
      return TextEditingValue(
        text: text.substring(0, 5),
        selection: const TextSelection.collapsed(offset: 5),
      );
    }
    return newValue;
  }
}
