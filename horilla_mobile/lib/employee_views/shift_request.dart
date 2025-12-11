import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../res/consts/app_colors.dart';

class ShiftRequestPage extends StatefulWidget {
  final String selectedEmployerId;
  final String selectedEmployeeFullName;

  const ShiftRequestPage(
      {super.key,
        required this.selectedEmployerId,
        required this.selectedEmployeeFullName});

  @override
  _ShiftRequestPageState createState() => _ShiftRequestPageState();
}

class StateInfo {
  final Color color;
  final String displayString;

  StateInfo(this.color, this.displayString);
}

class _ShiftRequestPageState extends State<ShiftRequestPage> {
  TextEditingController yearController = TextEditingController();
  TextEditingController workedHoursController = TextEditingController();
  TextEditingController pendingHoursController = TextEditingController();
  TextEditingController overtimeHoursController = TextEditingController();
  TextEditingController createRequestedDateController = TextEditingController();
  TextEditingController createRequestedTillController = TextEditingController();
  TextEditingController descriptionSelect = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _typeAheadEditController =
  TextEditingController();
  final TextEditingController _typeCreateAheadController =
  TextEditingController();
  final TextEditingController _typeAheadEditShiftController =
  TextEditingController();
  final TextEditingController _typeAheadCreateShiftController =
  TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _pageController = PageController(initialPage: 0);
  final _controller = NotchBottomBarController(index: -1);
  String? _errorMessage;
  String searchText = '';
  String? editShift;
  String? selectedEditShift;
  String? selectedEmployee;
  String? createEmployee;
  String? createShift;
  String? selectedCreateShift;
  String employeeId = '';
  String selectedEmployeeFullName = '';
  String? selectedEditWorkType;
  String? editEmployee;
  String? selectedEditEmployeeId;
  String? selectedCreateEmployeeId;
  String? selectedCreateWorkType;
  List<String> workTypeItems = [];
  List<String> shiftDetails = [];
  List<Map<String, dynamic>> requests = [];
  List<dynamic> filteredRecords = [];
  List<String> months = [
    'Select Month',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];
  List employeeIdValue = [''];
  List<Map<String, dynamic>> allEmployeeList = [];
  int currentPage = 1;
  int? selectedEmployerId;
  int requestsCount = 0;
  int maxCount = 5;
  late Map<String, dynamic> arguments;
  late String baseUrl = '';
  var employeeItems = [''];
  var selectedMonth;
  bool permissionCheck = false;
  bool approveRejectCheck = false;
  bool isLoading = true;
  bool isAction = true;
  bool hasNoRecords = false;
  bool isSaveClick = true;
  bool _validateRequestedDate = false;
  bool _validateRequestedTill = false;
  bool _validateDescription = false;
  bool _validateShift = false;
  Map<String, String> workTypeIdMap = {};
  Map<String, String> shiftIdMap = {};
  Map<String, String> employeeIdMap = {};
  Map<String, dynamic> employeeDetails = {};
  bool isCreateButtonVisible = true;
  late String getToken = '';



  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    prefetchData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      permissionChecks();
      approveRejectChecks();
      getShiftRequest();
      getEmployees();
      getEmployeeDetails();
      getWorkType();
      getBaseUrl();
      fetchToken();
      _simulateLoading();
      getRequestingShift();
      _simulateLoading();
      createVisibility();
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

  Future<void> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    setState(() {
      baseUrl = typedServerUrl ?? '';
    });
  }

  Future<void> createVisibility() async {
    final prefs = await SharedPreferences.getInstance();
    var employeeId = prefs.getInt("employee_id");
    if (employeeId == int.parse(widget.selectedEmployerId)) {
      setState(() {
        isCreateButtonVisible = true;
      });
    }
    else {
      setState(() {
        isCreateButtonVisible = false;
      });
    }
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
  void approveRejectChecks() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var employeeId = prefs.getInt("employee_id");
    var uri =
    Uri.parse('$typedServerUrl/api/base/shift-request-approve-permission-check/$employeeId');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      approveRejectCheck = true;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset >=
        _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange) {
      currentPage++;
      getShiftRequest();
    }
  }

  /// widget list
  final List<Widget> bottomBarPages = [
    const Home(),
    const Overview(),
    const User(),
  ];

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


  Future<void> getEmployees() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var employeeId = prefs.getInt("employee_id");
    var uri = Uri.parse(
        '$typedServerUrl/api/employee/employee-selector?employee_id=$employeeId');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });

    if (response.statusCode == 200) {
      setState(() {
        // Clear previous data
        employeeItems.clear();
        employeeIdMap.clear();

        // Decode response
        var employees = jsonDecode(response.body)['results'];

        // Filter to display only the current logged-in user's details
        var currentUserDetails = employees.firstWhere(
              (employee) => employee['id'] == employeeId,
          orElse: () => null, // Handle case if no match is found
        );

        if (currentUserDetails != null) {
          final firstName = currentUserDetails['employee_first_name'] ?? '';
          final lastName = currentUserDetails['employee_last_name'] ?? '';
          final fullName = (firstName.isEmpty ? '' : firstName) +
              (lastName.isEmpty ? '' : ' $lastName');
          String employeeIdStr = "${currentUserDetails['id']}";

          // Add current user's details
          employeeItems.add(fullName);
          employeeIdMap[fullName] = employeeIdStr;

          // Set allEmployeeList with only the logged-in user details
          allEmployeeList = [currentUserDetails];
        }
      });
    }
  }


  Future<void> getEmployeeDetails() async {
    employeeId = widget.selectedEmployerId;
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/employee/employees/$employeeId');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      setState(() {
        employeeDetails = jsonDecode(response.body);
      });
    }
  }

  Future<void> getRequestingShift() async {
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
          String shiftId = "${rec['id']}";
          shiftDetails.add(rec['employee_shift']);
          shiftIdMap[shift] = shiftId;
        }
      });
    }
  }

  Future<void> rejectShiftRequest(Map<String, dynamic> updatedDetails) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    int requestId = updatedDetails['id'];
    var uri =
    Uri.parse('$typedServerUrl/api/base/shift-request-cancel/$requestId');
    var response = await http.post(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      setState(() {
        isSaveClick = false;
        getShiftRequest();
      });
    } else {
      isSaveClick = true;
    }
  }

  Future<void> approveShiftRequest(Map<String, dynamic> updatedDetails) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    int requestId = updatedDetails['id'];
    var uri =
    Uri.parse('$typedServerUrl/api/base/shift-request-approve/$requestId');
    var response = await http.put(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      setState(() {
        isSaveClick = false;
        getShiftRequest();
      });
    } else {
      isSaveClick = true;
    }
  }

  Future<void> getShiftRequest() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    employeeId = widget.selectedEmployerId;
    setState(() {
      hasNoRecords = false;
    });
    if (currentPage != 0) {
      var uri = Uri.parse(
          '$typedServerUrl/api/base/individual-shift-request?employee_id=$employeeId&page=$currentPage&search=$searchText');
      var response = await http.get(uri, headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });
      if (response.statusCode == 200) {
        setState(() {
          requests.addAll(
            List<Map<String, dynamic>>.from(
              jsonDecode(response.body)['results'],
            ),
          );
          requestsCount = jsonDecode(response.body)['count'];
          String serializeMap(Map<String, dynamic> map) {
            return jsonEncode(map);
          }

          Map<String, dynamic> deserializeMap(String jsonString) {
            return jsonDecode(jsonString);
          }

          List<String> mapStrings = requests.map(serializeMap).toList();
          Set<String> uniqueMapStrings = mapStrings.toSet();
          requests = uniqueMapStrings.map(deserializeMap).toList();

          filteredRecords = filterRecords(searchText);
          setState(() {
            isLoading = false;
          });
        });
      } else {
        setState(() {
          isLoading = false;
          hasNoRecords = true;
        });
      }
    } else {
      currentPage = 1;
      var uri = Uri.parse(
          '$typedServerUrl/api/base/shift-requests?employee_id=$employeeId&search=$searchText');
      var response = await http.get(uri, headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });
      if (response.statusCode == 200) {
        setState(() {
          requests.addAll(
            List<Map<String, dynamic>>.from(
              jsonDecode(response.body)['results'],
            ),
          );
          requestsCount = jsonDecode(response.body)['count'];
          String serializeMap(Map<String, dynamic> map) {
            return jsonEncode(map);
          }

          Map<String, dynamic> deserializeMap(String jsonString) {
            return jsonDecode(jsonString);
          }

          List<String> mapStrings = requests.map(serializeMap).toList();
          Set<String> uniqueMapStrings = mapStrings.toSet();
          requests = uniqueMapStrings.map(deserializeMap).toList();

          filteredRecords = filterRecords(searchText);
          setState(() {
            isLoading = false;
          });
        });
      } else {
        setState(() {
          isLoading = false;
          hasNoRecords = true;
        });
      }
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

  Future<void> getWorkType() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/base/worktypes');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      List<dynamic> workTypesData = jsonDecode(response.body);
      setState(() {
        for (var rec in workTypesData) {
          final workType = rec['work_type'] ?? '';
          String workTypeId = "${rec['id']}";
          workTypeItems.add(workType);
          workTypeIdMap[workType] = workTypeId;
        }
      });
    }
  }

  void showShiftApproveAnimation() {
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
                      "Shift Request Approved Successfully",
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

  void showRejectShiftAnimation() {
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
                      "Shift Request Rejected Successfully",
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

  Future<void> createShiftRequest(Map<String, dynamic> createdDetails) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/base/shift-requests/');
    var response = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "employee_id": createdDetails['employee_id'],
        "requested_date": createdDetails['requested_date'],
        "requested_till": createdDetails['requested_till'],
        "description": createdDetails['description'],
        "shift_id": createdDetails['shift_id'],
      }),
    );
    if (response.statusCode == 201) {
      isSaveClick = false;
      _errorMessage = null;
      getShiftRequest();
      setState(() {});
    } else {
      isSaveClick = true;
      var responseData = jsonDecode(response.body);
      if (responseData.containsKey('non_field_errors')) {
        _errorMessage = responseData['non_field_errors'].join('\n');
        setState(() {});
      }
      if (responseData.containsKey('requested_date')) {
        _errorMessage = responseData['requested_date'].join('\n');
        setState(() {});
      }
      if (responseData.containsKey('requested_till')) {
        _errorMessage = responseData['requested_till'].join('\n');
        setState(() {});
      }
      if (responseData.containsKey('description')) {
        _errorMessage = responseData['description'].join('\n');
        setState(() {});
      }
      if (responseData.containsKey('work_type_id')) {
        _errorMessage = responseData['work_type_id'].join('\n');
        setState(() {});
      }
      if (responseData.containsKey('employee_id')) {
        _errorMessage = responseData['employee_id'].join('\n');
        setState(() {});
      }
      setState(() {});
    }
  }

  void showCreateShiftAnimation() {
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
                      "Shift Created Successfully",
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

  void showDeleteShiftAnimation() {
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
                      "Shift Deleted Successfully",
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

  void showUpdateShiftAnimation() {
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
                      "Shift Updated Successfully",
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

  Future<void> deleteShiftRequest(int requestId) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/base/shift-requests/$requestId/');
    var response = await http.delete(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      setState(() {
        isSaveClick = false;
        getShiftRequest();
      });
    } else {
      isSaveClick = true;
    }
  }

  List<Map<String, dynamic>> filterRecords(String searchText) {
    if (searchText.isEmpty) {
      return requests;
    } else {
      return requests.where((record) {
        final firstName = record['employee_first_name'] ?? '';
        final lastName = record['employee_last_name'] ?? '';
        final fullName = (firstName + ' ' + lastName).toLowerCase();
        return fullName.contains(searchText.toLowerCase());
      }).toList();
    }
  }

  Future<void> updateShiftRequest(Map<String, dynamic> updatedDetails) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    String shiftRequestId = updatedDetails['id'].toString();
    var uri =
    Uri.parse('$typedServerUrl/api/base/shift-requests/$shiftRequestId/');
    var response = await http.put(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "employee_id": updatedDetails['employee_id'],
        "requested_date": updatedDetails['requested_date'],
        "requested_till": updatedDetails['requested_till'],
        "description": updatedDetails['description'],
        "shift_id": updatedDetails['shift_id'],
      }),
    );
    if (response.statusCode == 200) {
      isSaveClick = false;
      _errorMessage = null;
      getShiftRequest();
      setState(() {});
    } else {
      isSaveClick = true;
      var responseData = jsonDecode(response.body);
      if (responseData.containsKey('non_field_errors')) {
        _errorMessage = responseData['non_field_errors'].join('\n');
        setState(() {});
      }
      if (responseData.containsKey('requested_date')) {
        _errorMessage = responseData['requested_date'].join('\n');
        setState(() {});
      }
      if (responseData.containsKey('requested_till')) {
        _errorMessage = responseData['requested_till'].join('\n');
        setState(() {});
      }
      if (responseData.containsKey('description')) {
        _errorMessage = responseData['description'].join('\n');
        setState(() {});
      }
      if (responseData.containsKey('shift_id')) {
        _errorMessage = responseData['shift_id'].join('\n');
        setState(() {});
      }
      if (responseData.containsKey('employee_id')) {
        _errorMessage = responseData['employee_id'].join('\n');
        setState(() {});
      }
      setState(() {});
    }
  }

  void _showEditShiftRequest(
      BuildContext context, Map<String, dynamic> record) {
    TextEditingController editRequestedDateController =
    TextEditingController(text: record['requested_date'] ?? '');
    TextEditingController editRequestedTillController =
    TextEditingController(text: record['requested_till'] ?? 'None');
    TextEditingController descriptionSelect =
    TextEditingController(text: record['description'] ?? '');
    _typeAheadEditController.text = (record['employee_first_name'] ?? "") +
        " " +
        (record['employee_last_name'] ?? "");
    _typeAheadEditShiftController.text = record['shift_name'] ?? "";
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Stack(
              children: [
                AlertDialog(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Edit Shift Request",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontSize: 21),
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
                              controller: _typeAheadEditController,
                              decoration: InputDecoration(
                                labelText: 'Search Employee',
                                labelStyle: TextStyle(color: Colors.grey[350]),
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
                              });
                              _typeAheadEditController.text = suggestion;
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
                            'Requesting Shift',
                            style: TextStyle(color: Colors.black),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          TypeAheadField<String>(
                            textFieldConfiguration: TextFieldConfiguration(
                              controller: _typeAheadEditShiftController,
                              decoration: InputDecoration(
                                labelText: 'Search Requesting Shift',
                                labelStyle: TextStyle(color: Colors.grey[350]),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10.0),
                                border: const OutlineInputBorder(),
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
                                selectedEditShift = shiftIdMap[suggestion];
                                _validateShift = false;
                              });
                              _typeAheadEditShiftController.text = suggestion;
                            },
                            noItemsFoundBuilder: (context) => const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'No Requesting Shift Found',
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
                            "Requested Date",
                            style: TextStyle(color: Colors.black),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          TextField(
                            readOnly: true,
                            controller: editRequestedDateController,
                            onTap: () async {
                              final selectedDate = await showCustomDatePicker(
                                  context, DateTime.now());
                              if (selectedDate != null) {
                                DateTime parsedDate = DateFormat('yyyy-MM-dd')
                                    .parse(selectedDate);
                                setState(() {
                                  editRequestedDateController.text =
                                      DateFormat('yyyy-MM-dd')
                                          .format(parsedDate);
                                  _validateRequestedDate = false;
                                });
                              }
                            },
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: 'Select Requested Date',
                              labelStyle: TextStyle(color: Colors.grey[350]),
                              errorText: _validateRequestedDate
                                  ? 'Please select a Requested Date'
                                  : null,
                              contentPadding:
                              const EdgeInsets.symmetric(horizontal: 10.0),
                            ),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.03),
                          const Text(
                            "Requested Till",
                            style: TextStyle(color: Colors.black),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          TextField(
                            readOnly: true,
                            controller: editRequestedTillController,
                            onTap: () async {
                              final selectedDate = await showCustomDatePicker(
                                  context, DateTime.now());
                              if (selectedDate != null) {
                                DateTime parsedDate = DateFormat('yyyy-MM-dd')
                                    .parse(selectedDate);
                                setState(() {
                                  editRequestedTillController.text =
                                      DateFormat('yyyy-MM-dd')
                                          .format(parsedDate);
                                  _validateRequestedTill = false;
                                });
                              }
                            },
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: 'Select Requested Till',
                              labelStyle: TextStyle(color: Colors.grey[350]),
                              errorText: _validateRequestedTill
                                  ? 'Please select a Requested Till'
                                  : null,
                              contentPadding:
                              const EdgeInsets.symmetric(horizontal: 10.0),
                            ),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.03),
                          const Text(
                            'Description',
                            style: TextStyle(color: Colors.black),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          TextField(
                            controller: descriptionSelect,
                            decoration: InputDecoration(
                              labelText: "Description",
                              labelStyle: TextStyle(color: Colors.grey[350]),
                              border: const OutlineInputBorder(),
                              contentPadding:
                              const EdgeInsets.symmetric(horizontal: 10.0),
                              errorText: _validateDescription
                                  ? 'Description cannot be empty'
                                  : null,
                            ),
                            onChanged: (newValue) {
                              descriptionSelect.text = newValue;
                              _validateDescription = newValue.isEmpty;
                            },
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
                            if (descriptionSelect.text.isEmpty) {
                              setState(() {
                                isSaveClick = true;
                                _validateDescription = true;
                                Navigator.of(context).pop(true);
                                _showEditShiftRequest(context, record);
                              });
                            } else {
                              isAction = true;
                              Map<String, dynamic> updatedDetails = {
                                'id': record['id'],
                                "employee_id": selectedEditEmployeeId ??
                                    record['employee_id'].toString(),
                                "shift_id": selectedEditWorkType ??
                                    record['shift_id'].toString(),
                                "requested_date":
                                editRequestedDateController.text,
                                "requested_till":
                                editRequestedTillController.text,
                                "description": descriptionSelect.text,
                              };
                              await updateShiftRequest(updatedDetails);
                              setState(() {
                                isAction = false;
                              });
                              if (_errorMessage == null ||
                                  _errorMessage!.isEmpty) {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => ShiftRequestPage(
                                          selectedEmployerId:
                                          widget.selectedEmployerId,
                                          selectedEmployeeFullName:
                                          widget.selectedEmployeeFullName)),
                                );
                                showUpdateShiftAnimation();
                              } else {
                                Navigator.of(context).pop(true);
                                _showEditShiftRequest(context, record);
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

  void _showCreateShiftRequest(
      BuildContext context, selectedEmployeeFullName, selectedEmployerId) {
    _typeCreateAheadController.text = widget.selectedEmployeeFullName;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Stack(
              children: [
                AlertDialog(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Add Shift Request",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontSize: 21),
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
                              controller: _typeCreateAheadController,
                              decoration: InputDecoration(
                                labelText: 'Search Employee',
                                labelStyle: TextStyle(color: Colors.grey[350]),
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10.0),
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
                                _typeCreateAheadController.text = suggestion;
                                createEmployee = suggestion;
                                selectedCreateEmployeeId =
                                employeeIdMap[suggestion];
                              });
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
                            'Requesting Shift',
                            style: TextStyle(color: Colors.black),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          TypeAheadField<String>(
                            textFieldConfiguration: TextFieldConfiguration(
                              controller: _typeAheadCreateShiftController,
                              decoration: InputDecoration(
                                labelText: 'Search a Shift',
                                labelStyle: TextStyle(color: Colors.grey[350]),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10.0),
                                errorText: _validateShift
                                    ? 'Please Select a Shift'
                                    : null,
                                border: const OutlineInputBorder(),
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
                                selectedCreateShift = shiftIdMap[suggestion];
                                _validateShift = false;
                              });
                              _typeAheadCreateShiftController.text = suggestion;
                            },
                            noItemsFoundBuilder: (context) => const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'No Shifts Found',
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
                            "Requested Date",
                            style: TextStyle(color: Colors.black),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          TextField(
                            readOnly: true,
                            controller: createRequestedDateController,
                            onTap: () async {
                              final selectedDate = await showCustomDatePicker(
                                  context, DateTime.now());
                              if (selectedDate != null) {
                                DateTime parsedDate = DateFormat('yyyy-MM-dd')
                                    .parse(selectedDate);
                                setState(() {
                                  createRequestedDateController.text =
                                      DateFormat('yyyy-MM-dd')
                                          .format(parsedDate);
                                  _validateRequestedDate = false;
                                });
                              }
                            },
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: 'Requested Date',
                              labelStyle: TextStyle(color: Colors.grey[350]),
                              errorText: _validateRequestedDate
                                  ? 'Please select a Requested date'
                                  : null,
                              contentPadding:
                              const EdgeInsets.symmetric(horizontal: 10.0),
                              hintText: 'Select a Requested Date',
                            ),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.03),
                          const Text(
                            "Requested Till",
                            style: TextStyle(color: Colors.black),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          TextField(
                            readOnly: true,
                            controller: createRequestedTillController,
                            onTap: () async {
                              final selectedDate = await showCustomDatePicker(
                                  context, DateTime.now());
                              if (selectedDate != null) {
                                DateTime parsedDate = DateFormat('yyyy-MM-dd')
                                    .parse(selectedDate);
                                setState(() {
                                  createRequestedTillController.text =
                                      DateFormat('yyyy-MM-dd')
                                          .format(parsedDate);
                                  _validateRequestedTill = false;
                                });
                              }
                            },
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: 'Requested Till',
                              labelStyle: TextStyle(color: Colors.grey[350]),
                              errorText: _validateRequestedTill
                                  ? 'Please select a Requested Till'
                                  : null,
                              contentPadding:
                              const EdgeInsets.symmetric(horizontal: 10.0),
                              hintText: 'Select a Requested Till',
                            ),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.03),
                          const Text(
                            'Description',
                            style: TextStyle(color: Colors.black),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          TextField(
                            controller: descriptionSelect,
                            decoration: InputDecoration(
                              labelText: "Description",
                              labelStyle: TextStyle(color: Colors.grey[350]),
                              border: const OutlineInputBorder(),
                              contentPadding:
                              const EdgeInsets.symmetric(horizontal: 10.0),
                              errorText: _validateDescription
                                  ? 'Description cannot be empty'
                                  : null,
                            ),
                            onChanged: (newValue) {
                              descriptionSelect.text = newValue;
                              _validateDescription = newValue.isEmpty;
                            },
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
                            if (_typeAheadCreateShiftController.text.isEmpty) {
                              setState(() {
                                isSaveClick = true;
                                _validateShift = true;
                                _validateRequestedDate = false;
                                _validateRequestedTill = false;
                                _validateDescription = false;
                                Navigator.of(context).pop(true);
                                _showCreateShiftRequest(
                                    context,
                                    selectedEmployeeFullName,
                                    selectedEmployerId);
                              });
                            } else if (createRequestedDateController
                                .text.isEmpty) {
                              setState(() {
                                isSaveClick = true;
                                _validateShift = false;
                                _validateRequestedDate = true;
                                _validateRequestedTill = false;
                                _validateDescription = false;
                                Navigator.of(context).pop(true);
                                _showCreateShiftRequest(
                                    context,
                                    selectedEmployeeFullName,
                                    selectedEmployerId);
                              });
                            } else if (createRequestedTillController
                                .text.isEmpty) {
                              setState(() {
                                isSaveClick = true;
                                _validateShift = false;
                                _validateRequestedDate = false;
                                _validateRequestedTill = true;
                                _validateDescription = false;
                                Navigator.of(context).pop(true);
                                _showCreateShiftRequest(
                                    context,
                                    selectedEmployeeFullName,
                                    selectedEmployerId);
                              });
                            } else if (descriptionSelect.text.isEmpty) {
                              setState(() {
                                isSaveClick = true;
                                _validateShift = false;
                                _validateRequestedDate = false;
                                _validateRequestedTill = false;
                                _validateDescription = true;
                                Navigator.of(context).pop(true);
                                _showCreateShiftRequest(
                                    context,
                                    selectedEmployeeFullName,
                                    selectedEmployerId);
                              });
                            } else {
                              isAction = true;
                              Map<String, dynamic> createdDetails = {
                                "employee_id": selectedCreateEmployeeId ??
                                    widget.selectedEmployerId,
                                "shift_id": selectedCreateShift,
                                "requested_date":
                                createRequestedDateController.text,
                                "requested_till":
                                createRequestedTillController.text,
                                "description": descriptionSelect.text,
                              };
                              await createShiftRequest(createdDetails);
                              setState(() {
                                isAction = false;
                              });
                              if (_errorMessage == null ||
                                  _errorMessage!.isEmpty) {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => ShiftRequestPage(
                                          selectedEmployerId:
                                          widget.selectedEmployerId,
                                          selectedEmployeeFullName:
                                          widget.selectedEmployeeFullName)),
                                );
                                showCreateShiftAnimation();
                              } else {
                                Navigator.of(context).pop(true);
                                _showCreateShiftRequest(
                                    context,
                                    selectedEmployeeFullName,
                                    selectedEmployerId);
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

  Widget buildListItem(Map<String, dynamic> record, baseUrl, token) {
    final image = employeeDetails['employee_profile'] ?? '';
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return AlertDialog(
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
                                      if (employeeDetails['employee_profile'] !=
                                          null &&
                                          employeeDetails['employee_profile']
                                              .isNotEmpty)
                                        Positioned.fill(
                                          child: ClipOval(
                                            child: Image.network(
                                              baseUrl +
                                                  employeeDetails[
                                                  'employee_profile'],
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
                                      if (employeeDetails['employee_profile'] ==
                                          null ||
                                          employeeDetails['employee_profile']
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
                                    MediaQuery.of(context).size.width * 0.01),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.selectedEmployeeFullName,
                                        style: const TextStyle(
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.bold),
                                        maxLines: 2,
                                      ),
                                      Text(
                                        employeeDetails['badge_id'] != null
                                            ? '(${employeeDetails['badge_id']})'
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
                                height: MediaQuery.of(context).size.height * 0.02),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Requested shift',
                                  style: TextStyle(color: grey700),
                                ),
                                Text('${record['shift_name'] ?? 'None'}'),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Previous shift',
                                  style: TextStyle(color: grey700),
                                ),
                                Text('${record['previous_shift_name'] ?? 'None'}'),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Requested date',
                                  style: TextStyle(color: grey700),
                                ),
                                Text('${record['requested_date'] ?? 'None'}'),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Requested till',
                                  style: TextStyle(color: grey700),
                                ),
                                Text('${record['requested_till'] ?? 'None'}'),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Description',
                                  style: TextStyle(color: grey700),
                                ),
                                Flexible(
                                  child: Text(
                                    '${record['description'] ?? 'None'}',
                                    softWrap: true,
                                    textAlign: TextAlign.right,
                                  ),
                                )
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Is permanent shift',
                                  style: TextStyle(color: grey700),
                                ),
                                Text(record['is_permanent_shift'] ? 'Yes' : 'No'),
                              ],
                            ),
                            SizedBox(
                                height: MediaQuery.of(context).size.height * 0.01),
                          ],
                        ),
                      ),
                    ),
                    actions: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (!record['canceled'] && !record['approved'])
                            Row(
                              children: [
                                SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.3,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
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
                                              height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                                  0.1,
                                              child: const Center(
                                                child: Text(
                                                  "Are you sure you want to Reject this Shift Request?",
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
                                                      rejectShiftRequest(record);

                                                      Navigator.pop(context);
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) => ShiftRequestPage(
                                                                selectedEmployerId:
                                                                widget
                                                                    .selectedEmployerId,
                                                                selectedEmployeeFullName:
                                                                widget
                                                                    .selectedEmployeeFullName)),
                                                      );
                                                      showRejectShiftAnimation();
                                                    }
                                                  },
                                                  style: ButtonStyle(
                                                    backgroundColor:
                                                    MaterialStateProperty.all<
                                                        Color>(Colors.red),
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
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8.0),
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Reject',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: Colors.white, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.3,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      isSaveClick = true;
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
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
                                              height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                                  0.1,
                                              child: const Center(
                                                child: Text(
                                                  "Are you sure you want to Approve this Shift Request?",
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
                                                      await approveShiftRequest(
                                                          record);
                                                      Navigator.pop(context);
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) => ShiftRequestPage(
                                                                selectedEmployerId:
                                                                widget
                                                                    .selectedEmployerId,
                                                                selectedEmployeeFullName:
                                                                widget
                                                                    .selectedEmployeeFullName)),
                                                      );
                                                      showShiftApproveAnimation();
                                                    }
                                                  },
                                                  style: ButtonStyle(
                                                    backgroundColor:
                                                    MaterialStateProperty.all<
                                                        Color>(Colors.green),
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
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8.0),
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Approve',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: Colors.white, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          if (!record['canceled'] && record['approved'])
                            Row(
                              children: [
                                SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.3,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      isSaveClick = true;
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
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
                                              height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                                  0.1,
                                              child: const Center(
                                                child: Text(
                                                  "Are you sure you want to Reject this Shift Request?",
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
                                                      rejectShiftRequest(record);
                                                      Navigator.pop(context);
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) => ShiftRequestPage(
                                                                selectedEmployerId:
                                                                widget
                                                                    .selectedEmployerId,
                                                                selectedEmployeeFullName:
                                                                widget
                                                                    .selectedEmployeeFullName)),
                                                      );
                                                      showRejectShiftAnimation();
                                                    }
                                                  },
                                                  style: ButtonStyle(
                                                    backgroundColor:
                                                    MaterialStateProperty.all<
                                                        Color>(Colors.red),
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
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8.0),
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Reject',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: Colors.white, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.3,
                                  child: ElevatedButton(
                                    onPressed: null,
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8.0),
                                      ),
                                      backgroundColor:
                                      Colors.green.withOpacity(0.5),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Approve',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: Colors.white, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          if (record['canceled'] && !record['approved'])
                            Row(
                              children: [
                                SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.3,
                                  child: ElevatedButton(
                                    onPressed: null,
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8.0),
                                      ),
                                      backgroundColor: Colors.red.withOpacity(0.5),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Reject',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: Colors.white, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.3,
                                  child: ElevatedButton(
                                    onPressed: null,
                                    // Make the button inactive
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8.0),
                                      ),
                                      backgroundColor:
                                      Colors.green.withOpacity(0.5),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Approve',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: Colors.white, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  );
                });
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
              borderRadius: BorderRadius.circular(8.0),
            ),
            color: Colors.white,
            elevation: 0.0,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
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
                            if (employeeDetails['employee_profile'] != null &&
                                employeeDetails['employee_profile'].isNotEmpty)
                              Positioned.fill(
                                child: ClipOval(
                                  child: Image.network(
                                    baseUrl +
                                        employeeDetails['employee_profile'],
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
                            if (employeeDetails['employee_profile'] == null ||
                                employeeDetails['employee_profile'].isEmpty)
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
                              employeeDetails['employee_first_name'] +
                                  ' ' +
                                  (employeeDetails['employee_last_name'] ?? ''),
                              style: const TextStyle(
                                  fontSize: 16.0, fontWeight: FontWeight.bold),
                              maxLines: 2,
                            ),
                            Text(
                              employeeDetails['badge_id'] != null
                                  ? '(${employeeDetails['badge_id']})'
                                  : '',
                              style: const TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.normal),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.005),
                      if (!record['canceled'] && !record['approved'])
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(15.0),
                              bottomLeft: Radius.circular(15.0),
                            ),
                            color: Colors.blue[100],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 0.0),
                            child: IconButton(
                              icon: const Icon(
                                Icons.edit,
                                size: 18.0,
                                color: Colors.blue,
                              ),
                              onPressed: () async {
                                _errorMessage = null;
                                isAction = false;
                                _showEditShiftRequest(context, record);
                              },
                            ),
                          ),
                        ),
                      if (!record['canceled'] && !record['approved'])
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(15.0),
                              bottomRight: Radius.circular(15.0),
                            ),
                            color: Colors.red[100],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 0.0),
                            child: IconButton(
                              icon: const Icon(
                                Icons.delete,
                                size: 18.0,
                                color: Colors.red,
                              ),
                              onPressed: () async {
                                isSaveClick = true;
                                await showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            "Confirmation",
                                            style: TextStyle(
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
                                      content: SizedBox(
                                        height:
                                        MediaQuery.of(context).size.height *
                                            0.1,
                                        child: const Center(
                                          child: Text(
                                            "Are you sure you want to delete this Shift Request?",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
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
                                                var requestId = record['id'];
                                                await deleteShiftRequest(
                                                    requestId);
                                                Navigator.pop(context);
                                                setState(() {
                                                  requests.removeWhere(
                                                          (record) =>
                                                      record['id'] ==
                                                          requestId);
                                                });
                                                showDeleteShiftAnimation();
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
                                            child: const Text(
                                              "Continue",
                                              style: TextStyle(
                                                  color: Colors.white),
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
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.02,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Requested Shift',
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold)),
                          Text(
                            record['shift_name'] != null
                                ? record['shift_name'].toString()
                                : "None",
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Current Shift',
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold)),
                          Text(
                            record['previous_shift_name'] != null
                                ? record['previous_shift_name'].toString()
                                : "None",
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Requested Date',
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold)),
                          Text(
                            record['requested_date'] != null
                                ? record['requested_date'].toString()
                                : "None",
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Requested Till Date',
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold)),
                          Text(
                            record['requested_till'] != null
                                ? record['requested_till'].toString()
                                : "None",
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.01),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (!record['canceled'] && !record['approved'])
                            Row(
                              children: [
                                SizedBox(
                                  width:
                                  MediaQuery.of(context).size.width * 0.3,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      isSaveClick = true;
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: Row(
                                              mainAxisAlignment:
                                              MainAxisAlignment
                                                  .spaceBetween,
                                              children: [
                                                const Text(
                                                  "Confirmation",
                                                  style: TextStyle(
                                                      fontWeight:
                                                      FontWeight.bold,
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
                                              height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                                  0.1,
                                              child: const Center(
                                                child: Text(
                                                  "Are you sure you want to Reject this Shift Request?",
                                                  style: TextStyle(
                                                      fontWeight:
                                                      FontWeight.bold,
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
                                                      rejectShiftRequest(
                                                          record);
                                                      Navigator.pop(context);
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) =>
                                                                ShiftRequestPage(
                                                                    selectedEmployerId:
                                                                    widget
                                                                        .selectedEmployerId,
                                                                    selectedEmployeeFullName:
                                                                    widget
                                                                        .selectedEmployeeFullName)),
                                                      );
                                                      showRejectShiftAnimation();
                                                    }
                                                  },
                                                  style: ButtonStyle(
                                                    backgroundColor:
                                                    MaterialStateProperty
                                                        .all<Color>(
                                                        Colors.red),
                                                    shape: MaterialStateProperty
                                                        .all<
                                                        RoundedRectangleBorder>(
                                                      RoundedRectangleBorder(
                                                        borderRadius:
                                                        BorderRadius
                                                            .circular(8.0),
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
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(8.0),
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Reject',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width:
                                  MediaQuery.of(context).size.width * 0.3,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      isSaveClick = true;
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: Row(
                                              mainAxisAlignment:
                                              MainAxisAlignment
                                                  .spaceBetween,
                                              children: [
                                                const Text(
                                                  "Confirmation",
                                                  style: TextStyle(
                                                      fontWeight:
                                                      FontWeight.bold,
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
                                              height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                                  0.1,
                                              child: const Center(
                                                child: Text(
                                                  "Are you sure you want to Approve this Shift Request?",
                                                  style: TextStyle(
                                                      fontWeight:
                                                      FontWeight.bold,
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
                                                      await approveShiftRequest(
                                                          record);
                                                      Navigator.pop(context);
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) =>
                                                                ShiftRequestPage(
                                                                    selectedEmployerId:
                                                                    widget
                                                                        .selectedEmployerId,
                                                                    selectedEmployeeFullName:
                                                                    widget
                                                                        .selectedEmployeeFullName)),
                                                      );
                                                      showShiftApproveAnimation();
                                                    }
                                                  },
                                                  style: ButtonStyle(
                                                    backgroundColor:
                                                    MaterialStateProperty
                                                        .all<Color>(
                                                        Colors.green),
                                                    shape: MaterialStateProperty
                                                        .all<
                                                        RoundedRectangleBorder>(
                                                      RoundedRectangleBorder(
                                                        borderRadius:
                                                        BorderRadius
                                                            .circular(8.0),
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
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(8.0),
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Approve',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          if (!record['canceled'] && record['approved'])
                            Row(
                              children: [
                                SizedBox(
                                  width:
                                  MediaQuery.of(context).size.width * 0.3,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      isSaveClick = true;
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: Row(
                                              mainAxisAlignment:
                                              MainAxisAlignment
                                                  .spaceBetween,
                                              children: [
                                                const Text(
                                                  "Confirmation",
                                                  style: TextStyle(
                                                      fontWeight:
                                                      FontWeight.bold,
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
                                              height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                                  0.1,
                                              child: const Center(
                                                child: Text(
                                                  "Are you sure you want to Reject this Shift Request?",
                                                  style: TextStyle(
                                                      fontWeight:
                                                      FontWeight.bold,
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
                                                      rejectShiftRequest(
                                                          record);
                                                      Navigator.pop(context);
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) =>
                                                                ShiftRequestPage(
                                                                    selectedEmployerId:
                                                                    widget
                                                                        .selectedEmployerId,
                                                                    selectedEmployeeFullName:
                                                                    widget
                                                                        .selectedEmployeeFullName)),
                                                      );
                                                      showRejectShiftAnimation();
                                                    }
                                                  },
                                                  style: ButtonStyle(
                                                    backgroundColor:
                                                    MaterialStateProperty
                                                        .all<Color>(
                                                        Colors.red),
                                                    shape: MaterialStateProperty
                                                        .all<
                                                        RoundedRectangleBorder>(
                                                      RoundedRectangleBorder(
                                                        borderRadius:
                                                        BorderRadius
                                                            .circular(8.0),
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
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(8.0),
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Reject',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width:
                                  MediaQuery.of(context).size.width * 0.3,
                                  child: ElevatedButton(
                                    onPressed: null,
                                    // Make the button inactive
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(8.0),
                                      ),
                                      backgroundColor:
                                      Colors.green.withOpacity(0.5),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Approve',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          if (record['canceled'] && !record['approved'])
                            Row(
                              children: [
                                SizedBox(
                                  width:
                                  MediaQuery.of(context).size.width * 0.3,
                                  child: ElevatedButton(
                                    onPressed: null,
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(8.0),
                                      ),
                                      backgroundColor:
                                      Colors.red.withOpacity(0.5),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Reject',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width:
                                  MediaQuery.of(context).size.width * 0.3,
                                  child: ElevatedButton(
                                    onPressed: null,
                                    // Make the button inactive
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(8.0),
                                      ),
                                      backgroundColor:
                                      Colors.green.withOpacity(0.5),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Approve',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
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

  @override
  Widget build(BuildContext context) {
    final bool permissionCheck =
    ModalRoute.of(context)?.settings.arguments != null
        ? ModalRoute.of(context)!.settings.arguments as bool
        : false;
    return Scaffold(
      backgroundColor: Colors.white,
      key: _scaffoldKey,
      appBar: AppBar(
        forceMaterialTransparency: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        title: const Text('Shift Request',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // if (permissionCheck)
                Container(
                  alignment: Alignment.centerRight,
                  child: Visibility(
                    visible: isCreateButtonVisible, // Set visibility based on your bool value
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                          _typeAheadCreateShiftController.clear();
                          createRequestedDateController.clear();
                          createRequestedTillController.clear();
                          descriptionSelect.clear();
                          _validateShift = false;
                          _validateRequestedDate = false;
                          _validateRequestedTill = false;
                          _validateDescription = false;
                          isAction = false;
                        });
                        _showCreateShiftRequest(context, selectedEmployeeFullName, selectedEmployerId);
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(75, 50),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0),
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                      child: const Text(
                        'CREATE',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  )                ),
                // ),
              ],
            ),
          ),
        ],
      ),
      body: isLoading ? _buildLoadingWidget() : _buildEmployeeDetailsWidget(),
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

  Widget _buildLoadingWidget() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300] ?? Colors.grey,
        highlightColor: Colors.grey[100] ?? Colors.white,
        child: ListView.builder(
          itemCount: 10, // Number of placeholder items
          itemBuilder: (context, index) {
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
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  color: Colors.white,
                  elevation: 0.0,
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
                              height: 40.0,
                              width: 40.0,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border:
                                Border.all(color: Colors.grey, width: 1.0),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 100.0),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmployeeDetailsWidget() {
    return Column(
      children: [
        if (requestsCount == 0)
          const Expanded(
            child: Center(
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
                    "There are no records to display",
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView.builder(
                controller: _scrollController,
                itemCount: searchText.isEmpty
                    ? requests.length
                    : filteredRecords.length,
                itemBuilder: (context, index) {
                  final record = searchText.isEmpty
                      ? requests[index]
                      : filteredRecords[index];
                  return buildListItem(record, baseUrl,getToken);
                },
              ),
            ),
          ),
      ],
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
