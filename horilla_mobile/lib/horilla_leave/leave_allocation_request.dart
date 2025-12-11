import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'dart:io';
import '../../res/consts/app_colors.dart';

class LeaveAllocationRequest extends StatefulWidget {
  const LeaveAllocationRequest({super.key});

  @override
  _LeaveAllocationRequest createState() => _LeaveAllocationRequest();
}

class _LeaveAllocationRequest extends State<LeaveAllocationRequest>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _controller = NotchBottomBarController(index: -1);
  final TextEditingController _typeAheadEditController =
  TextEditingController();
  final TextEditingController _typeAheadAddController = TextEditingController();
  final TextEditingController _typeEditEmployeeController =
  TextEditingController();
  final TextEditingController _typeAddEmployeeController =
  TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _fileNameController = TextEditingController();
  final TextEditingController _controllerValue = TextEditingController();
  TextEditingController description = TextEditingController();
  TextEditingController rejectDescription = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController allocationDescription = TextEditingController();
  TextEditingController leaveDescription = TextEditingController();
  TextEditingController myLeaveDescription = TextEditingController();
  List<Map<String, dynamic>> myAllRequests = [];
  List<dynamic> leaveTypes = [];
  List<String> leaveItem = [];
  List<Map<String, dynamic>> filteredRecords = [];
  List<Map<String, dynamic>> myAllPagesRequests = [];
  List<String> employeeItem = [];
  List<Map<String, dynamic>> allEmployeeList = [];
  List<Map<String, dynamic>> requestsEmployeesName = [];
  List<Map<String, dynamic>> leaveType = [];
  List<Map<String, dynamic>> allRequests = [];
  List<Map<String, dynamic>> currentRequests = [];
  List<Map<String, dynamic>> currentAllRequests = [];
  Map<String, String> employeeIdMap = {};
  Map<String, String> leaveItemsIdMap = {};
  int leaveAllocationRequestCount = 0;
  int myLeaveAllocationCount = 0;
  int maxCount = 5;
  int? selectedLeaveId;
  int currentPage = 1;
  bool allocationCheck = false;
  bool _validateDescriptions = false;
  bool _validateAllocateDescriptions = false;
  bool _validateDays = false;
  bool _validateDescription = false;
  bool _validateLeaveType = false;
  bool _validateEmployee = false;
  bool isLoading = true;
  bool _isShimmerVisible = true;
  bool isSaveClick = true;
  bool checkFile = false;
  bool _validateAttachment = false;
  bool isAction = true;
  bool permissionLeaveTypeCheck = false;
  bool permissionAllocationCheck = true;
  bool permissionLeaveAssignCheck = false;
  bool permissionLeaveRequestCheck = false;
  bool permissionLeaveOverviewCheck = false;
  bool permissionMyLeaveRequestCheck = false;
  bool permissionLeaveAllocationCheck = false;
  bool _isShimmer = true;
  XFile? pickedFile;
  String fileName = '';
  String filePath = '';
  String searchText = '';
  String? editLeaveType;
  String? editEmployeeType;
  String? _errorMessage;
  String? selectedLeaveType;
  String? selectedEmployee;
  String? selectedEmployeeId;
  late String baseUrl = '';
  late Map<String, dynamic> arguments;
  late TabController _tabController;
  var employeeItems = [''];
  var leaveItems = [''];
  bool _isLoadingMore = false;
  bool _hasMoreAllRequests = true;
  bool _hasMoreMyRequests = true;
  int _allRequestsPage = 1;
  int _myRequestsPage = 1;
  late String getToken = '';


  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    description.text = "";

    getBaseUrl();
    fetchToken();
    prefetchData();
    _simulateLoading();

    _tabController = TabController(length: allocationCheck ? 2 : 1, vsync: this);

    if (!allocationCheck) {
      _loadInitialData();
    } else {
      getMyAllocationRequest();
    }

    getLeaveTypes();
    getEmployees();
    checkUserAllocation();
    getAllEmployeesName();

  }

  Future<void> fetchToken() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    setState(() {
      getToken = token ?? '';
    });
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _allRequestsPage = 1;
      _myRequestsPage = 1;
      allRequests.clear();
      myAllRequests.clear();
    });
    await Future.wait([
      getAllocationRequest(),
      getMyAllocationRequest(),
    ]);
  }

  Future<void> checkPermissions() async {
    await permissionLeaveOverviewChecks();
    await permissionLeaveTypeChecks();
    await permissionLeaveRequestChecks();
    await permissionLeaveAssignChecks();
    _isShimmerVisible = false;
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _fileNameController.dispose();
    super.dispose();
  }

  Future<void> _simulateLoading() async {
    await Future.delayed(const Duration(seconds: 5));
    setState(() {
      _isShimmer = false;
    });
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

  void _scrollListener() {
    if (_scrollController.offset >=
        _scrollController.position.maxScrollExtent - 200 && // Load more before reaching exact bottom
        !_scrollController.position.outOfRange &&
        !_isLoadingMore) {
      if (allocationCheck && _tabController.index == 0 && _hasMoreAllRequests) {
        _allRequestsPage++;
        getAllocationRequest();
      } else if ((!allocationCheck || _tabController.index == 1) && _hasMoreMyRequests) {
        _myRequestsPage++;
        getMyAllocationRequest();
      }
    }
  }

  void setFileName() {
    setState(() {
      _fileNameController.text = fileName;
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

  Future<void> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    var typedServerUrl = prefs.getString("typed_url");
    setState(() {
      baseUrl = typedServerUrl ?? '';
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
                      "Allocation Created Successfully",
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
                      "Allocation Deleted Successfully",
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
                      "Allocation Approved Successfully",
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
                      "Allocation Rejected Successfully",
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

  void showEditAnimation() {
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
                      "Allocation Updated Successfully",
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

  Future<void> checkUserAllocation() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/leave/check-allocation');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });

    if (response.statusCode == 200) {
      allocationCheck = true;
    } else {
      allocationCheck = false;
    }
  }

  final List<Widget> bottomBarPages = [];

  Future<void> getLeaveTypes() async {
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
        leaveTypes = jsonDecode(response.body)['results'];
        for (var leaveType in leaveTypes) {
          String leaveId = "${leaveType['id']}";
          leaveItem.add(leaveType['name']);
          leaveItemsIdMap[leaveType['name']] = leaveId;
        }
      });
    }
  }

  Future<void> updateRequest(Map<String, dynamic> updatedDetails, checkFile,
      String fileName, String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var itemId = updatedDetails['id'];
    for (var leaveType in leaveType) {
      if (leaveType['name'] == updatedDetails['leave_type']) {}
    }
    var request = http.MultipartRequest('PUT',
        Uri.parse('$typedServerUrl/api/leave/allocation-request/$itemId/'));
    request.fields['description'] = updatedDetails['description'];
    request.fields['requested_days'] = updatedDetails['requested_days'];
    request.fields['leave_type_id'] =
        updatedDetails['leave_type_id'].toString();
    request.fields['employee_id'] = updatedDetails['employee_id'].toString();
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
      allRequests.clear();
      myAllRequests.clear();
      currentPage = 0;
      await getAllocationRequest();
      await getMyAllocationRequest();
    } else {
      isSaveClick = true;
      var responseBody = await response.stream.bytesToString();
      var errorJson = jsonDecode(responseBody);
      setState(() {
        if (errorJson.containsKey("description")) {
          _errorMessage = errorJson["description"];
        } else if (errorJson.containsKey("requested_days")) {
          _errorMessage = errorJson["requested_days"];
        } else if (errorJson.containsKey("leave_type_id")) {
          _errorMessage = errorJson["leave_type_id"];
        } else if (errorJson.containsKey("employee_id")) {
          _errorMessage = errorJson["employee_id"];
        } else {
          _errorMessage = errorJson["non_field_errors"];
        }
      });
    }
  }

  List<String> allEmployeeNames = [];

  Future<void> getEmployees() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");

    employeeItem.clear();
    int page = 1;
    bool hasMore = true;

    while (hasMore) {
      var uri = Uri.parse('$typedServerUrl/api/employee/employee-selector?page=$page');
      var response = await http.get(uri, headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'];

        if (results.isEmpty) {
          hasMore = false;
          break;
        }

        setState(() {
          for (var employee in results) {
            String fullName = "${employee['employee_first_name']} ${employee['employee_last_name']}".trim();
            String employeeId = "${employee['id']}";
            employeeItem.add(fullName);
            employeeIdMap[fullName] = employeeId;
          }
          allEmployeeList.addAll(List<Map<String, dynamic>>.from(results));
        });

        page++;
      } else {
        print('Error fetching employees: ${response.statusCode}');
        hasMore = false;
      }
    }
  }

  Future<void> updateMyRequest(Map<String, dynamic> updatedDetails, checkFile,
      String fileName, String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var itemId = updatedDetails['id'];
    var employeeID = prefs.getInt("employee_id");

    var request = http.MultipartRequest('PUT',
        Uri.parse('$typedServerUrl/api/leave/user-allocation-request/$itemId/'));
    request.fields['description'] = updatedDetails['description'];
    request.fields['requested_days'] = updatedDetails['requested_days'];
    request.fields['leave_type_id'] =
        updatedDetails['leave_type_id'].toString();
    request.fields['employee_id'] = employeeID.toString();

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
      myAllRequests.clear();
      getMyAllocationRequest();
    } else {
      isSaveClick = true;
      var responseBody = await response.stream.bytesToString();
      var errorJson = jsonDecode(responseBody);
      setState(() {
        if (errorJson.containsKey("requested_days")) {
          _errorMessage = errorJson["requested_days"].join(", ");
        } else if (errorJson.containsKey("description")) {
          _errorMessage = errorJson["description"].join(", ");
        } else if (errorJson.containsKey("leave_type_id")) {
          _errorMessage = errorJson["leave_type_id"].join(", ");
        } else if (errorJson.containsKey("employee_id")) {
          _errorMessage = errorJson["employee_id"].join(", ");
        } else if (errorJson.containsKey("non_field_errors")) {
          _errorMessage = errorJson["non_field_errors"].join(", ");
        }
      });
    }
  }

  void _showUpdateDialog(BuildContext context, Map<String, dynamic> record) {
    TextEditingController controllerValue = TextEditingController(
        text: (double.tryParse(record['requested_days']?.toString() ?? '0')
            ?.toInt() ??
            0)
            .toString());
    TextEditingController leaveDescription =
    TextEditingController(text: record['description'] ?? " ");
    _typeEditEmployeeController.text =
        record['employee_id']['full_name'] ?? " ";
    _typeAheadEditController.text = record['leave_type_id']['name'] ?? " ";
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
                      const Text("Edit Allocation",
                          style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                              color: Colors.black)),
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
                                selectedLeaveId = int.tryParse(
                                    leaveItemsIdMap[suggestion] ?? '');
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
                            child: Text("Employee"),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          TypeAheadField<String>(
                            textFieldConfiguration: TextFieldConfiguration(
                              controller: _typeEditEmployeeController,
                              decoration: InputDecoration(
                                labelText: 'Search Employee',
                                labelStyle: TextStyle(color: Colors.grey[350]),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10.0),
                                border: const OutlineInputBorder(),
                                errorText: _validateEmployee
                                    ? 'Please Select an Employee'
                                    : null,
                              ),
                            ),
                            suggestionsCallback: (pattern) {
                              return employeeItem
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
                                selectedEmployee = suggestion;
                                selectedEmployeeId = employeeIdMap[suggestion];
                                _validateEmployee = false;
                              });
                              _typeEditEmployeeController.text = suggestion;
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
                            "Requested Days",
                            style: TextStyle(color: Colors.black),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          TextField(
                            controller: controllerValue,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10.0, horizontal: 10.0),
                              labelText: 'Requested Days',
                              labelStyle: TextStyle(color: Colors.grey[350]),
                              errorText: _validateDays
                                  ? 'Please enter Requested Days'
                                  : null,
                              suffixIcon: IntrinsicHeight(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      height: 24.0,
                                      width: 24.0,
                                      child: IconButton(
                                        padding: const EdgeInsets.all(0),
                                        icon: const Icon(Icons.arrow_drop_up,
                                            size: 16.0),
                                        onPressed: () {
                                          int currentValue =
                                          int.parse(controllerValue.text);
                                          setState(() {
                                            controllerValue.text =
                                                (currentValue + 1).toString();
                                          });
                                        },
                                      ),
                                    ),
                                    SizedBox(
                                      height: 24.0,
                                      width: 24.0,
                                      child: IconButton(
                                        padding: const EdgeInsets.all(0),
                                        icon: const Icon(Icons.arrow_drop_down,
                                            size: 16.0),
                                        onPressed: () {
                                          int currentValue =
                                          int.parse(controllerValue.text);
                                          setState(() {
                                            controllerValue.text =
                                                (currentValue > 0
                                                    ? currentValue - 1
                                                    : 0)
                                                    .toString();
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.02),
                          if (record['attachment'] != null)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Attachment:',
                                  style: TextStyle(color: grey700),
                                ),
                                TextButton(
                                  onPressed: () {
                                    String pdfPath =
                                        baseUrl + record['attachment'];
                                    if (pdfPath.endsWith('.png') ||
                                        pdfPath.endsWith('.jpg') ||
                                        pdfPath.endsWith('.jpeg') ||
                                        pdfPath.endsWith('.gif')) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ImageViewer(
                                            imagePath: pdfPath,
                                            token: getToken,
                                          ),
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
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              labelStyle: TextStyle(color: Colors.grey[350]),
                              contentPadding:
                              const EdgeInsets.symmetric(horizontal: 5.0),
                              errorText: _validateAttachment
                                  ? 'Attachment is not given'
                                  : null,
                            ),
                            readOnly: true,
                            onChanged: (newValue) {
                              setState(() {
                                fileName = newValue;
                                _validateAttachment = newValue.isEmpty;
                              });
                            },
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
                            if (leaveDescription.text.isEmpty) {
                              setState(() {
                                isSaveClick = true;
                                _validateDescription = true;
                                Navigator.of(context).pop(true);
                                _showUpdateDialog(context, record);
                              });
                            } else {
                              setState(() {
                                _validateDescription = false;
                                isAction = true;
                              });
                              Map<String, dynamic> updatedDetails = {
                                'id': record['id'],
                                'status': record['status'],
                                "employee_id": selectedEmployeeId ??
                                    record['employee_id']['id'],
                                "leave_type_id": selectedLeaveId ??
                                    record['leave_type_id']['id'],
                                'requested_days': controllerValue.text,
                                'description': leaveDescription.text,
                              };
                              await updateRequest(updatedDetails, checkFile,
                                  fileName, filePath);
                              setState(() {
                                isAction = false;
                              });
                              if (_errorMessage == null ||
                                  _errorMessage!.isEmpty) {
                                Navigator.of(context).pop(true);
                                showEditAnimation();
                              } else {
                                Navigator.of(context).pop(true);
                                _showUpdateDialog(context, record);
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

  _showMyUpdateDialog(BuildContext context, Map<String, dynamic> record) {
    TextEditingController controllerValue = TextEditingController(
        text: (double.tryParse(record['requested_days']?.toString() ?? '0')
            ?.toInt() ??
            0)
            .toString());
    TextEditingController myLeaveDescription =
    TextEditingController(text: record['description'] ?? " ");
    _typeAheadEditController.text = record['leave_type_id']['name'] ?? " ";
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Edit Allocation",
                  style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () {
                  leaveItems.clear();
                  employeeItems.clear();
                  Navigator.of(context).pop();
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
                            color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                  const Text(
                    "Leave Type",
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                  TypeAheadField<String>(
                    textFieldConfiguration: TextFieldConfiguration(
                      controller: _typeAheadEditController,
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
                        _typeAheadEditController.text = suggestion;
                        editLeaveType = suggestion;
                        selectedLeaveId =
                            int.tryParse(leaveItemsIdMap[suggestion] ?? '');
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
                  SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                  const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Text("Requested Days"),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                  TextField(
                    controller: controllerValue,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 10.0, horizontal: 10.0),
                      labelText: 'Requested Days',
                      labelStyle: TextStyle(color: Colors.grey[350]),
                      errorText:
                      _validateDays ? 'Please enter Requested Days' : null,
                      suffixIcon: IntrinsicHeight(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 24.0,
                              width: 24.0,
                              child: IconButton(
                                padding: const EdgeInsets.all(0),
                                icon:
                                const Icon(Icons.arrow_drop_up, size: 16.0),
                                onPressed: () {
                                  int currentValue =
                                  int.parse(controllerValue.text);
                                  setState(() {
                                    controllerValue.text =
                                        (currentValue + 1).toString();
                                  });
                                },
                              ),
                            ),
                            SizedBox(
                              height: 24.0,
                              width: 24.0,
                              child: IconButton(
                                padding: const EdgeInsets.all(0),
                                icon: const Icon(Icons.arrow_drop_down,
                                    size: 16.0),
                                onPressed: () {
                                  int currentValue =
                                  int.parse(controllerValue.text);
                                  setState(() {
                                    controllerValue.text = (currentValue > 0
                                        ? currentValue - 1
                                        : 0)
                                        .toString();
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                  const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Text("Description"),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: TextField(
                      controller: myLeaveDescription,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10.0),
                        errorText: _validateDescriptions
                            ? 'Description cannot be empty'
                            : null,
                      ),
                      onChanged: (newValue) {
                        myLeaveDescription.text = newValue;
                        _validateDescriptions = false;
                      },
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  if (record['attachment'] != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Attachment:',
                          style: TextStyle(color: grey700),
                        ),
                        TextButton(
                          onPressed: () {
                            String pdfPath = baseUrl + record['attachment'];
                            if (pdfPath.endsWith('.png') ||
                                pdfPath.endsWith('.jpg') ||
                                pdfPath.endsWith('.jpeg') ||
                                pdfPath.endsWith('.gif')) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ImageViewer(
                                    imagePath: pdfPath,
                                    token: getToken,
                                  ),
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
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      labelStyle: TextStyle(color: Colors.grey[350]),
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 5.0),
                      errorText: _validateAttachment
                          ? 'Attachment is not given'
                          : null,
                    ),
                    readOnly: true,
                    onChanged: (newValue) {
                      setState(() {
                        fileName = newValue;
                        _validateAttachment = newValue.isEmpty;
                      });
                    },
                  ),
                ],
              ),
            ),
            // ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (isSaveClick == true) {
                    isSaveClick = false;
                    Map<String, dynamic> updatedDetails = {
                      'id': record['id'],
                      'status': record['status'],
                      "leave_type_id":
                      selectedLeaveId ?? record['employee_id']['id'],
                      'requested_days': controllerValue.text,
                      'description': myLeaveDescription.text,
                    };
                    await updateMyRequest(
                        updatedDetails, checkFile, fileName, filePath);
                    if (_errorMessage == null || _errorMessage!.isEmpty) {
                      Navigator.of(context).pop(true);
                      showEditAnimation();
                    } else {
                      Navigator.of(context).pop(true);
                      _showMyUpdateDialog(context, record);
                    }
                  }
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(Colors.red),
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                  ),
                ),
                child:
                const Text('Save', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        );
      },
    );
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

  Future<void> getMyAllocationRequest() async {
    setState(() {
      _isLoadingMore = true;
    });

    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var employeeID = prefs.getInt("employee_id");
    var typedServerUrl = prefs.getString("typed_url");

    try {
      var uri = Uri.parse(
          '$typedServerUrl/api/leave/user-allocation-request/?page=$_myRequestsPage&search=$searchText');
      var response = await http.get(uri, headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = List<Map<String, dynamic>>.from(data['results']);

        setState(() {
          if (_myRequestsPage == 1) {
            myAllRequests = results;
          } else {
            myAllRequests.addAll(results);
          }

          myLeaveAllocationCount = data['count'];
          _hasMoreMyRequests = results.isNotEmpty &&
              (myAllRequests.length < myLeaveAllocationCount);
          filteredRecords = filterMyAllocationRecords(searchText);
        });
      }
    } catch (e) {
      print('Error loading my allocation requests: $e');
    } finally {
      setState(() {
        _isLoadingMore = false;
        isLoading = false;
      });
    }
  }

  Future<void> getAllocationRequest() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");

    try {
      var uri = Uri.parse(
          '$typedServerUrl/api/leave/allocation-request/?page=$_allRequestsPage&search=$searchText');
      var response = await http.get(uri, headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = List<Map<String, dynamic>>.from(data['results']);

        setState(() {
          if (_allRequestsPage == 1) {
            allRequests = results;
          } else {
            allRequests.addAll(results);
          }

          leaveAllocationRequestCount = data['count'];
          _hasMoreAllRequests = results.isNotEmpty &&
              (allRequests.length < leaveAllocationRequestCount);
          filteredRecords = filterAllAllocationRecords(searchText);
        });
      }
    } catch (e) {
      print('Error loading allocation requests: $e');
    } finally {
      setState(() {
        _isLoadingMore = false;
        isLoading = false;
      });
    }
  }


  Future<void> getCurrentLeaveRequest(String recordId) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/leave/user-request/$recordId');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      setState(() {
        currentRequests = [jsonDecode(response.body)];
      });
    }
  }

  Future<void> getCurrentAllLeaveRequest(String recordId) async {
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
        currentAllRequests = [jsonDecode(response.body)];
      });
    }
  }

  Future<void> createLeaveRequest(Map<String, dynamic> createdDetails,
      checkFile, String fileName, String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var request = http.MultipartRequest(
        'POST', Uri.parse('$typedServerUrl/api/leave/allocation-request/'));
    request.fields['description'] = createdDetails['description'];
    request.fields['leave_type_id'] =
        createdDetails['leave_type_id'].toString();
    request.fields['employee_id'] = createdDetails['employee_id'].toString();
    request.fields['requested_days'] = createdDetails['requested_days'];
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
      allRequests.clear();
      myAllRequests.clear();
      currentPage = 0;
      await getMyAllocationRequest();
      await getAllocationRequest();
      setState(() {});
    } else {
      isSaveClick = true;
      var responseBody = await response.stream.bytesToString();
      var errorJson = jsonDecode(responseBody);

      setState(() {
        if (errorJson.containsKey("description")) {
          _errorMessage = errorJson["description"];
        }
        if (errorJson.containsKey("requested_days")) {
          _errorMessage = errorJson["requested_days"];
        }
        if (errorJson.containsKey("employee_id")) {
          _errorMessage = errorJson["employee_id"];
        }
        if (errorJson.containsKey("leave_type_id")) {
          _errorMessage = errorJson["leave_type_id"];
        } else {
          _errorMessage = _errorMessage = errorJson["non_field_errors"];
        }
      });
    }
  }

  Future<void> approveRequest(int approveId) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri =
    Uri.parse('$typedServerUrl/api/leave/allocation-approve/$approveId/');
    var response = await http.put(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });

    if (response.statusCode == 200) {
      setState(() {
        for (var request in allRequests) {
          if (request['id'] == approveId) {
            request['status'] = 'approved';
            break;
          }
        }
      });
    }
  }

  Future<void> deleteMyRequest(int myLeaveId) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri =
    Uri.parse('$typedServerUrl/api/leave/user-allocation-request/$myLeaveId/');
    var response = await http.delete(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      setState(() {
        isSaveClick = false;
        myAllRequests.removeWhere((item) => item['id'] == myLeaveId);
        getMyAllocationRequest();
      });
      setState(() {
        isLoading = false;
      });
    }
    else {
      isSaveClick = true;
    }
  }

  Future<void> deleteRequest(int allLeaveId) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri =
    Uri.parse('$typedServerUrl/api/leave/allocation-request/$allLeaveId/');
    var response = await http.delete(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      setState(() {
        isSaveClick = false;
        allRequests.removeWhere((item) => item['id'] == allLeaveId);
        getAllocationRequest();
      });
      setState(() {
        isLoading = false;
      });
    }
    else {
      isSaveClick = true;
    }
  }

  Future<void> rejectRequest(int rejectId, String description) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri =
    Uri.parse('$typedServerUrl/api/leave/allocation-reject/$rejectId/');
    var response = await http.put(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      setState(() {
        isSaveClick = false;
        for (var request in allRequests) {
          if (request['id'] == rejectId) {
            request['status'] = 'rejected';
            request['description'] = description;
            break;
          }
        }
      });
    }
    else {
      isSaveClick = true;
    }
  }

  Future<void> getAllPagesAllocationRequest() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");

    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse(
        '$typedServerUrl/api/leave/allocation-request?search=$searchText');
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

  List<Map<String, dynamic>> filterAllAllocationRecords(String searchText) {
    if (searchText.isEmpty) {
      return allRequests;
    } else {
      return allRequests.where((record) {
        String fullName =
        record['employee_id']['full_name'].toString().toLowerCase();
        return fullName.contains(searchText.toLowerCase());
      }).toList();
    }
  }

  List<Map<String, dynamic>> filterMyAllocationRecords(String searchText) {
    if (searchText.isEmpty) {
      return myAllRequests;
    } else {
      return myAllRequests.where((record) {
        String fullName =
        record['employee_id']['full_name'].toString().toLowerCase();
        return fullName.contains(searchText.toLowerCase());
      }).toList();
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

  Future<void> getAllEmployeesName() async {
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
        for (var rec in requestsEmployeesName) {
          var employees = rec['employee_first_name'] +
              ' ' +
              (rec['employee_last_name'] ?? '');
          employeeItems.add(employees);
        }
      });
    }
  }

  _showCreateDialog(BuildContext context) {
    TextEditingController controllerValue = TextEditingController(text: "0");
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Stack(
              children: [
                AlertDialog(
                  backgroundColor: Colors.white,
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Add Allocation',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black)),
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
                              height: MediaQuery.of(context).size.width * 0.03),
                          const Text("Leave Type"),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          TypeAheadField<String>(
                            textFieldConfiguration: TextFieldConfiguration(
                              controller: _typeAheadAddController,
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
                                _typeAheadAddController.text = suggestion;
                                editLeaveType = suggestion;
                                selectedLeaveId = int.tryParse(
                                    leaveItemsIdMap[suggestion] ?? '');
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
                            child: Text("Employee"),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          TypeAheadField<String>(
                            textFieldConfiguration: TextFieldConfiguration(
                              controller: _typeAddEmployeeController,
                              decoration: InputDecoration(
                                labelText: 'Search Employee',
                                labelStyle: TextStyle(color: Colors.grey[350]),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10.0),
                                border: const OutlineInputBorder(),
                                errorText: _validateEmployee
                                    ? 'Please Select an Employee'
                                    : null,
                              ),
                            ),
                            suggestionsCallback: (pattern) {
                              return employeeItem
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
                                selectedEmployee = suggestion;
                                selectedEmployeeId = employeeIdMap[suggestion];
                                _validateEmployee = false;
                              });
                              _typeAddEmployeeController.text = suggestion;
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
                            "Requested Days",
                            style: TextStyle(color: Colors.black),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          TextField(
                            controller: controllerValue,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10.0, horizontal: 10.0),
                              labelText: 'Requested Days',
                              labelStyle: TextStyle(color: Colors.grey[350]),
                              errorText: _validateDays
                                  ? 'Please enter Requested Days'
                                  : null,
                              suffixIcon: IntrinsicHeight(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      height: 24.0,
                                      width: 24.0,
                                      child: IconButton(
                                        padding: const EdgeInsets.all(0),
                                        icon: const Icon(Icons.arrow_drop_up,
                                            size: 16.0),
                                        onPressed: () {
                                          int currentValue =
                                          int.parse(controllerValue.text);
                                          setState(() {
                                            controllerValue.text =
                                                (currentValue + 1).toString();
                                          });
                                        },
                                      ),
                                    ),
                                    SizedBox(
                                      height: 24.0,
                                      width: 24.0,
                                      child: IconButton(
                                        padding: const EdgeInsets.all(0),
                                        icon: const Icon(Icons.arrow_drop_down,
                                            size: 16.0),
                                        onPressed: () {
                                          int currentValue =
                                          int.parse(controllerValue.text);
                                          setState(() {
                                            controllerValue.text =
                                                (currentValue > 0
                                                    ? currentValue - 1
                                                    : 0)
                                                    .toString();
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.03),
                          const Text("Description"),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          TextField(
                            controller: allocationDescription,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: "Description",
                              labelStyle: TextStyle(color: Colors.grey[350]),
                              contentPadding:
                              const EdgeInsets.symmetric(horizontal: 10.0),
                              errorText: _validateAllocateDescriptions
                                  ? 'Description cannot be empty'
                                  : null,
                            ),
                            onChanged: (newValue) {
                              allocationDescription.text = newValue;
                              _validateAllocateDescriptions = false;
                            },
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.03),
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
                              errorText: _validateAttachment
                                  ? 'Attachment is not given'
                                  : null,
                              suffixIcon: _fileNameController.text.isNotEmpty
                                  ? IconButton(
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
                            onChanged: (newValue) {
                              setState(() {
                                _validateAttachment = newValue.isEmpty;
                              });
                            },
                          ),
                        ],
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
                            setState(() {
                              _validateLeaveType = false;
                              _validateEmployee = false;
                              _validateDays = false;
                              _validateAllocateDescriptions = false;
                            });

                            if (_typeAheadAddController.text.isEmpty) {
                              setState(() {
                                isSaveClick = true;
                                _validateLeaveType = true;
                                _validateEmployee = false;
                                _validateDays = false;
                                _validateAllocateDescriptions = false;
                                Navigator.of(context).pop();
                                _showCreateDialog(context);
                              });
                            } else if (_typeAddEmployeeController
                                .text.isEmpty) {
                              setState(() {
                                isSaveClick = true;
                                _validateEmployee = true;
                                _validateLeaveType = false;
                                _validateDays = false;
                                _validateAllocateDescriptions = false;
                                Navigator.of(context).pop();
                                _showCreateDialog(context);
                              });
                            } else if (controllerValue.text.isEmpty) {
                              setState(() {
                                isSaveClick = true;
                                _validateDays = true;
                                _validateEmployee = false;
                                _validateLeaveType = false;
                                _validateAllocateDescriptions = false;
                                Navigator.of(context).pop();
                                _showCreateDialog(context);
                              });
                            } else if (allocationDescription.text.isEmpty) {
                              setState(() {
                                isSaveClick = true;
                                _validateAllocateDescriptions = true;
                                _validateEmployee = false;
                                _validateLeaveType = false;
                                Navigator.of(context).pop();
                                _showCreateDialog(context);
                              });
                            } else {
                              setState(() {
                                _validateAllocateDescriptions = false;
                                _errorMessage = null;
                                isAction = true;
                              });
                              Map<String, dynamic> createdDetails = {
                                'leave_type_id': selectedLeaveId,
                                'employee_id': selectedEmployeeId,
                                'requested_days': controllerValue.text,
                                'description': allocationDescription.text,
                              };
                              await createLeaveRequest(createdDetails,
                                  checkFile, fileName, filePath);
                              setState(() {
                                isAction = false;
                              });
                              if (_errorMessage == null ||
                                  _errorMessage!.isEmpty) {
                                Navigator.of(context).pop(true);
                                showCreateAnimation();
                              } else {
                                Navigator.of(context).pop();
                                _showCreateDialog(context);
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
                        child: const Text(
                          "Save",
                          style: TextStyle(color: Colors.white),
                        ),
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
    List<Widget> tabs = [];
    if (allocationCheck) {
      tabs = [
        Tab(text: 'Leave allocation request(${allRequests.length})'),
        Tab(text: 'My leave allocation(${myAllRequests.length})'),
      ];
    } else {
      tabs = [
        Tab(text: 'My leave allocation(${myAllRequests.length})'),
      ];
    }
    if (!allocationCheck) {
      _tabController.index = 0;
    }
    return DefaultTabController(
      length: tabs.length,
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
          title: const Row(
            children: [
              Text(
                'Allocation',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    isSaveClick = true;
                    _validateLeaveType = false;
                    _validateAllocateDescriptions = false;
                    _validateDays = false;
                    _validateDescription = false;
                    _validateEmployee = false;
                    isAction = false;

                    _fileNameController.clear();
                    _errorMessage = null;
                    selectedLeaveId = null;
                    selectedEmployee = null;
                    _typeAddEmployeeController.clear();
                    _typeAheadAddController.clear();
                    _controllerValue.clear();
                    allocationDescription.clear();
                  });
                  _showCreateDialog(context);
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(75, 50),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  side: const BorderSide(color: Colors.red),
                ),
                child:
                const Text('CREATE', style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ),
        body: _isShimmerVisible
            ? _buildLoadingWidget()
            : _buildAllocationRequestWidget(),
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
    List<Widget> tabs = [];
    List<Widget> tabViews = [];
    if (allocationCheck) {
      tabs = [
        Tab(text: 'Leave allocation request(${allRequests.length})'),
        Tab(text: 'My leave allocation(${myAllRequests.length})'),
      ];
      tabViews = [
        buildTabContent(allRequests),
        buildTabContents(myAllRequests),
      ];
    } else {
      tabs = [
        Tab(text: 'My leave allocation(${myAllRequests.length})'),
      ];
      tabViews = [
        buildTabContents(myAllRequests),
      ];
    }
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
          tabs: tabs,
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.03),
        Expanded(
          child: TabBarView(
            children: tabViews,
          ),
        ),
      ],
    );
  }

  Widget _buildAllocationRequestWidget() {
    List<Widget> tabs = [];
    List<Widget> tabViews = [];

    if (allocationCheck) {
      tabs = [
        Tab(text: 'Leave allocation request($leaveAllocationRequestCount)'),
        Tab(text: 'My leave allocation($myLeaveAllocationCount)'),
      ];
      tabViews = [
        leaveAllocationRequestCount == 0
            ? ListView(
          children: const [
            Padding(
              padding: EdgeInsets.only(top: 40.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_clock,
                      color: Colors.black,
                      size: 92,
                    ),
                    SizedBox(height: 20),
                    Text(
                      "There are no records to display",
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
            : buildTabContent(allRequests),
        myLeaveAllocationCount == 0
            ? ListView(
          children: const [
            Padding(
              padding: EdgeInsets.only(top: 40.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_clock,
                      color: Colors.black,
                      size: 92,
                    ),
                    SizedBox(height: 20),
                    Text(
                      "There are no records to display",
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
            : buildTabContents(myAllRequests),
      ];
    } else {
      tabs = [
        Tab(text: 'My leave allocation(${myAllRequests.length})'),
      ];
      tabViews = [
        myLeaveAllocationCount == 0
            ? ListView(
          children: const [
            Padding(
              padding: EdgeInsets.only(top: 40.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_clock,
                      color: Colors.black,
                      size: 92,
                    ),
                    SizedBox(height: 20),
                    Text(
                      "There are no records to display",
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
            : buildTabContents(myAllRequests),      ];
    }
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
                          border: Border.all(color: Colors.grey.shade50),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextField(
                          onChanged: (value) {
                            setState(() {
                              searchText = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: Transform.scale(
                              scale: 0.8,
                              child: Icon(Icons.search, color: Colors.blueGrey.shade300),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 12.0, horizontal: 4.0),
                            hintStyle: TextStyle(
                                color: Colors.blueGrey.shade300, fontSize: 14),
                            filled: true,
                            fillColor: Colors.grey[100],
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
              indicatorColor: Colors.red,
              unselectedLabelColor: Colors.grey,
              isScrollable: true,
              tabs: tabs,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
            Expanded(
              child: TabBarView(
                children: tabViews,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildTabContents(List<Map<String, dynamic>> myAllRequests) {
    final displayedRecords = searchText.isEmpty
        ? myAllRequests
        : _filterRecords(myAllRequests, searchText);

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: displayedRecords.length + (_hasMoreMyRequests ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= displayedRecords.length) {
                return _buildLoader();
              }

              final record = displayedRecords[index];
              final fullName = record['employee_id']['full_name'];
              final profile = record['employee_id']['employee_profile'];
              final stateInfo = _getStateInfo(record['status']);

              return buildMyLeaveTiles(
                  record, fullName, baseUrl, getToken, profile ?? "", stateInfo);
            },
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _filterRecords(List<Map<String, dynamic>> records, String query) {
    if (query.isEmpty) return records;

    return records.where((record) {
      final employeeName = record['employee_id']['full_name']?.toString().toLowerCase() ?? '';
      final leaveType = record['leave_type_id']['name']?.toString().toLowerCase() ?? '';
      final status = record['status']?.toString().toLowerCase() ?? '';
      final requestedDays = record['requested_days']?.toString().toLowerCase() ?? '';

      return employeeName.contains(query.toLowerCase()) ||
          leaveType.contains(query.toLowerCase()) ||
          status.contains(query.toLowerCase()) ||
          requestedDays.contains(query.toLowerCase());
    }).toList();
  }

  Widget buildMyLeaveTiles(Map<String, dynamic> record, fullName, baseUrl,token,
      String profile, stateInfo) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
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
                                                  color: Colors.grey);
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
                                      record['employee_id']['badge_id'] != null
                                          ? '${record['employee_id']['badge_id']}'
                                          : '',
                                      style: const TextStyle(
                                          fontSize: 12.0,
                                          fontWeight: FontWeight.normal),
                                    ),
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
                                        _getStateInfo(record['status'])
                                            .displayString,
                                        style: TextStyle(
                                          color:
                                          _getStateInfo(record['status']).color,
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Requested days',
                                style: TextStyle(color: grey700),
                              ),
                              Text('${record['requested_days'] ?? "None"}'),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Leave Type',
                                style: TextStyle(color: grey700),
                              ),
                              Text('${record['leave_type_id']['name'] ?? "None"}'),
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
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: Text(record['description'] ?? "None"),
                                ),
                              ),
                            ],
                          ),
                          if (record['attachment'] != null)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Attachment:',
                                  style: TextStyle(color: grey700),
                                ),
                                TextButton(
                                  onPressed: () {
                                    String pdfPath = baseUrl + record['attachment'];
                                    if (pdfPath.endsWith('.png') ||
                                        pdfPath.endsWith('.jpg') ||
                                        pdfPath.endsWith('.jpeg') ||
                                        pdfPath.endsWith('.gif')) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ImageViewer(
                                            imagePath: pdfPath,
                                            token: getToken,
                                          ),
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
                        ],
                      ),
                    ),
                  ),
                );
              }
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
                                          color: Colors.grey);
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
                              maxLines: 2,
                            ),
                            Text(
                              record['employee_id']['badge_id'] != null
                                  ? '${record['employee_id']['badge_id']}'
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
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(15.0),
                                bottomLeft: Radius.circular(15.0),
                              ),
                              color: Colors.blue[100],
                            ),
                            child: Visibility(
                              visible: record['status'] == 'requested',
                              child: IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  size: 18.0,
                                  color: Colors.blue,
                                ),
                                onPressed: () {
                                  isSaveClick = true;
                                  description.text =
                                      record['description'] ?? '';
                                  leaveItems.clear();
                                  employeeItems.clear();
                                  getAllEmployeesName();
                                  getEmployees();
                                  getAllLeaveTypeName();
                                  _showMyUpdateDialog(context, record);
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
                                                  var myLeaveId = record['id'];
                                                  await deleteMyRequest(
                                                      myLeaveId);
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
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Requested Days',
                          style: TextStyle(color: grey700)),
                      Text('${record['requested_days']}'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Leave Type',
                          style: TextStyle(color: grey700)),
                      Text('${record['leave_type_id']['name']}'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Status',
                          style: TextStyle(color: grey700)),
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
                          _getStateInfo(record['status']).displayString,
                          style: TextStyle(
                            color: _getStateInfo(record['status']).color,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
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


  Widget buildTabContent(List<Map<String, dynamic>> allRequests) {
    final displayedRecords = searchText.isEmpty
        ? allRequests
        : _filterRecords(allRequests, searchText);

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: displayedRecords.length + (_hasMoreAllRequests ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= displayedRecords.length) {
                return _buildLoader();
              }

              final record = displayedRecords[index];
              final fullName = record['employee_id']['full_name'];
              final profile = record['employee_id']['employee_profile'];
              final stateInfo = _getStateInfo(record['status']);
              final recordId = record['id'].toString();

              return buildAllLeaveTile(record, fullName, baseUrl,getToken,
                  profile ?? "", stateInfo, recordId);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoader() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget buildAllLeaveTile(Map<String, dynamic> record, fullName, baseUrl,token,
      String profile, stateInfo, String recordId) {
    return GestureDetector(
      onTap: () async {
        await getCurrentAllLeaveRequest(recordId);
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
                                              color: Colors.grey);
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
                                  record['employee_id']['badge_id'] != null
                                      ? '${record['employee_id']['badge_id']}'
                                      : '',
                                  style: const TextStyle(
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.normal),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5.0, vertical: 2.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(9.0),
                                    color: _getStateInfo(record['status'])
                                        .color
                                        .withOpacity(0.1),
                                  ),
                                  child: Text(
                                    _getStateInfo(record['status'])
                                        .displayString,
                                    style: TextStyle(
                                      color:
                                      _getStateInfo(record['status']).color,
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
                          height: MediaQuery.of(context).size.height * 0.01),
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
                            'Requested days',
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
                              border: Border.all(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: Text(
                                '${record['description']}',
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (record['attachment'] != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Attachment:',
                              style: TextStyle(color: grey700),
                            ),
                            TextButton(
                              onPressed: () {
                                String pdfPath = baseUrl + record['attachment'];
                                if (pdfPath.endsWith('.png') ||
                                    pdfPath.endsWith('.jpg') ||
                                    pdfPath.endsWith('.jpeg') ||
                                    pdfPath.endsWith('.gif')) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ImageViewer(
                                        imagePath: pdfPath,
                                        token: getToken,
                                      ),
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
                            visible: record['status'] != 'rejected',
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.3,
                              child: ElevatedButton(
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
                                          height: MediaQuery.of(context)
                                              .size
                                              .height *
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
                                                  var rejectId = record['id'];
                                                  var description =
                                                      rejectDescription.text;
                                                  await rejectRequest(
                                                      rejectId, description);
                                                  Navigator.pop(context);
                                                  Navigator.pop(context);
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
                                  backgroundColor: Colors.red,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                                child: const Text(
                                  'Reject',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: record['status'] != 'rejected',
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.3,
                              child: ElevatedButton(
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
                                          height: MediaQuery.of(context)
                                              .size
                                              .height *
                                              0.1,
                                          child: const Center(
                                            child: Text(
                                              "Are you sure you want to Approve this request?",
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
                                                var approveId = record['id'];
                                                await approveRequest(approveId);
                                                Navigator.pop(context);
                                                Navigator.pop(context);
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
                                  backgroundColor:
                                  record['status'] == 'approved' ||
                                      record['status'] == 'requested'
                                      ? Colors.green[400]
                                      : Colors.green,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                                child: const Text(
                                  'Approve',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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
                                          color: Colors.grey);
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
                              maxLines: 2,
                            ),
                            Text(
                              record['employee_id']['badge_id'] != null
                                  ? '${record['employee_id']['badge_id']}'
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
                          if (record['status'] == 'requested')
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(15.0),
                                  bottomLeft: Radius.circular(15.0),
                                ),
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
                                      _errorMessage = null;
                                      isAction = false;
                                      leaveDescription.clear();
                                      _controllerValue.clear();
                                      _fileNameController.clear();
                                    });
                                    getAllEmployeesName();
                                    getEmployees();
                                    getAllLeaveTypeName();
                                    _showUpdateDialog(context, record);
                                  },
                                ),
                              ),
                            ),
                          if (record['status'] == 'requested')
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
                                                    var allLeaveId = record['id'];
                                                    await deleteRequest(
                                                        allLeaveId);
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
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Requested Days',
                          style: TextStyle(color: grey700)),
                      Text('${record['requested_days']}'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Leave Type',
                          style: TextStyle(color: grey700)),
                      Text('${record['leave_type_id']['name']}'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Status',
                          style: TextStyle(color: grey700)),
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
                          _getStateInfo(record['status']).displayString,
                          style: TextStyle(
                            color: _getStateInfo(record['status']).color,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Visibility(
                        visible: record['status'] != 'rejected',
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.4,
                          child: ElevatedButton(
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
                            ),
                            child: const Text(
                              'Reject',
                              style:
                              TextStyle(fontSize: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: record['status'] != 'rejected',
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.4,
                          child: ElevatedButton(
                            onPressed: record['status'] != 'requested'
                                ? null
                                : () {
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
                                          "Are you sure you want to Approve this request?",
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
                                            var approveId = record['id'];
                                            await approveRequest(
                                                approveId);
                                            Navigator.pop(context);
                                            showApproveAnimation();
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
                              backgroundColor: record['status'] == 'approved' ||
                                  record['status'] == 'requested'
                                  ? Colors.green[400]
                                  : Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: const Text(
                              'Approve',
                              style:
                              TextStyle(fontSize: 14, color: Colors.white),
                            ),
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
      appBar: AppBar(
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
