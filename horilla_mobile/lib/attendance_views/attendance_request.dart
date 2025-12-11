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

class AttendanceRequest extends StatefulWidget {
  const AttendanceRequest({super.key});

  @override
  _AttendanceRequest createState() => _AttendanceRequest();
}

class _AttendanceRequest extends State<AttendanceRequest>
    with SingleTickerProviderStateMixin {
  Map<String, String> employeeIdMap = {};
  Map<String, String> shiftIdMap = {};
  Map<String, String> workTypeIdMap = {};
  List<Map<String, dynamic>> filteredRequestedAttendanceRecords = [];
  List<Map<String, dynamic>> filteredAllAttendanceRecords = [];
  List<Map<String, dynamic>> requestsAllRequestedAttendances = [];
  List<Map<String, dynamic>> requestsAllAttendances = [];
  List<Map<String, dynamic>> allEmployeeList = [];
  List<String> shiftDetails = [];
  List<String> workTypeDetails = [];
  bool _validateEmployee = false;
  bool permissionCheck = false;
  bool _validateDate = false;
  bool _validateShift = false;
  bool _validateWorkType = false;
  String searchText = '';
  String workHoursSpent = '';
  String minimumHoursSpent = '';
  String checkInHoursSpent = '';
  String checkOutHoursSpent = '';
  String? createShift;
  String? createWorkType;
  String? _errorMessage;
  String? selectedShiftId;
  String? selectedWorkTypeId;
  String? createEmployee;
  String? selectedEmployeeId;
  late String baseUrl = '';
  late Map<String, dynamic> arguments;
  var employeeItems = [''];
  final List<Widget> bottomBarPages = [];
  final TextEditingController _typeAheadCreateShiftController =
      TextEditingController();
  final TextEditingController _typeAheadCreateWorkTypeController =
      TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  final _controller = NotchBottomBarController(index: -1);
  final TextEditingController _typeAheadController = TextEditingController();
  TextEditingController attendanceDateController = TextEditingController();
  TextEditingController workedHoursController = TextEditingController();
  TextEditingController minimumHourController = TextEditingController();
  TextEditingController checkInHoursController = TextEditingController();
  TextEditingController checkoutHoursController = TextEditingController();
  TextEditingController checkOutDateController = TextEditingController();
  TextEditingController checkInDateController = TextEditingController();
  int currentPage = 1;
  int maxCount = 5;
  int allRequestAttendance = 0;
  int myRequestAttendance = 0;
  bool isLoading = true;
  bool isAction = true;
  bool _validateCheckInDate = false;
  bool _validateCheckIn = false;
  bool _validateCheckoutDate = false;
  bool _validateCheckout = false;
  bool _validateWorkingHours = false;
  bool _validateMinimumHours = false;
  bool isSaveClick = true;
  bool permissionOverview = true;
  bool permissionAttendance = false;
  bool permissionAttendanceRequest = false;
  bool permissionHourAccount = false;
  Timer? _debounce;

  bool _drawerPermissionOverview = false;
  bool _drawerPermissionAttendance = false;
  bool _drawerPermissionAttendanceRequest = false;
  bool _drawerPermissionHourAccount = false;
  bool _isPermissionCheckComplete = false;
  late String getToken = '';

  @override
  void initState() {
    super.initState();
    prefetchData();
    _scrollController.addListener(_scrollListener);
    getAllRequestedAttendances();
    getAllAttendances();
    getBaseUrl();
    getEmployees();
    getShiftDetails();
    getWorkTypeDetails();
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

  Future<void> fetchToken() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    setState(() {
      getToken = token ?? '';
    });
  }

  Future<void> _simulateLoading() async {
    await Future.delayed(const Duration(seconds: 5));
    setState(() {});
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange) {
      currentPage++;
      getAllRequestedAttendances();
      getAllAttendances();
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
                    const Text(
                      "Attendance Created Successfully",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red),
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
                    const Text(
                      "Attendance Approved Successfully",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red),
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

  void showRejectAnimation() {
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
                    const Text(
                      "Attendance Rejected Successfully",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red),
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

  Future<void> getEmployees() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");

    employeeItems.clear();
    employeeIdMap.clear();
    allEmployeeList.clear();

    for (var page = 1;; page++) {
      var uri = Uri.parse(
        '$typedServerUrl/api/employee/employee-selector?page=$page',
      );

      var response = await http.get(uri, headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = List<Map<String, dynamic>>.from(data['results']);

        if (results.isEmpty) break; // ✅ Stop if there are no more employees

        setState(() {
          for (var employee in results) {
            final firstName = employee['employee_first_name'] ?? '';
            final lastName = employee['employee_last_name'] ?? '';
            final fullName = '$firstName $lastName'.trim();
            final employeeId = "${employee['id']}";

            employeeItems.add(fullName);
            employeeIdMap[fullName] = employeeId;
          }

          allEmployeeList.addAll(results);
        });
      } else {
        print('Error fetching employees (status: ${response.statusCode})');
        break;
      }
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

  Future<void> getWorkTypeDetails() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/base/worktypes');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      setState(() {
        for (var rec in jsonDecode(response.body)) {
          String workType = "${rec['work_type']}";
          String workTypeId = "${rec['id']}";
          workTypeDetails.add(rec['work_type']);
          workTypeIdMap[workType] = workTypeId;
        }
      });
    }
  }

  Future<void> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    setState(() {
      baseUrl = typedServerUrl ?? '';
    });
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
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
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

  void showCreateAttendanceDialog(BuildContext context) {
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
                      const Text(
                        "Add Attendance",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.black),
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
                                style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.03),
                          const Text(
                            'Employee',
                            style: TextStyle(color: Colors.black),
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.01),
                          TypeAheadField<String>(
                            textFieldConfiguration: TextFieldConfiguration(
                              controller: _typeAheadController,
                              decoration: InputDecoration(
                                labelText: 'Search Employee',
                                border: const OutlineInputBorder(),
                                labelStyle: TextStyle(color: Colors.grey[350]),
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
                                  maxHeight:
                                      MediaQuery.of(context).size.height *
                                          0.23), // Limit height
                            ),
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.03),
                          const Text(
                            "Attendance Date",
                            style: TextStyle(color: Colors.black),
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
                                  _validateDate = false;
                                });
                              }
                            },
                            decoration: InputDecoration(
                              labelText: "Attendance Date",
                              labelStyle: TextStyle(color: Colors.grey[350]),
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
                          const Text(
                            "Shift",
                            style: TextStyle(color: Colors.black),
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.01),
                          TypeAheadField<String>(
                            textFieldConfiguration: TextFieldConfiguration(
                              controller: _typeAheadCreateShiftController,
                              decoration: InputDecoration(
                                labelText: 'Search Shift',
                                errorText: _validateShift
                                    ? 'Please select a Shift'
                                    : null,
                                labelStyle: TextStyle(color: Colors.grey[350]),
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
                                  maxHeight:
                                      MediaQuery.of(context).size.height *
                                          0.23), // Limit height
                            ),
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.03),
                          const Text(
                            "Work Type ",
                            style: TextStyle(color: Colors.black),
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.01),
                          TypeAheadField<String>(
                            textFieldConfiguration: TextFieldConfiguration(
                              controller: _typeAheadCreateWorkTypeController,
                              decoration: InputDecoration(
                                labelText: 'Search Shift',
                                labelStyle: TextStyle(color: Colors.grey[350]),
                                border: const OutlineInputBorder(),
                                errorText: _validateWorkType
                                    ? 'Please select a Work Type'
                                    : null,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10.0),
                              ),
                            ),
                            suggestionsCallback: (pattern) {
                              return workTypeDetails
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
                                createWorkType = suggestion;
                                selectedWorkTypeId = shiftIdMap[suggestion];
                                _validateWorkType = false;
                              });
                              _typeAheadCreateWorkTypeController.text =
                                  suggestion;
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
                                  maxHeight:
                                      MediaQuery.of(context).size.height *
                                          0.23), // Limit height
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
                                    const Text(
                                      'Check-In Date',
                                      style: TextStyle(color: Colors.black),
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
                                        errorText: _validateCheckInDate
                                            ? 'Please Choose Check-In Date'
                                            : null,
                                        labelStyle:
                                            TextStyle(color: Colors.grey[350]),
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
                                    const Text(
                                      'Check-In',
                                      style: TextStyle(color: Colors.black),
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
                                            TextStyle(color: Colors.grey[350]),
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
                                    const Text(
                                      'Check-Out Date',
                                      style: TextStyle(color: Colors.black),
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
                                            _validateCheckoutDate = false;
                                          });
                                        }
                                      },
                                      decoration: InputDecoration(
                                        labelText: "Check-Out Date",
                                        errorText: _validateCheckoutDate
                                            ? 'Please Choose a Check-Out Date'
                                            : null,
                                        labelStyle:
                                            TextStyle(color: Colors.grey[350]),
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
                                    const Text(
                                      'Check-Out',
                                      style: TextStyle(color: Colors.black),
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
                                        _validateCheckout = false;
                                      },
                                      decoration: InputDecoration(
                                        labelText: '00:00',
                                        errorText: _validateCheckout
                                            ? 'Please Choose a Check-Out'
                                            : null,
                                        labelStyle:
                                            TextStyle(color: Colors.grey[350]),
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
                                              checkoutHoursController.text =
                                                  '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                              checkOutHoursSpent =
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
                                    const Text(
                                      'Working Hours',
                                      style: TextStyle(color: Colors.black),
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
                                        errorText: _validateWorkingHours
                                            ? 'Please add Working Hours'
                                            : null,
                                        labelStyle:
                                            TextStyle(color: Colors.grey[350]),
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
                                    const Text(
                                      'Minimum Hour',
                                      style: TextStyle(color: Colors.black),
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
                                        errorText: _validateMinimumHours
                                            ? 'Please add Minimum Hours'
                                            : null,
                                        labelStyle:
                                            TextStyle(color: Colors.grey[350]),
                                        border: const OutlineInputBorder(),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 10.0),
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
                                _validateEmployee = true;
                                _validateDate = false;
                                _validateShift = false;
                                _validateWorkType = false;
                                _validateCheckInDate = false;
                                _validateCheckIn = false;
                                _validateCheckoutDate = false;
                                _validateCheckout = false;
                                _validateWorkingHours = false;
                                _validateMinimumHours = false;
                                Navigator.of(context).pop(true);
                                showCreateAttendanceDialog(context);
                              });
                            } else if (attendanceDateController.text.isEmpty) {
                              setState(() {
                                isAction = false;
                                isSaveClick = true;
                                _validateEmployee = false;
                                _validateDate = true;
                                _validateShift = false;
                                _validateWorkType = false;
                                _validateCheckInDate = false;
                                _validateCheckIn = false;
                                _validateCheckoutDate = false;
                                _validateCheckout = false;
                                _validateWorkingHours = false;
                                _validateMinimumHours = false;
                                Navigator.of(context).pop(true);
                                showCreateAttendanceDialog(context);
                              });
                            } else if (createShift == null) {
                              setState(() {
                                isAction = false;
                                isSaveClick = true;
                                _validateEmployee = false;
                                _validateDate = false;
                                _validateShift = true;
                                _validateWorkType = false;
                                _validateCheckInDate = false;
                                _validateCheckIn = false;
                                _validateCheckoutDate = false;
                                _validateCheckout = false;
                                _validateWorkingHours = false;
                                _validateMinimumHours = false;
                                Navigator.of(context).pop(true);
                                showCreateAttendanceDialog(context);
                              });
                            } else if (createWorkType == null) {
                              setState(() {
                                isAction = false;
                                isSaveClick = true;
                                _validateEmployee = false;
                                _validateDate = false;
                                _validateShift = false;
                                _validateWorkType = true;
                                _validateCheckInDate = false;
                                _validateCheckIn = false;
                                _validateCheckoutDate = false;
                                _validateCheckout = false;
                                _validateWorkingHours = false;
                                _validateMinimumHours = false;
                                Navigator.of(context).pop(true);
                                showCreateAttendanceDialog(context);
                              });
                            } else if (checkInDateController.text.isEmpty) {
                              setState(() {
                                isAction = false;
                                isSaveClick = true;
                                _validateEmployee = false;
                                _validateDate = false;
                                _validateShift = false;
                                _validateWorkType = false;
                                _validateCheckInDate = true;
                                _validateCheckIn = false;
                                _validateCheckoutDate = false;
                                _validateCheckout = false;
                                _validateWorkingHours = false;
                                _validateMinimumHours = false;
                                Navigator.of(context).pop(true);
                                showCreateAttendanceDialog(context);
                              });
                            } else if (checkInHoursController.text.isEmpty) {
                              setState(() {
                                isAction = false;
                                isSaveClick = true;
                                _validateEmployee = false;
                                _validateDate = false;
                                _validateShift = false;
                                _validateWorkType = false;
                                _validateCheckInDate = false;
                                _validateCheckIn = true;
                                _validateCheckoutDate = false;
                                _validateCheckout = false;
                                _validateWorkingHours = false;
                                _validateMinimumHours = false;
                                Navigator.of(context).pop(true);
                                showCreateAttendanceDialog(context);
                              });
                            } else if (checkOutDateController.text.isEmpty) {
                              setState(() {
                                isAction = false;
                                isSaveClick = true;
                                _validateEmployee = false;
                                _validateDate = false;
                                _validateShift = false;
                                _validateWorkType = false;
                                _validateCheckInDate = false;
                                _validateCheckIn = false;
                                _validateCheckoutDate = true;
                                _validateCheckout = false;
                                _validateWorkingHours = false;
                                _validateMinimumHours = false;
                                Navigator.of(context).pop(true);
                                showCreateAttendanceDialog(context);
                              });
                            } else if (checkoutHoursController.text.isEmpty) {
                              setState(() {
                                isAction = false;
                                isSaveClick = true;
                                _validateEmployee = false;
                                _validateDate = false;
                                _validateShift = false;
                                _validateWorkType = false;
                                _validateCheckInDate = false;
                                _validateCheckIn = false;
                                _validateCheckoutDate = false;
                                _validateCheckout = true;
                                _validateWorkingHours = false;
                                _validateMinimumHours = false;
                                Navigator.of(context).pop(true);
                                showCreateAttendanceDialog(context);
                              });
                            } else if (workedHoursController.text.isEmpty) {
                              setState(() {
                                isAction = false;
                                isSaveClick = true;
                                _validateEmployee = false;
                                _validateDate = false;
                                _validateShift = false;
                                _validateWorkType = false;
                                _validateCheckInDate = false;
                                _validateCheckIn = false;
                                _validateCheckoutDate = false;
                                _validateCheckout = false;
                                _validateWorkingHours = true;
                                _validateMinimumHours = false;
                                Navigator.of(context).pop(true);
                                showCreateAttendanceDialog(context);
                              });
                            } else if (minimumHourController.text.isEmpty) {
                              setState(() {
                                isAction = false;
                                isSaveClick = true;
                                _validateEmployee = false;
                                _validateDate = false;
                                _validateShift = false;
                                _validateWorkType = false;
                                _validateCheckInDate = false;
                                _validateCheckIn = false;
                                _validateCheckoutDate = false;
                                _validateCheckout = false;
                                _validateWorkingHours = false;
                                _validateMinimumHours = true;
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
                                'work_type_id': selectedWorkTypeId ?? '',
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
                              MaterialStateProperty.all<Color>(Colors.red),
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6.0),
                            ),
                          ),
                        ),
                        child: const Text('Save',
                            style: TextStyle(color: Colors.white)),
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

  Future<void> getAllRequestedAttendances() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    if (currentPage != 0) {
      var uri = Uri.parse(
          '$typedServerUrl/api/attendance/attendance-request/?page=$currentPage&search=$searchText');
      var response = await http.get(uri, headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });
      if (response.statusCode == 200) {
        setState(() {
          requestsAllRequestedAttendances.addAll(
            List<Map<String, dynamic>>.from(
              jsonDecode(response.body)['results'],
            ),
          );
          String serializeMap(Map<String, dynamic> map) {
            return jsonEncode(map);
          }

          Map<String, dynamic> deserializeMap(String jsonString) {
            return jsonDecode(jsonString);
          }

          List<String> mapStrings =
              requestsAllRequestedAttendances.map(serializeMap).toList();
          Set<String> uniqueMapStrings = mapStrings.toSet();
          requestsAllRequestedAttendances =
              uniqueMapStrings.map(deserializeMap).toList();

          allRequestAttendance = jsonDecode(response.body)['count'];
          filteredRequestedAttendanceRecords =
              filterRequestedAttendanceRecords(searchText);
          setState(() {
            isLoading = false;
          });
        });
      }
    } else {
      currentPage = 1;
      var uri = Uri.parse(
          '$typedServerUrl/api/attendance/attendance-request/?search=$searchText');
      var response = await http.get(uri, headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });
      if (response.statusCode == 200) {
        setState(() {
          requestsAllRequestedAttendances = List<Map<String, dynamic>>.from(
            jsonDecode(response.body)['results'],
          );

          String serializeMap(Map<String, dynamic> map) {
            return jsonEncode(map);
          }

          Map<String, dynamic> deserializeMap(String jsonString) {
            return jsonDecode(jsonString);
          }

          List<String> mapStrings =
              requestsAllRequestedAttendances.map(serializeMap).toList();
          Set<String> uniqueMapStrings = mapStrings.toSet();
          requestsAllRequestedAttendances =
              uniqueMapStrings.map(deserializeMap).toList();

          allRequestAttendance = jsonDecode(response.body)['count'];
          filteredRequestedAttendanceRecords =
              filterRequestedAttendanceRecords(searchText);
          setState(() {
            isLoading = false;
          });
        });
      }
    }
  }

  Future<void> createNewAttendance(Map<String, dynamic> createdDetails) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/attendance/attendance-request/');
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
        "work_type_id": createdDetails['work_type_id'],
      }),
    );
    if (response.statusCode == 200) {
      isSaveClick = false;
      _errorMessage = null;
      currentPage = 0;
      getAllRequestedAttendances();
      getAllAttendances();
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
      // Handle error if needed
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

  Future<void> getAllAttendances() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    prefs.getInt("employee_id");
    if (currentPage != 0) {
      var uri = Uri.parse(
          '$typedServerUrl/api/attendance/attendance/?page=$currentPage&search=$searchText');
      var response = await http.get(uri, headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });
      if (response.statusCode == 200) {
        setState(() {
          requestsAllAttendances.addAll(
            List<Map<String, dynamic>>.from(
              jsonDecode(response.body)['results'],
            ),
          );
          String serializeMap(Map<String, dynamic> map) {
            return jsonEncode(map);
          }

          Map<String, dynamic> deserializeMap(String jsonString) {
            return jsonDecode(jsonString);
          }

          List<String> mapStrings =
              requestsAllAttendances.map(serializeMap).toList();
          Set<String> uniqueMapStrings = mapStrings.toSet();
          requestsAllAttendances =
              uniqueMapStrings.map(deserializeMap).toList();

          myRequestAttendance = jsonDecode(response.body)['count'];
          filteredAllAttendanceRecords = filterAllAttendanceRecords(searchText);
          isLoading = false;
        });
      }
    } else {
      currentPage = 1;
      var uri = Uri.parse(
          '$typedServerUrl/api/attendance/attendance/?search=$searchText');
      var response = await http.get(uri, headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });
      if (response.statusCode == 200) {
        setState(() {
          requestsAllAttendances = List<Map<String, dynamic>>.from(
            jsonDecode(response.body)['results'],
          );

          String serializeMap(Map<String, dynamic> map) {
            return jsonEncode(map);
          }

          Map<String, dynamic> deserializeMap(String jsonString) {
            return jsonDecode(jsonString);
          }

          List<String> mapStrings =
              requestsAllAttendances.map(serializeMap).toList();
          Set<String> uniqueMapStrings = mapStrings.toSet();
          requestsAllAttendances =
              uniqueMapStrings.map(deserializeMap).toList();
          myRequestAttendance = jsonDecode(response.body)['count'];
          filteredAllAttendanceRecords =
              filterRequestedAttendanceRecords(searchText);
          setState(() {
            isLoading = false;
          });
        });
      }
    }
  }

  List<Map<String, dynamic>> filterRequestedAttendanceRecords(
      String searchText) {
    if (searchText.isEmpty) {
      return requestsAllRequestedAttendances;
    } else {
      return requestsAllRequestedAttendances.where((record) {
        final firstName = record['employee_first_name'] ?? '';
        final lastName = record['employee_last_name'] ?? '';
        final fullName = (firstName + ' ' + lastName).toLowerCase();
        return fullName.contains(searchText.toLowerCase());
      }).toList();
    }
  }

  List<Map<String, dynamic>> filterAllAttendanceRecords(String searchText) {
    if (searchText.isEmpty) {
      return requestsAllAttendances;
    } else {
      return requestsAllAttendances.where((record) {
        final firstName = record['employee_first_name'] ?? '';
        final lastName = record['employee_last_name'] ?? '';
        final fullName = (firstName + ' ' + lastName).toLowerCase();
        return fullName.contains(searchText.toLowerCase());
      }).toList();
    }
  }

  Future<void> rejectLeave(record) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    int requestId = record;
    var uri = Uri.parse(
        '$typedServerUrl/api/attendance/attendance-request-cancel/$requestId');
    var response = await http.put(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      setState(() {
        isSaveClick = false;
        requestsAllRequestedAttendances
            .removeWhere((item) => item['id'] == requestId);
        currentPage = 0;
        getAllRequestedAttendances();
        getAllAttendances();
      });
    } else {
      isSaveClick = true;
    }
  }

  Future<void> approveRequest(record) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    int requestId = record;
    var uri = Uri.parse(
        '$typedServerUrl/api/attendance/attendance-request-approve/$requestId');
    var response = await http.put(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      setState(() {
        isSaveClick = false;
        requestsAllRequestedAttendances
            .removeWhere((item) => item['id'] == requestId);
        currentPage = 0;
        getAllRequestedAttendances();
        getAllAttendances();
      });
    } else {
      isSaveClick = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool permissionCheck =
        ModalRoute.of(context)?.settings.arguments != null
            ? ModalRoute.of(context)!.settings.arguments as bool
            : false;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        key: _scaffoldKey,
        appBar: AppBar(
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.menu), // Menu icon
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
          title: const Text(
            'Attendance Requests',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.all(12.0),
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
                          _validateEmployee = false;
                          _validateDate = false;
                          _validateShift = false;
                          _validateWorkType = false;
                          _validateCheckInDate = false;
                          _validateCheckIn = false;
                          _validateCheckoutDate = false;
                          _validateCheckout = false;
                          _validateWorkingHours = false;
                          _validateMinimumHours = false;
                          _typeAheadController.clear();
                          attendanceDateController.clear();
                          _typeAheadCreateShiftController.clear();
                          _typeAheadCreateWorkTypeController.clear();
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
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0),
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                      child: const Text('CREATE',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: isLoading ? _buildLoadingWidget() : _buildEmployeeDetailsWidget(),
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
                        // Only "Overview" has a permission check
                        _drawerPermissionOverview
                            ? ListTile(
                                title: const Text('Overview'),
                                onTap: () {
                                  Navigator.pushNamed(
                                      context, '/attendance_overview');
                                },
                              )
                            : const SizedBox.shrink(),

                        // All other menu items are always visible
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
                      // Loading state (shimmer effect)
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
                    // itemLabel: 'Home',
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
                        border: Border.all(color: Colors.grey),
                        color: Colors.white,
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
        TabBar(
          labelColor: Colors.red,
          indicatorColor: Colors.red,
          unselectedLabelColor: Colors.grey,
          isScrollable: true,
          tabs: [
            Tab(
              text: 'Requested Attendances ($allRequestAttendance)',
            ),
            Tab(
              text: 'All Attendances ($myRequestAttendance)',
            ),
          ],
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.03),
        Expanded(
          child: TabBarView(
            children: [
              buildRequestedLoadingAttendanceContent(
                  requestsAllRequestedAttendances,
                  _scrollController,
                  searchText),
              buildMyAllAttendanceLoadingContent(
                  requestsAllAttendances, _scrollController),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeeDetailsWidget() {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
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
                          border: Border.all(color: Colors.grey.shade50),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextField(
                          onChanged: (employeeSearchValue) {
                            if (_debounce?.isActive ?? false) {
                              _debounce!.cancel();
                            }
                            _debounce =
                                Timer(const Duration(milliseconds: 1000), () {
                              setState(() {
                                searchText = employeeSearchValue;
                                getAllRequestedAttendances();
                                getAllAttendances();
                              });
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide.none,
                            ),
                            hintStyle:
                                TextStyle(color: Colors.blueGrey.shade300),
                            filled: true,
                            fillColor: Colors.grey[100],
                            prefixIcon: Transform.scale(
                              scale: 0.8,
                              child: Icon(Icons.search,
                                  color: Colors.blueGrey.shade300),
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
              indicatorColor: Colors.red,
              labelColor: Colors.red,
              unselectedLabelColor: Colors.grey,
              isScrollable: true,
              tabs: [
                Tab(
                  text: 'Requested Attendances ($allRequestAttendance)',
                ),
                Tab(
                  text: 'All Attendances ($myRequestAttendance)',
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
            Expanded(
              child: TabBarView(
                children: [
                  allRequestAttendance == 0
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: ListView(
                              children: const [
                                Icon(
                                  Icons.inventory_outlined,
                                  color: Colors.black,
                                  size: 92,
                                ),
                                SizedBox(height: 20),
                                Center(
                                  child: Text(
                                    "There are no attendance records to display",
                                    style: TextStyle(
                                        fontSize: 16.0,
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : buildRequestedAttendanceContent(
                          requestsAllRequestedAttendances,
                          _scrollController,
                          searchText),
                  myRequestAttendance == 0
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: ListView(
                              children: const [
                                Icon(
                                  Icons.inventory_outlined,
                                  color: Colors.black,
                                  size: 92,
                                ),
                                SizedBox(height: 20),
                                Center(
                                  child: Text(
                                    "There are no attendance records to display",
                                    style: TextStyle(
                                        fontSize: 16.0,
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : buildMyAllAttendanceContent(
                          requestsAllAttendances, _scrollController),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildRequestedAttendanceContent(
      requestsAllRequestedAttendances, scrollController, searchText) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView.builder(
        controller: scrollController,
        shrinkWrap: true,
        itemCount: filteredRequestedAttendanceRecords.length,
        itemBuilder: (context, index) {
          final record = filteredRequestedAttendanceRecords[index];
          final firstName = record['employee_first_name'] ?? '';
          final lastName = record['employee_last_name'] ?? '';
          final fullName = (firstName.isEmpty ? '' : firstName) +
              (lastName.isEmpty ? '' : ' $lastName');
          final profile = record['employee_profile'];
          return buildRequestedAttendance(
              record, fullName, profile ?? "", baseUrl, getToken);
        },
      ),
    );
  }

  Widget buildRequestedLoadingAttendanceContent(
      List<Map<String, dynamic>> requestsAllRequestedAttendances,
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40.0,
                              height: 40.0,
                              color: Colors.grey[300],
                            ),
                          ],
                        ),
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.005),
                        Container(
                          height: 20.0,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 20.0,
                          width: 80.0,
                          color: Colors.grey[300],
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

  Widget buildMyAllAttendanceLoadingContent(
      List<Map<String, dynamic>> requestsAllAttendances, scrollController) {
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40.0,
                              height: 40.0,
                              color: Colors.grey[300],
                            ),
                          ],
                        ),
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.005),
                        Container(
                          height: 20.0,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 20.0,
                          width: 80.0,
                          color: Colors.grey[300],
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

  Widget buildMyAllAttendanceContent(
      List<Map<String, dynamic>> requestsAllAttendances, scrollController) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView.builder(
        controller: _scrollController,
        shrinkWrap: true,
        itemCount: searchText.isEmpty
            ? requestsAllAttendances.length
            : filteredAllAttendanceRecords.length,
        itemBuilder: (context, index) {
          final record = searchText.isEmpty
              ? requestsAllAttendances[index]
              : filteredAllAttendanceRecords[index];
          final firstName = record['employee_first_name'] ?? '';
          final lastName = record['employee_last_name'] ?? '';
          final fullName = (firstName.isEmpty ? '' : firstName) +
              (lastName.isEmpty ? '' : ' $lastName');
          final profile = record['employee_profile'];
          return buildMyAllAttendance(
              record, fullName, profile ?? "", baseUrl, getToken);
        },
      ),
    );
  }

  Widget buildRequestedAttendance(
      Map<String, dynamic> record, fullName, String profile, baseUrl, token) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(""),
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
                height: MediaQuery.of(context).size.height * 0.6,
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
                                  Border.all(color: Colors.grey, width: 1.0),
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
                                          return const Icon(Icons.person,
                                              color: Colors.grey);
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
                                        color: Colors.grey[400],
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
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                              ),
                              SizedBox(
                                  width: MediaQuery.of(context).size.width *
                                      0.008),
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
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.005),
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
                if (permissionCheck)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              isSaveClick = true;
                              await showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    backgroundColor: Colors.white,
                                    title: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          "Confirmation",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black),
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
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.1,
                                      child: const Center(
                                        child: Text(
                                          "Are you sure you want to Reject this request?",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                              fontSize: 17),
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
                                              await rejectLeave(record['id']);
                                              Navigator.of(context).pop(true);
                                              Navigator.of(context).pop(true);
                                              showRejectAnimation();
                                            }
                                          },
                                          style: ButtonStyle(
                                            backgroundColor:
                                                MaterialStateProperty.all<
                                                    Color>(Colors.red),
                                            shape: MaterialStateProperty.all<
                                                RoundedRectangleBorder>(
                                              RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                            ),
                                          ),
                                          child: const Text("Continue",
                                              style: TextStyle(
                                                  color: Colors.white)),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal:
                                    MediaQuery.of(context).size.width * 0.06,
                                vertical:
                                    MediaQuery.of(context).size.height * 0.01,
                              ),
                            ),
                            child: const Text(
                              "Reject",
                              style:
                                  TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          ),
                          SizedBox(
                              width: MediaQuery.of(context).size.width * 0.01),
                          ElevatedButton(
                            onPressed: () async {
                              await showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    backgroundColor: Colors.white,
                                    title: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          "Confirmation",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black),
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
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.1,
                                      child: const Center(
                                        child: Text(
                                          "Are you sure you want to Approve this Attendance?",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                              fontSize: 17),
                                        ),
                                      ),
                                    ),
                                    actions: [
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            await approveRequest(record['id']);
                                            Navigator.of(context).pop(true);
                                            Navigator.of(context).pop(true);
                                            showValidateAnimation();
                                          },
                                          style: ButtonStyle(
                                            backgroundColor:
                                                MaterialStateProperty.all<
                                                    Color>(Colors.green),
                                            shape: MaterialStateProperty.all<
                                                RoundedRectangleBorder>(
                                              RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                            ),
                                          ),
                                          child: const Text("Approve",
                                              style: TextStyle(
                                                  color: Colors.white)),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal:
                                    MediaQuery.of(context).size.width * 0.05,
                                vertical:
                                    MediaQuery.of(context).size.height * 0.01,
                              ),
                            ),
                            child: const Text(
                              "Approve",
                              style:
                                  TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
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
                          border: Border.all(color: Colors.grey, width: 1.0),
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
                                      return const Icon(Icons.person,
                                          color: Colors.grey);
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
                        'Shift',
                        style: TextStyle(color: grey700),
                      ),
                      Text('${record['shift_name'] ?? 'None'}'),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                  if (permissionCheck)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                isSaveClick = true;
                                await showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      backgroundColor: Colors.white,
                                      title: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            "Confirmation",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black),
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
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.1,
                                        child: const Center(
                                          child: Text(
                                            "Are you sure you want to Reject this Attendance?",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                                fontSize: 17),
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
                                                await rejectLeave(record['id']);
                                                Navigator.of(context).pop(true);
                                                showRejectAnimation();
                                              }
                                            },
                                            style: ButtonStyle(
                                              backgroundColor:
                                                  MaterialStateProperty.all<
                                                      Color>(Colors.red),
                                              shape: MaterialStateProperty.all<
                                                  RoundedRectangleBorder>(
                                                RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                              ),
                                            ),
                                            child: const Text("Continue",
                                                style: TextStyle(
                                                    color: Colors.white)),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal:
                                      MediaQuery.of(context).size.width * 0.09,
                                  vertical:
                                      MediaQuery.of(context).size.height * 0.01,
                                ),
                              ),
                              child: const Text(
                                "Reject",
                                style: TextStyle(
                                    fontSize: 18, color: Colors.white),
                              ),
                            ),
                            SizedBox(
                                width:
                                    MediaQuery.of(context).size.width * 0.02),
                            ElevatedButton(
                              onPressed: () async {
                                isSaveClick = true;
                                await showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      backgroundColor: Colors.white,
                                      title: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            "Confirmation",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black),
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
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.1,
                                        child: const Center(
                                          child: Text(
                                            "Are you sure you want to Approve this Attendance?",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                                fontSize: 17),
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
                                                await approveRequest(
                                                    record['id']);
                                                Navigator.of(context).pop(true);
                                                showValidateAnimation();
                                              }
                                            },
                                            style: ButtonStyle(
                                              backgroundColor:
                                                  MaterialStateProperty.all<
                                                      Color>(Colors.green),
                                              shape: MaterialStateProperty.all<
                                                  RoundedRectangleBorder>(
                                                RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                              ),
                                            ),
                                            child: const Text("Continue",
                                                style: TextStyle(
                                                    color: Colors.white)),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal:
                                      MediaQuery.of(context).size.width * 0.09,
                                  vertical:
                                      MediaQuery.of(context).size.height * 0.01,
                                ),
                              ),
                              child: const Text(
                                "Approve",
                                style: TextStyle(
                                    fontSize: 18, color: Colors.white),
                              ),
                            ),
                          ],
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

  Widget buildMyAllAttendance(
      Map<String, dynamic> record, fullName, String profile, baseUrl, token) {
    return Container(
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
                        border: Border.all(color: Colors.grey, width: 1.0),
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
                                    return const Icon(Icons.person,
                                        color: Colors.grey); // Fallback icon
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
                                fontSize: 12.0, fontWeight: FontWeight.normal),
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
                      onPressed: () {
                        Navigator.pushNamed(context, '/my_attendance_view',
                            arguments: {
                              'id': record['id'],
                              'employee_name': record['employee_first_name'] +
                                  ' ' +
                                  record['employee_last_name'],
                              'badge_id': record['badge_id'],
                              'shift_name': record['shift_name'],
                              'attendance_date': record['attendance_date'],
                              'attendance_clock_in_date':
                                  record['attendance_clock_in_date'],
                              'attendance_clock_in':
                                  record['attendance_clock_in'],
                              'attendance_clock_out_date':
                                  record['attendance_clock_out_date'],
                              'attendance_clock_out':
                                  record['attendance_clock_out'],
                              'attendance_worked_hour':
                                  record['attendance_worked_hour'],
                              'minimum_hour': record['minimum_hour'],
                              'employee_profile':
                                  record['employee_profile_url'],
                              'permission_check': permissionCheck,
                            });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal:
                                MediaQuery.of(context).size.width * 0.04,
                            vertical:
                                MediaQuery.of(context).size.height * 0.01),
                      ),
                      child: const Text(
                        "View Request",
                        style: TextStyle(fontSize: 18, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
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
