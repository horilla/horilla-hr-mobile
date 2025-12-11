import 'dart:async';
import 'dart:convert';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:io';
import '../../res/consts/app_colors.dart';

class LeaveRequest extends StatefulWidget {
  const LeaveRequest({super.key});

  @override
  _LeaveRequest createState() => _LeaveRequest();
}

class _LeaveRequest extends State<LeaveRequest>
    with SingleTickerProviderStateMixin {
  String _getBreakdown(String breakdownValue) {
    final breakdownMap = {
      'full_day': 'Full Day',
      'second_half': 'Second Half',
      'first_half': 'First Half',
    };

    return breakdownMap[breakdownValue] ?? 'Unknown';
  }

  String? _errorMessage;
  String? selectedLeaveType;
  String? editStartDateBreakdown;
  String selectedStartDateValue = '';
  String? editEndDateBreakdown;
  String selectedEndDateValue = '';
  String? selectedEmployee;
  String? selectedEmployeeId;
  String searchText = '';
  String? selectedLeaveId;
  String? editLeaveType;
  String? editEmployeeType;
  String fileName = '';
  String filePath = '';
  Map<String, String> employeeIdMap = {};

  Map<String, dynamic> breakdownMaps = {
    'full_day': 'Full Day',
    'second_half': 'Second Half',
    'first_half': 'First Half',
  };
  Map<String, String> leaveItemsIdMap = {};
  Map<String, String> employeeItemsIdMap = {};
  final TextEditingController _typeAheadEditController =
  TextEditingController();
  final TextEditingController _typeAheadCreateController =
  TextEditingController();
  final TextEditingController _typeAheadEmployeeCreateController =
  TextEditingController();
  final TextEditingController _typeAheadEmployeeEditController =
  TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late Map<String, dynamic> arguments;
  bool isAction = true;
  bool permissionLeaveTypeCheck = false;
  bool permissionLeaveAssignCheck = false;
  bool permissionLeaveRequestCheck = false;
  bool permissionLeaveOverviewCheck = false;
  bool permissionMyLeaveRequestCheck = false;
  bool permissionLeaveAllocationCheck = false;
  bool isSaveClick = true;
  bool isLoading = true;
  bool _isShimmerVisible = true;
  bool _isShimmer = true;
  bool checkFile = false;
  bool dateCheckError = false;
  bool dateBreakDownError = false;
  bool insufficientDaysError = false;
  bool _validateLeaveType = false;
  bool _validateDate = false;
  bool _validateStartDateBreakdown = false;
  bool _validateEndDateBreakdown = false;
  bool _validateEndDate = false;
  bool _validateDescription = false;
  bool _validateEmployee = false;
  bool _validateAttachment = false;
  int maxCount = 5;
  int allRequestsLength = 0;
  int requestedLength = 0;
  int approvedLength = 0;
  int cancelledLength = 0;
  int rejectedLength = 0;
  int currentPage = 1;
  var employeeItems = [''];
  var startBreakdown = [''];
  var leaveItems = [''];
  late String baseUrl = '';
  late TabController _tabController;
  final _controller = NotchBottomBarController(index: -1);
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  XFile? pickedFile;
  DateTime? startDate;
  DateTime? endDate;
  List<dynamic> leaveTypes = [];
  List<String> leaveItem = [];
  List<String> employeeItem = [];
  List<Map<String, dynamic>> filteredRecords = [];
  List<Map<String, dynamic>> filteredRecordsRequested = [];
  List<Map<String, dynamic>> filteredRecordsApproved = [];
  List<Map<String, dynamic>> filteredRecordsCancelled = [];
  List<Map<String, dynamic>> filteredRecordsRejected = [];
  List<Map<String, dynamic>> requestsEmployeesName = [];
  List<Map<String, dynamic>> leaveType = [];
  List<Map<String, dynamic>> myAllRequests = [];
  List<Map<String, dynamic>> requestedRecords = [];
  List<Map<String, dynamic>> approvedRecords = [];
  List<Map<String, dynamic>> cancelledRecords = [];
  List<Map<String, dynamic>> rejectedRecords = [];
  List<Map<String, dynamic>> myAllPagesRequests = [];
  List<Map<String, dynamic>> myApprovedRequests = [];
  List<Map<String, dynamic>> currentLeaveRequests = [];
  List<Map<String, dynamic>> currentRequests = [];
  TextEditingController leaveDescription = TextEditingController();
  TextEditingController startDateInput = TextEditingController();
  TextEditingController endDateInput = TextEditingController();
  TextEditingController description = TextEditingController();
  TextEditingController descriptionLeaveRequest = TextEditingController();
  TextEditingController rejectDescription = TextEditingController();
  TextEditingController startDateSelect = TextEditingController();
  TextEditingController endDateSelect = TextEditingController();
  TextEditingController descriptionSelect = TextEditingController();
  final TextEditingController _fileNameController = TextEditingController();
  Timer? _debounce;

  bool isFetchingMore = false;
  bool hasMoreAll = true;
  bool hasMoreRequested = true;
  bool hasMoreApproved = true;
  bool hasMoreCancelled = true;
  bool hasMoreRejected = true;
  late String getToken = '';



  @override
  void initState() {
    super.initState();
    currentPage = 1;
    _scrollController.addListener(_scrollListener);
    _tabController = TabController(length: 5, vsync: this);

    _isShimmerVisible = true;
    isLoading = true;
    _isShimmer = true;

    startBreakdown.clear();
    startDateSelect.text = "Select Start Date";
    endDateSelect.text = "Select End Date";
    startDateInput.text = "";
    endDateInput.text = "";
    fetchToken();


    _loadInitialData();
  }

  Future<void> fetchToken() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    setState(() {
      getToken = token ?? '';
    });
  }


  Future<void> _loadInitialData() async {
    try {
      await prefetchData();
      await getBaseUrl();
      await getEmployees();
      await getListEmployees();
      await getAllEmployeesName();
      await checkPermissions();

      await Future.wait([
        getAllLeaveRequest(reset: true),
        getRequestedCount(reset: true),
        getApprovedCount(reset: true),
        getCancelledCount(reset: true),
        getRejectedCount(reset: true),
      ]);

      setState(() {
        _isShimmerVisible = false;
        isLoading = false;
        _isShimmer = false;
      });
    } catch (e) {
      setState(() {
        _isShimmerVisible = false;
        isLoading = false;
        _isShimmer = false;
      });
    }
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


  Future<void> prefetchData() async {
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

  @override
  void dispose() {
    _fileNameController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
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
                    const Text(
                      "Leave Deleted Successfully",
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
                      "Leave Rejected Successfully",
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

  void showApproveAnimation() {
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
                      "Leave Approved Successfully",
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
                      "Leave Created Successfully",
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
                    const Text(
                      "Leave Updated Successfully",
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

  Future<void> getCurrentLeaveRequest(String recordId) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/leave/request/$recordId');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      setState(() {
        currentLeaveRequests.clear();
        currentLeaveRequests.add(jsonDecode(response.body));
      });
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100 &&
        !isFetchingMore) {
      setState(() => isFetchingMore = true);
      currentPage++;
      // Load the next page based on selected tab
      switch (_tabController.index) {
        case 0:
          if (hasMoreAll) getAllLeaveRequest();
          break;
        case 1:
          if (hasMoreRequested) getRequestedCount();
          break;
        case 2:
          if (hasMoreApproved) getApprovedCount();
          break;
        case 3:
          if (hasMoreCancelled) getCancelledCount();
          break;
        case 4:
          if (hasMoreRejected) getRejectedCount();
          break;
      }
      setState(() => isFetchingMore = false);
    }
  }


  void setFileName() {
    setState(() {
      _fileNameController.text = fileName;
    });
  }

  Future<void> getEmployees() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/employee/employee-selector');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });

    if (response.statusCode == 200) {
      setState(() {
        employeeItem.clear();
        for (var employee in jsonDecode(response.body)['results']) {
          String fullName =
              "${employee['employee_first_name']} ${employee['employee_last_name']}";
          String employeeId = "${employee['id']}";
          employeeItem.add(fullName);
          employeeIdMap[fullName] = employeeId;
        }
      });
    } else {}
  }

  final List<Widget> bottomBarPages = [];

  Future<void> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    var typedServerUrl = prefs.getString("typed_url");
    setState(() {
      baseUrl = typedServerUrl ?? '';
    });
  }

  Future<XFile?> uploadFile(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? pickedFile =
    await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      return pickedFile;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No image selected'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
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

  void showCreateLeaveDialog(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    var employeeID = prefs.getInt("employee_id");

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
                          "Add Leave",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            Navigator.of(context).pop();
                            selectedEmployeeId = null;
                          },
                        ),
                      ],
                    ),
                    content: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.95,
                      height: MediaQuery.of(context).size.height * 0.5,
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
                                height: MediaQuery.of(context).size.height * 0.03),
                            const Text("Employee",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black)),
                            SizedBox(
                                height: MediaQuery.of(context).size.height * 0.01),
                            TypeAheadField<String>(
                              textFieldConfiguration: TextFieldConfiguration(
                                controller: _typeAheadEmployeeCreateController,
                                decoration: InputDecoration(
                                  labelText: 'Choose an employee',
                                  labelStyle: TextStyle(color: Colors.grey[350]),
                                  border: const OutlineInputBorder(),
                                  contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 10.0),
                                  errorText: _validateEmployee
                                      ? 'Please select a leave type'
                                      : null,
                                ),
                              ),
                              suggestionsCallback: (pattern) {
                                return employeeItem
                                    .where((leaveType) => leaveType
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
                                  _typeAheadEmployeeCreateController.text =
                                      suggestion;
                                  editEmployeeType = suggestion;
                                  selectedEmployeeId = employeeIdMap[suggestion];
                                  getLeaveTypes(selectedEmployeeId);
                                  _validateEmployee = false;
                                });
                              },
                              noItemsFoundBuilder: (context) => const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'No Leave Types Found',
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
                                    maxHeight: MediaQuery.of(context).size.height *
                                        0.23), // Limit height
                              ),
                              // Set initial value
                            ),
                            SizedBox(
                                height: MediaQuery.of(context).size.height * 0.03),
                            const Text(
                              "Leave Type",
                              style: TextStyle(color: Colors.black),
                            ),
                            SizedBox(
                                height: MediaQuery.of(context).size.height * 0.01),
                            TypeAheadField<String>(
                              textFieldConfiguration: TextFieldConfiguration(
                                controller: _typeAheadCreateController,
                                decoration: InputDecoration(
                                  labelText: 'Choose a Leave Type',
                                  labelStyle: TextStyle(color: Colors.grey[350]),
                                  border: const OutlineInputBorder(),
                                  contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 10.0),
                                  errorText: _validateLeaveType
                                      ? 'Please select a leave type'
                                      : null,
                                ),
                              ),
                              suggestionsCallback: (pattern) {
                                return leaveItem
                                    .where((leaveType) => leaveType
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
                                  startDate = null;
                                  endDate = null;
                                  _typeAheadCreateController.text = suggestion;
                                  editLeaveType = suggestion;
                                  selectedLeaveId = leaveItemsIdMap[suggestion];
                                  _validateLeaveType = false;
                                });
                              },
                              noItemsFoundBuilder: (context) => const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'No Leave Types Found',
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
                                    maxHeight: MediaQuery.of(context).size.height *
                                        0.23), // Limit height
                              ),
                            ),
                            SizedBox(
                                height: MediaQuery.of(context).size.height * 0.03),
                            const Text("Start Date"),
                            SizedBox(
                                height: MediaQuery.of(context).size.height * 0.01),
                            TextField(
                              readOnly: true,
                              controller: startDateSelect,
                              onTap: () async {
                                final selectedDate = await showCustomDatePicker(
                                    context, DateTime.now());
                                if (selectedDate != null) {
                                  DateTime parsedDate =
                                  DateFormat('yyyy-MM-dd').parse(selectedDate);
                                  setState(() {
                                    startDate = parsedDate;
                                    startDateSelect.text =
                                        DateFormat('yyyy-MM-dd').format(startDate!);
                                    _validateDate = false;
                                  });
                                }
                              },
                              decoration: InputDecoration(
                                labelText: "Start Date",
                                labelStyle: TextStyle(color: Colors.grey[350]),
                                border: const OutlineInputBorder(),
                                contentPadding:
                                const EdgeInsets.symmetric(horizontal: 10.0),
                                errorText: _validateDate
                                    ? 'Please select a start date'
                                    : null,
                              ),
                            ),
                            SizedBox(
                                height: MediaQuery.of(context).size.height * 0.03),
                            const Text("Start Date Breakdown"),
                            SizedBox(
                                height: MediaQuery.of(context).size.height * 0.01),
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: DropdownSearch<String>(
                                items: breakdownMaps.values.toList().cast<String>(),
                                selectedItem: editStartDateBreakdown,
                                onChanged: (newValue) {
                                  if (newValue != null) {
                                    editStartDateBreakdown = newValue;
                                    selectedStartDateValue = breakdownMaps.entries
                                        .firstWhere(
                                            (entry) => entry.value == newValue)
                                        .key;
                                    _validateStartDateBreakdown = false;
                                  }
                                },
                                dropdownDecoratorProps: DropDownDecoratorProps(
                                  dropdownSearchDecoration: InputDecoration(
                                    errorText: _validateStartDateBreakdown
                                        ? 'Please select a Start Date Breakdown'
                                        : null,
                                    border: const OutlineInputBorder(),
                                    labelText: "Start Date Breakdown",
                                    labelStyle: TextStyle(color: Colors.grey[350]),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 10.0),
                                  ),
                                ),
                                popupProps: PopupProps.menu(
                                  constraints: BoxConstraints(
                                      maxHeight:
                                      MediaQuery.of(context).size.height *
                                          0.23),
                                  // Set your desired height
                                  showSearchBox: false,
                                ),
                              ),
                            ),
                            SizedBox(
                                height: MediaQuery.of(context).size.height * 0.03),
                            const Text("End Date"),
                            SizedBox(
                                height: MediaQuery.of(context).size.height * 0.01),
                            TextField(
                              readOnly: true,
                              controller: endDateSelect,
                              onTap: () async {
                                final selectedDate = await showCustomDatePicker(
                                    context, DateTime.now());
                                if (selectedDate != null) {
                                  DateTime parsedDate =
                                  DateFormat('yyyy-MM-dd').parse(selectedDate);
                                  setState(() {
                                    endDate = parsedDate;
                                    endDateSelect.text =
                                        DateFormat('yyyy-MM-dd').format(endDate!);
                                    _validateEndDate = false;
                                  });
                                }
                              },
                              decoration: InputDecoration(
                                labelText: "End Date",
                                labelStyle: TextStyle(color: Colors.grey[350]),
                                border: const OutlineInputBorder(),
                                contentPadding:
                                const EdgeInsets.symmetric(horizontal: 10.0),
                                errorText: _validateEndDate
                                    ? 'Please select an end date'
                                    : null,
                              ),
                            ),
                            SizedBox(
                                height: MediaQuery.of(context).size.height * 0.03),
                            const Text("End Date Breakdown"),
                            SizedBox(
                                height: MediaQuery.of(context).size.height * 0.01),
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: DropdownSearch<String>(
                                items: breakdownMaps.values.toList().cast<String>(),
                                selectedItem: editEndDateBreakdown,
                                onChanged: (newValue) {
                                  setState(() {
                                    if (newValue != null) {
                                      editEndDateBreakdown = newValue;
                                      selectedEndDateValue = breakdownMaps.entries
                                          .firstWhere(
                                              (entry) => entry.value == newValue)
                                          .key;
                                      _validateEndDateBreakdown = false;
                                    }
                                  });
                                },
                                dropdownDecoratorProps: DropDownDecoratorProps(
                                  dropdownSearchDecoration: InputDecoration(
                                    errorText: _validateEndDateBreakdown
                                        ? 'Please select an End Date Breakdown'
                                        : null,
                                    border: const OutlineInputBorder(),
                                    labelText: "End Date Breakdown",
                                    labelStyle: TextStyle(color: Colors.grey[350]),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 10.0),
                                  ),
                                ),
                                popupProps: PopupProps.menu(
                                  constraints: BoxConstraints(
                                      maxHeight:
                                      MediaQuery.of(context).size.height *
                                          0.23),
                                  // Set your desired height
                                  showSearchBox: false,
                                ),
                              ),
                            ),
                            SizedBox(
                                height: MediaQuery.of(context).size.height * 0.03),
                            const Text("Description"),
                            SizedBox(
                                height: MediaQuery.of(context).size.height * 0.01),
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
                            SizedBox(
                                height: MediaQuery.of(context).size.height * 0.02),
                            IconButton(
                              icon: const Icon(Icons.attach_file),
                              onPressed: () async {
                                XFile? file = await uploadFile(context);
                                if (file != null) {
                                  setState(() {
                                    pickedFile = file;
                                    fileName = file.name;
                                    filePath = file.path;
                                    checkFile = true;
                                    setFileName();
                                  });
                                }
                              },
                            ),
                            TextField(
                              controller: _fileNameController,
                              readOnly: true,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                labelStyle: TextStyle(color: Colors.grey[350]),
                                contentPadding:
                                const EdgeInsets.symmetric(horizontal: 5.0),
                                suffixIcon: _fileNameController.text.isNotEmpty
                                    ? IconButton(
                                  padding: EdgeInsets.only(
                                      bottom:
                                      MediaQuery.of(context).size.height *
                                          0.0168),
                                  icon: const Icon(Icons.close,
                                      color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      _fileNameController.clear();
                                    });
                                  },
                                )
                                    : null,
                              ),
                            ),
                          ],
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
                              if (_typeAheadEmployeeCreateController.text.isEmpty) {
                                setState(() {
                                  isSaveClick = true;
                                  _validateEmployee = true;
                                  _validateLeaveType = false;
                                  _validateStartDateBreakdown = false;
                                  _validateEndDateBreakdown = false;
                                  _validateDate = false;
                                  _validateEndDate = false;
                                  _validateDescription = false;
                                  Navigator.of(context).pop();
                                  showCreateLeaveDialog(context);
                                });
                              } else if (selectedLeaveId == null) {
                                setState(() {
                                  isSaveClick = true;
                                  _validateLeaveType = true;
                                  _validateEmployee = false;
                                  _validateStartDateBreakdown = false;
                                  _validateEndDateBreakdown = false;
                                  _validateDate = false;
                                  _validateEndDate = false;
                                  _validateDescription = false;
                                  Navigator.of(context).pop();
                                  showCreateLeaveDialog(context);
                                });
                              } else if (startDate == null) {
                                setState(() {
                                  isSaveClick = true;
                                  _validateDate = true;
                                  _validateEmployee = false;
                                  _validateLeaveType = false;
                                  _validateStartDateBreakdown = false;
                                  _validateEndDateBreakdown = false;
                                  _validateEndDate = false;
                                  _validateDescription = false;
                                  Navigator.of(context).pop();
                                  showCreateLeaveDialog(context);
                                });
                              } else if (editStartDateBreakdown == null) {
                                setState(() {
                                  isSaveClick = true;
                                  _validateStartDateBreakdown = true;
                                  _validateEndDateBreakdown = false;
                                  _validateEmployee = false;
                                  _validateLeaveType = false;

                                  _validateDate = false;
                                  _validateEndDate = false;
                                  _validateDescription = false;
                                  Navigator.of(context).pop();
                                  showCreateLeaveDialog(context);
                                });
                              } else if (endDate == null) {
                                setState(() {
                                  isSaveClick = true;
                                  _validateEndDate = true;
                                  _validateEmployee = false;
                                  _validateLeaveType = false;
                                  _validateStartDateBreakdown = false;
                                  _validateEndDateBreakdown = false;
                                  _validateDate = false;
                                  _validateDescription = false;
                                  Navigator.of(context).pop();
                                  showCreateLeaveDialog(context);
                                });
                              } else if (editEndDateBreakdown == null) {
                                setState(() {
                                  isSaveClick = true;
                                  _validateEndDateBreakdown = true;
                                  _validateStartDateBreakdown = false;
                                  _validateEmployee = false;
                                  _validateLeaveType = false;
                                  _validateDate = false;
                                  _validateEndDate = false;
                                  _validateDescription = false;
                                  Navigator.of(context).pop();
                                  showCreateLeaveDialog(context);
                                });
                              } else if (descriptionSelect.text.isEmpty) {
                                setState(() {
                                  isSaveClick = true;
                                  _validateDescription = true;
                                  _validateEmployee = false;
                                  _validateLeaveType = false;
                                  _validateStartDateBreakdown = false;
                                  _validateEndDateBreakdown = false;
                                  _validateDate = false;
                                  _validateEndDate = false;
                                  Navigator.of(context).pop();
                                  showCreateLeaveDialog(context);
                                });
                              } else {
                                setState(() {
                                  _validateEmployee = false;
                                  _validateLeaveType = false;
                                  _validateStartDateBreakdown = false;
                                  _validateEndDateBreakdown = false;
                                  _validateDescription = false;
                                  _validateAttachment = false;
                                  _validateDate = false;
                                  _validateEndDate = false;
                                  isAction = true;
                                });
                                Map<String, dynamic> createdDetails = {
                                  "employee_id": selectedEmployeeId,
                                  "leave_type_id": selectedLeaveId,
                                  'leave_type': selectedLeaveType,
                                  'start_date': startDateSelect.text,
                                  'start_date_breakdown': selectedStartDateValue,
                                  'end_date': endDateSelect.text,
                                  'end_date_breakdown': selectedEndDateValue,
                                  'description': descriptionSelect.text,
                                };
                                await createNewLeaveType(
                                    createdDetails, checkFile, fileName, filePath);
                                setState(() {
                                  isAction = false;
                                });
                                if (_errorMessage == null ||
                                    _errorMessage!.isEmpty) {
                                  Navigator.of(context).pop(true);
                                  showCreateAnimation();
                                } else {
                                  Navigator.of(context).pop(true);
                                  showCreateLeaveDialog(context);
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
            });
      },
    );
    if (employeeID != null) {
      await getEmployees();
      await getLeaveTypes(employeeID);
    }
  }

  List<String> allEmployeeNames = [];

  Future<void> getAllEmployeesName() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");

    allEmployeeNames.clear();
    int page = 1;
    bool hasMore = true;

    while (hasMore) {
      var uri = Uri.parse('$typedServerUrl/api/employee/employee-selector?page=$page');
      var response = await http.get(uri, headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        var results = data['results'];

        if (results.isEmpty) {
          hasMore = false;
          break;
        }

        setState(() {
          for (var employee in results) {
            var employeeName = "${employee['employee_first_name'] ?? ''} ${employee['employee_last_name'] ?? ''}".trim();
            allEmployeeNames.add(employeeName);
          }
        });

        page++;
      } else {
        print('Failed to fetch employee names: ${response.statusCode}');
        hasMore = false;
      }
    }
  }

  Future<void> createNewLeaveType(Map<String, dynamic> createdDetails,
      checkfile, String fileName, String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    for (var leaveType in leaveTypes) {
      if (leaveType['name'] == createdDetails['leave_type']) {}
    }
    var request = http.MultipartRequest(
        'POST', Uri.parse('$typedServerUrl/api/leave/request/'));
    request.fields['employee_id'] = createdDetails['employee_id'].toString();
    request.fields['description'] = createdDetails['description'];
    request.fields['end_date_breakdown'] = createdDetails['end_date_breakdown'];
    request.fields['start_date_breakdown'] =
    createdDetails['start_date_breakdown'];
    request.fields['start_date'] = createdDetails['start_date'];
    request.fields['end_date'] = createdDetails['end_date'];
    request.fields['leave_type_id'] =
        createdDetails['leave_type_id'].toString();
    if (checkfile) {
      var attachment =
      await http.MultipartFile.fromPath('attachment', filePath);
      request.files.add(attachment);
    }
    request.headers['Authorization'] = 'Bearer $token';
    var response = await request.send();
    if (response.statusCode == 201) {
      isSaveClick = false;
      _errorMessage = null;
      currentPage = 0;
      requestedRecords.clear();
      approvedRecords.clear();
      cancelledRecords.clear();
      rejectedRecords.clear();
      getAllLeaveRequest();
      getRequestedCount();
      getApprovedCount();
      getCancelledCount();
      getRejectedCount();
      setState(() {});
    } else {
      isSaveClick = true;
      var responseBody = await response.stream.bytesToString();
      var errorJson = jsonDecode(responseBody);
      setState(() {
        if (DateTime.parse(createdDetails['end_date'])
            .isBefore(DateTime.parse(createdDetails['start_date']))) {
          _errorMessage = errorJson["end_date"].join(", ");
        } else if (errorJson.containsKey("description")) {
          _errorMessage = errorJson["description"].join(", ");
        } else if (errorJson.containsKey("start_date_breakdown")) {
          _errorMessage = errorJson["start_date_breakdown"].join(", ");
        } else if (errorJson.containsKey("start_date")) {
          _errorMessage = errorJson["start_date"].join(", ");
        } else if (errorJson.containsKey("end_date_breakdown")) {
          _errorMessage = errorJson["end_date_breakdown"].join(", ");
        } else if (errorJson.containsKey("end_date")) {
          _errorMessage = errorJson["end_date"].join(", ");
        } else if (errorJson.containsKey("attachment")) {
          _errorMessage = "Attachment field is required";
        } else if (errorJson.containsKey("non_field_errors")) {
          _errorMessage = errorJson["non_field_errors"].join(", ");
        } else if (errorJson.containsKey("leave_type_id")) {
          _errorMessage = "Leave Type field is required";
        } else {
          _errorMessage = "An unknown error occurred.";
        }
      });
    }
  }

  Future<void> getLeaveTypes(selectedEmployeeId) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var employeeID = selectedEmployeeId ?? prefs.getInt("employee_id");
    var uri =
    Uri.parse('$typedServerUrl/api/leave/employee-leave-type/$employeeID/');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      setState(() {
        leaveTypes = List<Map<String, dynamic>>.from(
            jsonDecode(response.body)['results']);
        leaveItem.clear();
        for (var leaveType in leaveTypes) {
          String leaveId = "${leaveType['id']}";
          leaveItem.add(leaveType['name']);
          leaveItemsIdMap[leaveType['name']] = leaveId;
        }
        selectedLeaveType = null;
      });
    } else {}
    if (selectedLeaveId == null) {
      setState(() {
        selectedLeaveId = null;
        selectedLeaveType = null;
      });
    }
  }

  Future<void> approveRequest(int approveId) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/leave/approve/$approveId/');
    var response = await http.put(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      setState(() {
        isSaveClick = false;
        for (var request in myAllRequests) {
          if (request['id'] == approveId) {
            request['status'] = 'approved';
            break;
          }
        }

        for (var request in requestedRecords) {
          if (request['id'] == approveId) {
            request['status'] = 'approved';
            break;
          }
        }
      });
    }
    else {
      isSaveClick = true;
    }
  }

  Future<void> rejectRequest(int rejectId, String rejectionReason) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/leave/reject/$rejectId/');
    var response = await http.put(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      setState(() {
        isSaveClick = false;
        for (var request in myAllRequests) {
          if (request['id'] == rejectId) {
            request['status'] = 'rejected';
            request['description'] = rejectionReason;
            break;
          }
        }

        for (var request in requestedRecords) {
          if (request['id'] == rejectId) {
            request['status'] = 'rejected';
            break;
          }
        }

        for (var request in approvedRecords) {
          if (request['id'] == rejectId) {
            request['status'] = 'rejected';
            break;
          }
        }
      });
    }
    else {
      isSaveClick = true;
    }
  }

  Future<void> deleteRequest(int leaveId) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/leave/request/$leaveId/');
    var response = await http.delete(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      isSaveClick = false;
      myAllRequests.removeWhere((item) => item['id'] == leaveId);
      requestedRecords.removeWhere((item) => item['id'] == leaveId);
      approvedRecords.removeWhere((item) => item['id'] == leaveId);
      cancelledRecords.removeWhere((item) => item['id'] == leaveId);
      rejectedRecords.removeWhere((item) => item['id'] == leaveId);
      getAllLeaveRequest();
      getRequestedCount();
      getApprovedCount();
      getCancelledCount();
      getRejectedCount();
      setState(() {});
    }
    else {
      isSaveClick = true;
    }
  }

  Future<void> cancelRequest(int cancelId, String description) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/leave/cancel/$cancelId/');
    var response = await http.put(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      setState(() {
        for (var request in myAllRequests) {
          if (request['id'] == cancelId) {
            request['status'] = 'cancelled';
            request['description'] = description;
            break;
          }
        }
      });
    }
  }

  Future<void> getAllLeaveTypeName() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/leave/leave-type/');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      setState(() {
        leaveType = List<Map<String, dynamic>>.from(
          jsonDecode(response.body)['results'],
        );
        for (var rec in leaveType) {
          leaveItems.add(rec['name']);
        }
      });
    }
  }

  Future<void> getListEmployees() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/employee/employees/');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      setState(() {
        requestsEmployeesName = List<Map<String, dynamic>>.from(
          jsonDecode(response.body)['results'],
        );
      });
    }
  }

  _showUpdateDialog(BuildContext context, Map<String, dynamic> record,
      List<Map<String, dynamic>> currentRequests, String recordId) {
    _typeAheadEditController.text = record['leave_type_id']['name'] ?? " ";
    _typeAheadEmployeeEditController.text =
        record['employee_id']['full_name'] ?? " ";

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
                          "Edit Leave",
                          style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                    content: SingleChildScrollView(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.95,
                        height: MediaQuery.of(context).size.height * 0.5,
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
                              const Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Text("Employee"),
                              ),
                              SizedBox(
                                  height:
                                  MediaQuery.of(context).size.height * 0.01),
                              TypeAheadField<String>(
                                textFieldConfiguration: TextFieldConfiguration(
                                  controller: _typeAheadEmployeeEditController,
                                  decoration: InputDecoration(
                                    labelText: 'Choose an employee',
                                    labelStyle: TextStyle(color: Colors.grey[350]),
                                    border: const OutlineInputBorder(),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 10.0),
                                    errorText: _validateEmployee
                                        ? 'Please select a leave type'
                                        : null,
                                  ),
                                ),
                                suggestionsCallback: (pattern) {
                                  return employeeItem
                                      .where((leaveType) => leaveType
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
                                    _typeAheadEmployeeEditController.text =
                                        suggestion;
                                    editEmployeeType = suggestion;
                                    selectedEmployeeId = employeeIdMap[suggestion];
                                    getLeaveTypes(selectedEmployeeId);
                                    _validateEmployee = false;
                                  });
                                },
                                noItemsFoundBuilder: (context) => const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'No Leave Types Found',
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
                                "Leave Type",
                              ),
                              SizedBox(
                                  height:
                                  MediaQuery.of(context).size.height * 0.01),
                              TypeAheadField<String>(
                                textFieldConfiguration: TextFieldConfiguration(
                                  controller: _typeAheadEditController,
                                  decoration: InputDecoration(
                                    labelText: 'Choose a Leave Type',
                                    labelStyle: TextStyle(color: Colors.grey[350]),
                                    border: const OutlineInputBorder(),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 10.0),
                                    errorText: _validateLeaveType
                                        ? 'Please select a leave type'
                                        : null,
                                  ),
                                ),
                                suggestionsCallback: (pattern) {
                                  return leaveItem
                                      .where((leaveType) => leaveType
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
                                    _typeAheadEditController.text = suggestion;
                                    editLeaveType = suggestion;
                                    selectedLeaveId = leaveItemsIdMap[suggestion];
                                    _validateLeaveType = false;
                                  });
                                },
                                noItemsFoundBuilder: (context) => const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'No Leave Types Found',
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
                              const Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Text("Start Date"),
                              ),
                              SizedBox(
                                  height:
                                  MediaQuery.of(context).size.height * 0.01),
                              Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: TextField(
                                  readOnly: true,
                                  controller: startDateInput,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding:
                                    EdgeInsets.symmetric(horizontal: 10.0),
                                    hintText: "Select Date",
                                  ),
                                  onTap: () async {
                                    final selectedDate = await showCustomDatePicker(
                                        context, DateTime.now());
                                    if (selectedDate != null) {
                                      DateTime parsedDate = DateFormat('yyyy-MM-dd')
                                          .parse(selectedDate);
                                      setState(() {
                                        startDate = parsedDate;
                                        startDateInput.text =
                                            DateFormat('yyyy-MM-dd')
                                                .format(startDate!);
                                      });
                                    }
                                  },
                                ),
                              ),
                              SizedBox(
                                  height:
                                  MediaQuery.of(context).size.height * 0.03),
                              const Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Text(" Start Date Breakdown "),
                              ),
                              SizedBox(
                                  height:
                                  MediaQuery.of(context).size.height * 0.01),
                              DropdownSearch<String>(
                                items: breakdownMaps.values.toList().cast<String>(),
                                selectedItem:
                                breakdownMaps[record['start_date_breakdown']],
                                onChanged: (newValue) {
                                  selectedStartDateValue = breakdownMaps.entries
                                      .firstWhere(
                                          (entry) => entry.value == newValue)
                                      .key;
                                  editStartDateBreakdown = selectedStartDateValue;
                                },
                                popupProps: PopupProps.menu(
                                  constraints: BoxConstraints(
                                      maxHeight:
                                      MediaQuery.of(context).size.height *
                                          0.23),
                                  // Set your desired height
                                  showSearchBox: false,
                                ),
                              ),
                              SizedBox(
                                  height:
                                  MediaQuery.of(context).size.height * 0.03),
                              const Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Text("End Date"),
                              ),
                              SizedBox(
                                  height:
                                  MediaQuery.of(context).size.height * 0.01),
                              Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: TextField(
                                  readOnly: true,
                                  controller: endDateInput,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding:
                                    EdgeInsets.symmetric(horizontal: 10.0),
                                    hintText: "Select Date",
                                  ),
                                  onTap: () async {
                                    final selectedDate = await showCustomDatePicker(
                                        context, DateTime.now());
                                    if (selectedDate != null) {
                                      DateTime parsedDate = DateFormat('yyyy-MM-dd')
                                          .parse(selectedDate);
                                      setState(() {
                                        endDate = parsedDate;
                                        endDateInput.text = DateFormat('yyyy-MM-dd')
                                            .format(endDate!);
                                      });
                                    }
                                  },
                                ),
                              ),
                              SizedBox(
                                  height:
                                  MediaQuery.of(context).size.height * 0.03),
                              const Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Text("End Date Breakdown"),
                              ),
                              SizedBox(
                                  height:
                                  MediaQuery.of(context).size.height * 0.01),
                              DropdownSearch<String>(
                                items: breakdownMaps.values.toList().cast<String>(),
                                selectedItem:
                                breakdownMaps[record['end_date_breakdown']],
                                onChanged: (newValue) {
                                  selectedEndDateValue = breakdownMaps.entries
                                      .firstWhere(
                                          (entry) => entry.value == newValue)
                                      .key;
                                  editEndDateBreakdown = selectedEndDateValue;
                                },
                                popupProps: PopupProps.menu(
                                  constraints: BoxConstraints(
                                      maxHeight:
                                      MediaQuery.of(context).size.height *
                                          0.23),
                                  // Set your desired height
                                  showSearchBox: false,
                                ),
                              ),
                              SizedBox(
                                  height:
                                  MediaQuery.of(context).size.height * 0.03),
                              const Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Text("Description"),
                              ),
                              SizedBox(
                                  height:
                                  MediaQuery.of(context).size.height * 0.01),
                              Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: TextField(
                                  controller: leaveDescription,
                                  decoration: InputDecoration(
                                    border: const OutlineInputBorder(),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 10.0),
                                    errorText: _validateDescription
                                        ? 'Description cannot be empty'
                                        : null,
                                  ),
                                  onChanged: (newValue) {
                                    leaveDescription.text = newValue;
                                    _validateDescription = newValue.isEmpty;
                                  },
                                ),
                              ),
                              if (currentLeaveRequests.isNotEmpty &&
                                  currentLeaveRequests[0]['attachment'] != null)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Attachment',
                                      style: TextStyle(color: grey700),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        String pdfPath =
                                        currentLeaveRequests[0]['attachment'];
                                        if (pdfPath.endsWith('.png') ||
                                            pdfPath.endsWith('.jpg') ||
                                            pdfPath.endsWith('.jpeg') ||
                                            pdfPath.endsWith('.gif')) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ImageViewer(imagePath: pdfPath,
                                                    token: getToken,),
                                            ),
                                          );
                                        } else {
                                          Navigator.pushNamed(
                                            context,
                                            '/attachment_view',
                                            arguments: pdfPath,
                                          );
                                        }
                                      },
                                      child: const Text(
                                        'View Attachment',
                                        style: TextStyle(
                                          decoration: TextDecoration.underline,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              SizedBox(
                                  height:
                                  MediaQuery.of(context).size.height * 0.01),
                              IconButton(
                                icon: const Icon(Icons.attach_file),
                                onPressed: () async {
                                  XFile? file = await uploadFile(context);
                                  if (file != null) {
                                    setState(() {
                                      pickedFile = file;
                                      fileName = file.name;
                                      filePath = file.path;
                                      checkFile = true;
                                      setFileName();
                                    });
                                  }
                                },
                              ),
                              TextField(
                                controller: _fileNameController,
                                readOnly: true,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  labelStyle: TextStyle(color: Colors.grey[350]),
                                  contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 5.0),
                                  suffixIcon: _fileNameController.text.isNotEmpty
                                      ? IconButton(
                                    padding: EdgeInsets.only(
                                        bottom: MediaQuery.of(context)
                                            .size
                                            .height *
                                            0.0168),
                                    icon: const Icon(Icons.close,
                                        color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        _fileNameController.clear();
                                      });
                                    },
                                  )
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    actions: <Widget>[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (isSaveClick == true) {
                              isSaveClick = false;
                              if (leaveDescription.text.isEmpty) {
                                setState(() {
                                  isSaveClick = true;
                                  _validateDescription = true;
                                  Navigator.of(context).pop(true);
                                  _showUpdateDialog(
                                      context, record, currentRequests, recordId);
                                });
                              } else {
                                setState(() {
                                  _validateAttachment = false;
                                  isAction = true;
                                });
                                Map<String, dynamic> updatedDetails = {
                                  'id': record['id'],
                                  'start_date_breakdown': editStartDateBreakdown ??
                                      record['start_date_breakdown'],
                                  'end_date_breakdown': editEndDateBreakdown ??
                                      record['end_date_breakdown'],
                                  'status': record['status'],
                                  "employee_id": selectedEmployeeId ??
                                      record['employee_id']['id'],
                                  "leave_type_id": selectedLeaveId ??
                                      record['leave_type_id']['id'],
                                  'start_date': startDateInput.text,
                                  'end_date': endDateInput.text,
                                  'description': leaveDescription.text,
                                };
                                await updateRequest(
                                    updatedDetails, checkFile, fileName, filePath);
                                setState(() {
                                  isAction = false;
                                });
                                if (_errorMessage == null ||
                                    _errorMessage!.isEmpty) {
                                  Navigator.of(context).pop();
                                  showUpdateAnimation();
                                } else {
                                  Navigator.of(context).pop();
                                  _showUpdateDialog(
                                      context, record, currentRequests, recordId);
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
            });
      },
    );
  }

  Future<void> updateRequest(Map<String, dynamic> updatedDetails, checkFile,
      String fileName, String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var itemId = updatedDetails['id'];
    var request = http.MultipartRequest(
        'PUT', Uri.parse('$typedServerUrl/api/leave/request/$itemId/'));
    request.fields['description'] = updatedDetails['description'];
    request.fields['employee_id'] = updatedDetails['employee_id'].toString();
    request.fields['end_date_breakdown'] = updatedDetails['end_date_breakdown'];
    request.fields['start_date_breakdown'] =
    updatedDetails['start_date_breakdown'];
    request.fields['start_date'] = updatedDetails['start_date'];
    request.fields['end_date'] = updatedDetails['end_date'];
    request.fields['leave_type_id'] =
        updatedDetails['leave_type_id'].toString();
    if (checkFile) {
      var attachment =
      await http.MultipartFile.fromPath('attachment', filePath);
      request.files.add(attachment);
    }
    request.headers['Authorization'] = 'Bearer $token';
    var response = await request.send();
    if (response.statusCode == 201) {
      isSaveClick = false;
      _errorMessage = null;
      requestedRecords.clear();
      approvedRecords.clear();
      cancelledRecords.clear();
      rejectedRecords.clear();
      currentPage = 0;
      getAllLeaveRequest();
      getRequestedCount();
      getApprovedCount();
      getCancelledCount();
      getRejectedCount();
      setState(() {});
    } else {
      isSaveClick = true;
      var responseBody = await response.stream.bytesToString();
      var errorJson = jsonDecode(responseBody);
      setState(() {
        if (DateTime.parse(updatedDetails['end_date'])
            .isBefore(DateTime.parse(updatedDetails['start_date']))) {
          _errorMessage = errorJson["end_date"].join(", ");
        } else if (errorJson.containsKey("description")) {
          _errorMessage = "Description is required";
        } else if (errorJson.containsKey("start_date_breakdown")) {
          _errorMessage = errorJson["start_date_breakdown"].join(", ");
        } else if (errorJson.containsKey("leave_type_id")) {
          _errorMessage = errorJson["leave_type_id"].join(", ");
        } else if (errorJson.containsKey("attachment")) {
          _errorMessage = "Attachment field is required";
        } else if (errorJson.containsKey("non_field_errors")) {
          _errorMessage = errorJson["non_field_errors"].join(", ");
        }
      });
    }
  }

  List<Map<String, dynamic>> filterAllRecords(String searchText) {
    if (searchText.isEmpty) {
      return myAllRequests;
    }
    return myAllRequests.where((record) {
      final fullName = record['employee_id']['full_name']?.toLowerCase() ?? '';
      final badgeId = record['employee_id']['badge_id']?.toLowerCase() ?? '';
      final leaveType = record['leave_type_id']['name']?.toLowerCase() ?? '';
      final status = record['status']?.toLowerCase() ?? '';
      final description = record['description']?.toLowerCase() ?? '';

      return fullName.contains(searchText.toLowerCase()) ||
          badgeId.contains(searchText.toLowerCase()) ||
          leaveType.contains(searchText.toLowerCase()) ||
          status.contains(searchText.toLowerCase()) ||
          description.contains(searchText.toLowerCase());
    }).toList();
  }

  List<Map<String, dynamic>> filterRequestedRecords(String searchText) {
    if (searchText.isEmpty) {
      return requestedRecords;
    }
    return requestedRecords.where((record) {
      final fullName = record['employee_id']['full_name']?.toLowerCase() ?? '';
      final badgeId = record['employee_id']['badge_id']?.toLowerCase() ?? '';
      final leaveType = record['leave_type_id']['name']?.toLowerCase() ?? '';
      final status = record['status']?.toLowerCase() ?? '';
      final description = record['description']?.toLowerCase() ?? '';

      return fullName.contains(searchText.toLowerCase()) ||
          badgeId.contains(searchText.toLowerCase()) ||
          leaveType.contains(searchText.toLowerCase()) ||
          status.contains(searchText.toLowerCase()) ||
          description.contains(searchText.toLowerCase());
    }).toList();
  }

  List<Map<String, dynamic>> filterApprovedRecords(String searchText) {
    if (searchText.isEmpty) {
      return approvedRecords;
    } else {
      return approvedRecords.where((record) {
        final firstName = record['employee_id']['full_name'] ?? '';
        final lastName = record['employee_last_name'] ?? '';
        final fullName = (firstName + ' ' + lastName).toLowerCase();
        return fullName.contains(searchText.toLowerCase());
      }).toList();
    }
  }

  List<Map<String, dynamic>> filterCancelledRecords(String searchText) {
    if (searchText.isEmpty) {
      return cancelledRecords;
    } else {
      return cancelledRecords.where((record) {
        final firstName = record['employee_id']['full_name'] ?? '';
        final lastName = record['employee_last_name'] ?? '';
        final fullName = (firstName + ' ' + lastName).toLowerCase();
        return fullName.contains(searchText.toLowerCase());
      }).toList();
    }
  }

  List<Map<String, dynamic>> filterRejectedRecords(String searchText) {
    if (searchText.isEmpty) {
      return rejectedRecords;
    } else {
      return rejectedRecords.where((record) {
        final firstName = record['employee_id']['full_name'] ?? '';
        final lastName = record['employee_last_name'] ?? '';
        final fullName = (firstName + ' ' + lastName).toLowerCase();
        return fullName.contains(searchText.toLowerCase());
      }).toList();
    }
  }

  Future getAllLeaveRequest({bool reset = false}) async {
    if (reset) {
      currentPage = 1;
      myAllRequests.clear();
      hasMoreAll = true;
    }

    if (!hasMoreAll) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      var token = prefs.getString("token");
      var typedServerUrl = prefs.getString("typed_url");

      var uri = Uri.parse(
          '$typedServerUrl/api/leave/request?page=$currentPage${searchText.isNotEmpty ? '&search=$searchText' : ''}');

      var response = await http.get(uri, headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });

      if (response.statusCode == 200) {
        final results = (jsonDecode(response.body)['results'] as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        setState(() {
          if (results.isEmpty) {
            hasMoreAll = false;
          } else {
            myAllRequests.addAll(results);
            // remove duplicates
            myAllRequests = myAllRequests
                .map((m) => jsonEncode(m))
                .toSet()
                .map((s) => jsonDecode(s) as Map<String, dynamic>)
                .toList();
            allRequestsLength = jsonDecode(response.body)['count'] ?? 0;
            filteredRecords = filterAllRecords(searchText);
          }
          isLoading = false;
          _isShimmerVisible = false;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          hasMoreAll = false;
          isLoading = false;
          _isShimmerVisible = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        _isShimmerVisible = false;
      });
      // Handle error
    }
  }

  Future<void> getAllPagesLeaveRequest() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/leave/request?search=$searchText');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      setState(() {
        myAllPagesRequests = List<Map<String, dynamic>>.from(
          jsonDecode(response.body)['results'],
        );
        isLoading = false;
      });
    }
  }

  Future<void> getRequestedCount({bool reset = false}) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");

    if (reset) {
      currentPage = 1;
      requestedRecords.clear();
      hasMoreRequested = true;
    }

    if (!hasMoreRequested) return;

    var uri = Uri.parse(
        '$typedServerUrl/api/leave/request?status=requested&search=$searchText&page=$currentPage');

    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });

    if (response.statusCode == 200) {
      final results = (jsonDecode(response.body)['results'] as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      if (results.isEmpty) {
        hasMoreRequested = false;
        return;
      }

      setState(() {
        requestedRecords.addAll(results);
        requestedRecords = requestedRecords
            .map((m) => jsonEncode(m))
            .toSet()
            .map((s) => jsonDecode(s) as Map<String, dynamic>)
            .toList();
        requestedLength = jsonDecode(response.body)['count'] ?? 0;
        filteredRecordsRequested = filterRequestedRecords(searchText);
        isLoading = false;
      });
    } else if (response.statusCode == 404) {
      hasMoreRequested = false;
    }
  }

  Future<void> getApprovedCount({bool reset = false}) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");

    if (reset) {
      currentPage = 1;
      approvedRecords.clear();
      hasMoreApproved = true;
    }

    if (!hasMoreApproved) return;

    var uri = Uri.parse(
        '$typedServerUrl/api/leave/request?status=approved&search=$searchText&page=$currentPage');

    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });

    if (response.statusCode == 200) {
      final results = (jsonDecode(response.body)['results'] as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      if (results.isEmpty) {
        hasMoreApproved = false;
        return;
      }

      setState(() {
        approvedRecords.addAll(results);
        approvedRecords = approvedRecords
            .map((m) => jsonEncode(m))
            .toSet()
            .map((s) => jsonDecode(s) as Map<String, dynamic>)
            .toList();
        approvedLength = jsonDecode(response.body)['count'] ?? 0;
        filteredRecordsApproved = filterApprovedRecords(searchText);
        isLoading = false;
      });
    } else if (response.statusCode == 404) {
      hasMoreApproved = false;
    }
  }

  Future<void> getCancelledCount({bool reset = false}) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");

    if (reset) {
      currentPage = 1;
      cancelledRecords.clear();
      hasMoreCancelled = true;
    }

    if (!hasMoreCancelled) return;

    var uri = Uri.parse(
        '$typedServerUrl/api/leave/request?status=cancelled&search=$searchText&page=$currentPage');

    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });

    if (response.statusCode == 200) {
      final results = (jsonDecode(response.body)['results'] as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      if (results.isEmpty) {
        hasMoreCancelled = false;
        return;
      }

      setState(() {
        cancelledRecords.addAll(results);
        cancelledRecords = cancelledRecords
            .map((m) => jsonEncode(m))
            .toSet()
            .map((s) => jsonDecode(s) as Map<String, dynamic>)
            .toList();
        cancelledLength = jsonDecode(response.body)['count'] ?? 0;
        filteredRecordsCancelled = filterCancelledRecords(searchText);
        isLoading = false;
      });
    } else if (response.statusCode == 404) {
      hasMoreCancelled = false;
    }
  }

  Future<void> getRejectedCount({bool reset = false}) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");

    if (reset) {
      currentPage = 1;
      rejectedRecords.clear();
      hasMoreRejected = true;
    }

    if (!hasMoreRejected) return;

    var uri = Uri.parse(
        '$typedServerUrl/api/leave/request?status=rejected&search=$searchText&page=$currentPage');

    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });

    if (response.statusCode == 200) {
      final results = (jsonDecode(response.body)['results'] as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      if (results.isEmpty) {
        hasMoreRejected = false;
        return;
      }

      setState(() {
        rejectedRecords.addAll(results);
        rejectedRecords = rejectedRecords
            .map((m) => jsonEncode(m))
            .toSet()
            .map((s) => jsonDecode(s) as Map<String, dynamic>)
            .toList();
        rejectedLength = jsonDecode(response.body)['count'] ?? 0;
        filteredRecordsRejected = filterRejectedRecords(searchText);
        isLoading = false;
      });
    } else if (response.statusCode == 404) {
      hasMoreRejected = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
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
          automaticallyImplyLeading: false,
          title: Row(children: [
            const Text(
              'Leave Request',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: MediaQuery.of(context).size.width * 0.008),
          ]),
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
                          selectedEmployee = null;
                          selectedEmployeeId = null;
                          selectedLeaveId = null;
                          editStartDateBreakdown = null;
                          editEndDateBreakdown = null;
                          isAction = false;
                          _validateEmployee = false;
                          _validateLeaveType = false;
                          _validateStartDateBreakdown = false;
                          _validateEndDateBreakdown = false;
                          _validateDescription = false;
                          _validateAttachment = false;
                          _validateDate = false;
                          _validateEndDate = false;
                          startDateSelect.clear();
                          endDateSelect.clear();
                          descriptionSelect.clear();
                          _fileNameController.clear();
                          _typeAheadEditController.clear();
                          _typeAheadCreateController.clear();
                          _typeAheadEmployeeCreateController.clear();
                          _typeAheadEmployeeEditController.clear();
                          startDate == null;
                          getEmployees();
                        });
                        showCreateLeaveDialog(context);
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
        body: _isShimmerVisible
            ? _buildLoadingWidget()
            : _buildLeaveRequestWidget(),
        drawer: Drawer(
          child: FutureBuilder<void>(
            future: checkPermissions(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // Show shimmer effect while waiting
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
                        Navigator.pushNamed(
                            context, '/all_assigned_leave');
                      },
                    )
                        : const SizedBox.shrink(),

                  ],
                );
              }
            },
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
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Stack(
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
                        margin: const EdgeInsets.all(8), // Remove any margin
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
                  Tab(text: 'All ($allRequestsLength)'),
                  Tab(text: 'Requested ($requestedLength)'),
                  Tab(text: 'Approved ($approvedLength)'),
                  Tab(text: 'Cancelled ($cancelledLength)'),
                  Tab(text: 'Rejected ($rejectedLength)'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildShimmerTabContent(),
                    _buildShimmerTabContent(),
                    _buildShimmerTabContent(),
                    _buildShimmerTabContent(),
                    _buildShimmerTabContent(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerTabContent() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300] ?? Colors.grey,
      highlightColor: Colors.grey[100] ?? Colors.white,
      child: ListView.builder(
        itemCount: 3,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[50] ?? Colors.grey),
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            height: 75.0,
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
    );
  }

  Widget _buildLeaveRequestWidget() {
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
                      margin: const EdgeInsets.all(8), // Remove any margin
                      elevation: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade50),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: // Update the TextField in the _buildLeaveRequestWidget method
                        TextField(
                          onChanged: (value) {
                            if (_debounce?.isActive ?? false) _debounce!.cancel();
                            _debounce = Timer(const Duration(milliseconds: 500), () {
                              setState(() {
                                searchText = value;
                                currentPage = 1; // Reset to first page when searching
                                myAllRequests.clear();
                                requestedRecords.clear();
                                approvedRecords.clear();
                                cancelledRecords.clear();
                                rejectedRecords.clear();
                                getAllLeaveRequest(reset: true);
                                getRequestedCount(reset: true);
                                getApprovedCount(reset: true);
                                getCancelledCount(reset: true);
                                getRejectedCount(reset: true);
                              });
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search',
                            hintStyle: TextStyle(color: Colors.blueGrey.shade300, fontSize: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            prefixIcon: Transform.scale(
                              scale: 0.8,
                              child: Icon(Icons.search, color: Colors.blueGrey.shade300),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
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
              labelColor: Colors.red,
              unselectedLabelColor: Colors.grey,
              isScrollable: true,
              indicatorColor: Colors.red,
              tabs: [
                Tab(text: 'All ($allRequestsLength)'),
                Tab(text: 'Requested ($requestedLength)'),
                Tab(text: 'Approved ($approvedLength)'),
                Tab(text: 'Cancelled ($cancelledLength)'),
                Tab(text: 'Rejected ($rejectedLength)'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  allRequestsLength == 0
                      ? ListView(
                    children: const [
                      Padding(
                        padding: EdgeInsets.only(top: 40.0),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calendar_month_outlined,
                                color: Colors.black,
                                size: 92,
                              ),
                              SizedBox(height: 20),
                              Text(
                                "There are no Leave request to display",
                                style: TextStyle(
                                    fontSize: 16.0,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                      : buildTabContent(myAllRequests),
                  requestedLength == 0
                      ? ListView(
                    children: const [
                      Padding(
                        padding: EdgeInsets.only(top: 40.0),
                        child: Center(
                          child: Column(
                            children: [
                              Column(
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
                                    "There are no Leave request to display",
                                    style: TextStyle(
                                        fontSize: 16.0,
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                      : buildRequestedTabContent(requestedRecords),
                  approvedLength == 0
                      ? ListView(
                    children: const [
                      Padding(
                        padding: EdgeInsets.only(top: 40.0),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calendar_month_outlined,
                                color: Colors.black,
                                size: 92,
                              ),
                              SizedBox(height: 20),
                              Text(
                                "There are no Leave request to display",
                                style: TextStyle(
                                    fontSize: 16.0,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                      : buildApprovedTabContent(approvedRecords),
                  cancelledLength == 0
                      ? ListView(
                    children: const [
                      Padding(
                        padding: EdgeInsets.only(top: 40.0),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calendar_month_outlined,
                                color: Colors.black,
                                size: 92,
                              ),
                              SizedBox(height: 20),
                              Text(
                                "There are no Leave request to display",
                                style: TextStyle(
                                    fontSize: 16.0,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                      : buildCancelledTabContent(cancelledRecords),
                  rejectedLength == 0
                      ? ListView(
                    children: const [
                      Padding(
                        padding: EdgeInsets.only(top: 40.0),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calendar_month_outlined,
                                color: Colors.black,
                                size: 92,
                              ),
                              SizedBox(height: 20),
                              Text(
                                "There are no Leave request to display",
                                style: TextStyle(
                                    fontSize: 16.0,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                      : buildRejectedTabContent(rejectedRecords),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildTabContent(List<Map<String, dynamic>> myAllRequests) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isShimmerVisible)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: 10,
                itemBuilder: (context, index) {
                  return Shimmer.fromColors(
                    baseColor: grey300,
                    highlightColor: grey100,
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 25.0,
                      ),
                      title: Container(
                        width: 200.0,
                        height: 20.0,
                        color: Colors.white,
                      ),
                      subtitle: Container(
                        width: 150.0,
                        height: 15.0,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
          )
        else
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView.builder(
                controller: _scrollController,
                shrinkWrap: true,
                  itemCount: (searchText.isEmpty ? myAllRequests.length : filteredRecords.length) +
                      (isFetchingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == (searchText.isEmpty ? myAllRequests.length : filteredRecords.length)) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final record = searchText.isEmpty ? myAllRequests[index] : filteredRecords[index];
                    return buildAllLeaveTile(
                      _getBreakdown(record['start_date_breakdown']),
                      record,
                      baseUrl,
                      getToken,
                      record['employee_id']['full_name'],
                      record['employee_id']['employee_profile'] ?? "",
                      record['employee_id']['badge_id'] ?? "",
                      _getStateInfo(record['status']),
                      record['id'].toString(),
                    );
                  }
              ),
            ),
          ),
      ],
    );
  }

  Widget buildRequestedTabContent(List<Map<String, dynamic>> requestedRecords) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: 10,
                itemBuilder: (context, index) {
                  return Shimmer.fromColors(
                    baseColor: grey300,
                    highlightColor: grey100,
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 25.0,
                      ),
                      title: Container(
                        width: 200.0,
                        height: 20.0,
                        color: Colors.white,
                      ),
                      subtitle: Container(
                        width: 150.0,
                        height: 15.0,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
          )
        else
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView.builder(
                controller: _scrollController,
                shrinkWrap: true,
                  itemCount: (searchText.isEmpty ? requestedRecords.length : filteredRecordsRequested.length) +
                      (isFetchingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == (searchText.isEmpty ? requestedRecords.length : filteredRecordsRequested.length)) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final record = searchText.isEmpty ? requestedRecords[index] : filteredRecordsRequested[index];
                    return buildAllLeaveTile(
                      _getBreakdown(record['start_date_breakdown']),
                      record,
                      baseUrl,
                      getToken,
                      record['employee_id']['full_name'],
                      record['employee_id']['employee_profile'] ?? "",
                      record['employee_id']['badge_id'] ?? "",
                      _getStateInfo(record['status']),
                      record['id'].toString(),
                    );
                  }
              ),
            ),
          ),
      ],
    );
  }

  Widget buildApprovedTabContent(List<Map<String, dynamic>> approvedRecords) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: 10,
                itemBuilder: (context, index) {
                  return Shimmer.fromColors(
                    baseColor: grey300,
                    highlightColor: grey100,
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 25.0,
                      ),
                      title: Container(
                        width: 200.0,
                        height: 20.0,
                        color: Colors.white,
                      ),
                      subtitle: Container(
                        width: 150.0,
                        height: 15.0,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
          )
        else
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView.builder(
                controller: _scrollController,
                shrinkWrap: true,
                  itemCount: (searchText.isEmpty ? approvedRecords.length : filteredRecordsApproved.length) +
                      (isFetchingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == (searchText.isEmpty ? approvedRecords.length : filteredRecordsApproved.length)) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final record = searchText.isEmpty ? approvedRecords[index] : filteredRecordsApproved[index];
                    return buildAllLeaveTile(
                      _getBreakdown(record['start_date_breakdown']),
                      record,
                      baseUrl,
                      getToken,
                      record['employee_id']['full_name'],
                      record['employee_id']['employee_profile'] ?? "",
                      record['employee_id']['badge_id'] ?? "",
                      _getStateInfo(record['status']),
                      record['id'].toString(),
                    );
                  }
              ),
            ),
          ),
      ],
    );
  }

  Widget buildCancelledTabContent(List<Map<String, dynamic>> cancelledRecords) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: 10,
                itemBuilder: (context, index) {
                  return Shimmer.fromColors(
                    baseColor: grey300,
                    highlightColor: grey100,
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 25.0,
                      ),
                      title: Container(
                        width: 200.0,
                        height: 20.0,
                        color: Colors.white,
                      ),
                      subtitle: Container(
                        width: 150.0,
                        height: 15.0,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
          )
        else
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView.builder(
                controller: _scrollController,
                shrinkWrap: true,
                  itemCount: (searchText.isEmpty ? cancelledRecords.length : filteredRecordsCancelled.length) +
                      (isFetchingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == (searchText.isEmpty ? cancelledRecords.length : filteredRecordsCancelled.length)) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final record = searchText.isEmpty ? cancelledRecords[index] : filteredRecordsCancelled[index];
                    return buildAllLeaveTile(
                      _getBreakdown(record['start_date_breakdown']),
                      record,
                      baseUrl,
                      getToken,
                      record['employee_id']['full_name'],
                      record['employee_id']['employee_profile'] ?? "",
                      record['employee_id']['badge_id'] ?? "",
                      _getStateInfo(record['status']),
                      record['id'].toString(),
                    );
                  }
              ),
            ),
          ),
      ],
    );
  }

  Widget buildRejectedTabContent(List<Map<String, dynamic>> rejectedRecords) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: 10,
                itemBuilder: (context, index) {
                  return Shimmer.fromColors(
                    baseColor: grey300,
                    highlightColor: grey100,
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 25.0,
                      ),
                      title: Container(
                        width: 200.0,
                        height: 20.0,
                        color: Colors.white,
                      ),
                      subtitle: Container(
                        width: 150.0,
                        height: 15.0,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
          )
        else
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView.builder(
                controller: _scrollController,
                shrinkWrap: true,
                  itemCount: (searchText.isEmpty ? rejectedRecords.length : filteredRecordsRejected.length) +
                      (isFetchingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == (searchText.isEmpty ? rejectedRecords.length : filteredRecordsRejected.length)) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final record = searchText.isEmpty ? rejectedRecords[index] : filteredRecordsRejected[index];
                    return buildAllLeaveTile(
                      _getBreakdown(record['start_date_breakdown']),
                      record,
                      baseUrl,
                      getToken,
                      record['employee_id']['full_name'],
                      record['employee_id']['employee_profile'] ?? "",
                      record['employee_id']['badge_id'] ?? "",
                      _getStateInfo(record['status']),
                      record['id'].toString(),
                    );
                  }
              ),
            ),
          ),
      ],
    );
  }

  Widget buildAllLeaveTile(breakdown, Map<String, dynamic> record, baseUrl,token,
      fullName, String badgeId, String profile, stateInfo, String recordId) {
    return GestureDetector(
      onTap: () async {
        final recordId = record['id'].toString();
        await getCurrentLeaveRequest(recordId);
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
                height: MediaQuery.of(context).size.height * 0.5,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SingleChildScrollView(
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
                                  if (record['employee_id']
                                  ['employee_profile'] !=
                                      null &&
                                      record['employee_id']['employee_profile']
                                          .isNotEmpty)
                                    Positioned.fill(
                                      child: ClipOval(
                                        child: Image.network(
                                          baseUrl +
                                              record['employee_id']
                                              ['employee_profile'],
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
                                  if (record['employee_id']
                                  ['employee_profile'] ==
                                      null ||
                                      record['employee_id']['employee_profile']
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
                                    fullName ?? '',
                                    style: const TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.bold),
                                    maxLines: 2,
                                  ),
                                  Text(
                                    record['employee_id']['badge_id'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.normal,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5.0, vertical: 2.0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10.0),
                                      color: _getStateInfo(record['status'])
                                          .color
                                          .withOpacity(0.1),
                                    ),
                                    child: Text(
                                      _getStateInfo(record['status'])
                                          .displayString,
                                      style: TextStyle(
                                        color: _getStateInfo(record['status'])
                                            .color,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
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
                            height: MediaQuery.of(context).size.height * 0.05),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Leave Type',
                              style: TextStyle(color: grey700),
                            ),
                            Text('${record['leave_type_id']['name']}'),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Start Date',
                              style: TextStyle(color: grey700),
                            ),
                            Text('${record['start_date']}'),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Start Date Breakdown',
                              style: TextStyle(color: grey700),
                            ),
                            Text(
                                '${breakdownMaps[record['start_date_breakdown']]}'),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'End Date',
                              style: TextStyle(color: grey700),
                            ),
                            Text('${record['end_date']}'),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Start Date Breakdown',
                              style: TextStyle(color: grey700),
                            ),
                            Text(
                                '${breakdownMaps[record['end_date_breakdown']]}'),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Requested Days',
                              style: TextStyle(color: grey700),
                            ),
                            Text('${record['requested_days']}'),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Description',
                              style: TextStyle(color: grey700),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              height: MediaQuery.of(context).size.height * 0.1,
                              width: MediaQuery.of(context).size.width * 0.6,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(4.0),
                                color: Colors.transparent,
                              ),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: Text(
                                    '${currentLeaveRequests[0]['description']}'),
                              ),
                            ),
                          ],
                        ),
                        if (currentLeaveRequests.isNotEmpty &&
                            currentLeaveRequests[0]['attachment'] != null)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Attachment',
                                style: TextStyle(color: grey700),
                              ),
                              TextButton(
                                onPressed: () {
                                  String pdfPath =
                                  currentLeaveRequests[0]['attachment'];
                                  if (pdfPath.endsWith('.png') ||
                                      pdfPath.endsWith('.jpg') ||
                                      pdfPath.endsWith('.jpeg') ||
                                      pdfPath.endsWith('.gif')) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ImageViewer(imagePath: pdfPath,
                                              token: getToken,),
                                      ),
                                    );
                                  } else {
                                    Navigator.pushNamed(
                                      context,
                                      '/attachment_view',
                                      arguments: pdfPath,
                                    );
                                  }
                                },
                                child: const Text(
                                  'View Attachment',
                                  style: TextStyle(
                                    decoration: TextDecoration.underline,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Visibility(
                              visible: record['status'] != 'rejected' &&
                                  record['status'] != 'cancelled',
                              child: ElevatedButton(
                                onPressed: () {
                                  isSaveClick = true;
                                  showDialog(
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
                                                Navigator.of(context).pop(true);
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
                                              "Are you sure you want to Reject this Leave Request?",
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
                                                  var rejectId = record['id'];
                                                  var description =
                                                      rejectDescription.text;
                                                  await rejectRequest(
                                                      rejectId, description);
                                                  Navigator.pop(context);
                                                  showRejectAnimation();
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
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                                child: const Text(
                                  'Reject',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: record['status'] != 'rejected' &&
                                  record['status'] != 'cancelled',
                              child: ElevatedButton(
                                onPressed: record['status'] == 'approved' ||
                                    record['status'] == 'cancelled'
                                    ? null
                                    : () {
                                  isSaveClick = true;
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        backgroundColor: Colors.white,
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
                                          child: const Center(
                                            child: Text(
                                              "Are you sure you want to Approve this Leave Request?",
                                              style: TextStyle(
                                                fontWeight:
                                                FontWeight.bold,
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
                                                  var approveId =
                                                  record['id'];
                                                  await approveRequest(
                                                      approveId);
                                                  Navigator.pop(context);
                                                  Navigator.pop(context);
                                                  showApproveAnimation();
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
                                                        .circular(
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
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: record['status'] ==
                                      'approved' ||
                                      record['status'] == 'cancelled' ||
                                      record['status'] == 'rejected'
                                      ? Colors.green[
                                  400] // Dim color for disabled state
                                      : Colors.green,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                                child: const Text(
                                  'Approve',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: record['status'] == 'cancelled',
                              child: ElevatedButton(
                                onPressed: () {
                                  isSaveClick = true;
                                  showDialog(
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
                                                Navigator.of(context).pop(true);
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
                                              "Are you sure you want to Reject this Leave Request?",
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
                                                  var rejectId = record['id'];
                                                  var description =
                                                      rejectDescription.text;
                                                  await rejectRequest(
                                                      rejectId, description);
                                                  // Navigator.pop(context);
                                                  Navigator.pop(context);
                                                  showRejectAnimation();
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
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.yellow,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Reject',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
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
                        width: 40.0,
                        height: 40.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey, width: 1.0),
                        ),
                        child: Stack(
                          children: [
                            if (record['employee_id']['employee_profile'] !=
                                null &&
                                record['employee_id']['employee_profile']
                                    .isNotEmpty)
                              Positioned.fill(
                                child: ClipOval(
                                  child: Image.network(
                                    baseUrl +
                                        record['employee_id']
                                        ['employee_profile'],
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
                            if (record['employee_id']['employee_profile'] ==
                                null ||
                                record['employee_id']['employee_profile']
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
                      SizedBox(width: MediaQuery.of(context).size.width * 0.01),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName ?? '',
                              style: const TextStyle(
                                  fontSize: 16.0, fontWeight: FontWeight.bold),
                              // maxLines: 2,
                            ),
                            Text(
                              record['employee_id']['badge_id'] ?? '',
                              style: const TextStyle(
                                fontSize: 12.0,
                                fontWeight: FontWeight.normal,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: record['status'] == 'requested'
                                  ? const BorderRadius.only(
                                topLeft: Radius.circular(15.0),
                                bottomLeft: Radius.circular(15.0),
                              )
                                  : BorderRadius.circular(15.0),
                              color: Colors.blue[100],
                            ),
                            child: Padding(
                              padding:
                              const EdgeInsets.symmetric(vertical: 0.0),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  size: 18.0,
                                  color: Colors.blue,
                                ),
                                onPressed: () {
                                  setState(() {
                                    isSaveClick = true;
                                    leaveDescription.clear();
                                    _fileNameController.clear();
                                    isAction = false;
                                    _errorMessage = null;
                                    startDateInput.text =
                                        record['start_date'] ?? '';
                                    endDateInput.text =
                                        record['end_date'] ?? '';
                                    getLeaveTypes(selectedEmployeeId);
                                    getEmployees();
                                  });
                                  getAllEmployeesName();
                                  getAllLeaveTypeName();
                                  _showUpdateDialog(context, record,
                                      currentRequests, recordId);
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
                              color: Colors.red[100],
                            ),
                            child: Padding(
                              padding:
                              const EdgeInsets.symmetric(vertical: 0.0),
                              child: Visibility(
                                visible: record['status'] == 'requested',
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
                                          backgroundColor: Colors.white,
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
                                                  startDate = null;
                                                  endDate = null;
                                                  _validateDate = true;
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
                                            child: const Center(
                                              child: Text(
                                                "Are you sure you want to delete this request?",
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
                                                    var leaveId = record['id'];
                                                    await deleteRequest(leaveId);
                                                    Navigator.pop(context);
                                                    showDeleteAnimation();
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
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Start Date'),
                      Text('${record['start_date']}'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('End Date'),
                      Text('${record['end_date']}'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Leave Type'),
                      Text('${record['leave_type_id']['name']}'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Requested Days'),
                      Text('${record['requested_days']}'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Status'),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5.0, vertical: 2.0),
                        // Adjust padding as needed
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(9.0),
                          color: _getStateInfo(record['status'])
                              .color
                              .withOpacity(0.1),
                        ),
                        child: Text(
                          _getStateInfo(record['status']).displayString,
                          style: TextStyle(
                            color: _getStateInfo(record['status']).color,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Visibility(
                            visible: record['status'] != 'rejected' &&
                                record['status'] != 'cancelled',
                            child: ElevatedButton(
                              onPressed: () {
                                isSaveClick = true;
                                showDialog(
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
                                            "Are you sure you want to Reject this Leave Request?",
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
                                                var rejectId = record['id'];
                                                var description =
                                                    rejectDescription.text;
                                                await rejectRequest(
                                                    rejectId, description);
                                                Navigator.pop(context);
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
                                'Reject',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.white),
                              ),
                            ),
                          ),
                          SizedBox(
                              width: MediaQuery.of(context).size.width * 0.03),
                          Visibility(
                            visible: record['status'] != 'rejected' &&
                                record['status'] != 'cancelled',
                            child: ElevatedButton(
                              onPressed: record['status'] == 'approved' ||
                                  record['status'] == 'cancelled'
                                  ? null
                                  : () {
                                isSaveClick = true;
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      backgroundColor: Colors.white,
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
                                        child: const Center(
                                          child: Text(
                                            "Are you sure you want to Approve this Leave Request?",
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
                                                var approveId =
                                                record['id'];
                                                await approveRequest(
                                                    approveId);
                                                Navigator.pop(context);
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
                                'Approve',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.white),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: record['status'] == 'cancelled',
                            child: ElevatedButton(
                              onPressed: () {
                                isSaveClick = true;
                                showDialog(
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
                                            "Are you sure you want to Reject this Leave Request?",
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
                                                var rejectId = record['id'];
                                                var description =
                                                    rejectDescription.text;
                                                await rejectRequest(
                                                    rejectId, description);
                                                Navigator.pop(context);
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
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.yellow,
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
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Reject',
                                    style: TextStyle(
                                        fontSize: 18.0, color: Colors.white),
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
            ),
          ),
        ),
      ),
    );
  }
}

class StateInfo {
  final Color color;
  final String displayString;

  StateInfo(this.color, this.displayString);
}

StateInfo _getStateInfo(String state) {
  switch (state) {
    case 'requested':
      return StateInfo(Colors.yellow[700]!, 'Requested');
    case 'approved':
      return StateInfo(Colors.green, 'Approved');
    case 'cancelled':
      return StateInfo(Colors.red, 'Cancelled');
    case 'rejected':
      return StateInfo(Colors.orange[700]!, 'Rejected');
    default:
      return StateInfo(Colors.black, 'Unknown');
  }
}

class ImageViewer extends StatelessWidget {
  final String imagePath;
  final String token;


  const ImageViewer({super.key, required this.imagePath, required this.token});

  @override
  Widget build(BuildContext context) {
    bool isNetworkImage =
        imagePath.startsWith('http') || imagePath.startsWith('https');
    bool fileExists = !isNetworkImage && File(imagePath).existsSync();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: Colors.white,
        title: const Text('Image Viewer'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: isNetworkImage
            ? Image.network(
          imagePath,
          headers: {
            "Authorization": "Bearer $token",
          },
          errorBuilder: (context, error, stackTrace) {
            return const Text(
              'Error loading image',
              style: TextStyle(color: Colors.red),
            );
          },
        )
            : fileExists
            ? Image.file(
          File(imagePath),
          errorBuilder: (context, error, stackTrace) {
            return const Text(
              'Error loading image',
              style: TextStyle(color: Colors.red),
            );
          },
        )
            : const Text(
          'Image not found',
          style: TextStyle(color: Colors.red),
        ),
      ),
    );
  }
}
