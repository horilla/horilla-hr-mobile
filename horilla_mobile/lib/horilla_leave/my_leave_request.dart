import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:intl/intl.dart';
import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'dart:io';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:shimmer/shimmer.dart';
import '../../res/consts/app_colors.dart';

class MyLeaveRequest extends StatefulWidget {
  const MyLeaveRequest({super.key});

  @override
  _MyLeaveRequest createState() => _MyLeaveRequest();
}

class _MyLeaveRequest extends State<MyLeaveRequest>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _controller = NotchBottomBarController(index: -1);
  final TextEditingController _typeAheadEditController =
  TextEditingController();
  final List<Widget> bottomBarPages = [];
  Map<String, String> leaveItemsIdMap = {};
  Map<String, dynamic> breakdownMaps = {
    'full_day': 'Full Day',
    'second_half': 'Second Half',
    'first_half': 'First Half',
  };
  var leaveItems = [''];
  var startBreakdown = [''];
  late TabController _tabController;
  late String baseUrl = '';
  late Map<String, dynamic> arguments;
  XFile? pickedFile;
  String fileName = '';
  String filePath = '';
  bool isLoading = true;
  bool permissionLeaveTypeCheck = false;
  bool permissionAllocationCheck = false;
  bool permissionLeaveAssignCheck = false;
  bool permissionLeaveRequestCheck = false;
  bool permissionLeaveOverviewCheck = false;
  bool permissionMyLeaveRequestCheck = false;
  bool permissionLeaveAllocationCheck = false;
  bool _isShimmer = true;
  bool checkfile = false;
  bool dateCheckError = false;
  bool dateBreakDownError = false;
  bool insufficientDaysError = false;
  bool enoughDays = false;
  bool _validateLeaveType = false;
  bool dateCheck = false;
  bool dateBreakDown = false;
  bool _validateDate = false;
  bool _validateStartDateBreakdown = false;
  bool _validateEndDateBreakdown = false;
  bool _validateDescription = false;
  bool _validateAttachment = false;
  bool _validateEndDate = false;
  bool userCheck = false;
  bool allocationCheck = false;
  DateTime? startDate;
  DateTime? endDate;
  String employeeId = '';
  bool isAction = true;
  bool isSaveClick = true;
  int currentPage = 1;
  int allMyRequestsCount = 0;
  int requestedCount = 0;
  int approvedCount = 0;
  int cancelledCount = 0;
  int rejectedCount = 0;
  int? difference;
  int? available;
  int maxCount = 5;
  bool isFetching = false;
  bool hasMore = true;
  late String getToken = '';


  String _getBreakdown(String breakdownValue) {
    final breakdownMap = {
      'full_day': 'Full Day',
      'second_half': 'Second Half',
      'first_half': 'First Half',
    };
    return breakdownMap[breakdownValue] ?? 'Unknown';
  }

  String encodeFile(File file) {
    List<int> fileBytes = file.readAsBytesSync();
    String encodedFile = base64Encode(fileBytes);
    return encodedFile;
  }

  String selectedEndDateValue = '';
  String employeeName = '';
  String? _errorMessage;
  String? selectedLeaveType;
  String? editleaveType;
  String? editEndDateBreakdown;
  String? editStartDateBreakdown;
  String selectedStartDateValue = '';
  String? selectedFilePath;
  String? selectedLeaveId;
  List<Map<String, dynamic>> requestsEmployeesName = [];
  List<Map<String, dynamic>> myRequests = [];
  List<Map<String, dynamic>> myAllRequests = [];
  List<Map<String, dynamic>> currentRequests = [];
  List<Map<String, dynamic>> userRequests = [];
  List<Map<String, dynamic>> leaveType = [];
  List<Map<String, dynamic>> cancelLeaveType = [];
  List<Map<String, dynamic>> deletedLeaveType = [];
  List<dynamic> leaveResults = [];
  List<dynamic> leaveTypes = [];
  List<String> leaveItem = [];
  List<int> leaveIDs = [];
  TextEditingController startDateInput = TextEditingController();
  TextEditingController endDateInput = TextEditingController();
  TextEditingController descriptions = TextEditingController();
  TextEditingController leaveDescription = TextEditingController();
  TextEditingController descriptionLeaveType = TextEditingController();
  TextEditingController startDateSelect = TextEditingController();
  TextEditingController descriptionSelect = TextEditingController();
  TextEditingController endDateSelect = TextEditingController();
  final TextEditingController _fileNameController = TextEditingController();


  @override
  void initState() {
    super.initState();
    currentPage = 1;
    getMyAllLeaveRequestFirstPage();
    _scrollController.addListener(_scrollListener);
    startDateSelect.text = "Select Start Date";
    endDateSelect.text = "Select End Date";
    _tabController = TabController(length: 5, vsync: this);
    startBreakdown.clear();
    getMyLeaveRequest();
    getRequestedCount();
    _simulateLoading();
    getApprovedCount();
    getCancelledCount();
    getRejectedCount();
    getLeaveDetails();
    getMyAllLeaveRequest();
    getLeaveTypes();
    getUserLeaveRequest();
    getCurrentEmployeeDetails();
    getBaseUrl();
    fetchToken();
    checkUserType();
    prefetchData();
  }

  Future<void> checkPermissions() async {
    await permissionLeaveOverviewChecks();
    await permissionLeaveTypeChecks();
    await permissionLeaveRequestChecks();
    await permissionLeaveAssignChecks();
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

  void prefetchData() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerurl = prefs.getString("typed_url");
    var employeeId = prefs.getInt("employee_id");
    var uri = Uri.parse('$typedServerurl/api/employee/employees/$employeeId');
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
    super.dispose();
  }

  Future<void> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    var typedServerUrl = prefs.getString("typed_url");
    setState(() {
      baseUrl = typedServerUrl ?? '';
    });
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200 &&
        !isFetching &&
        hasMore) {
      currentPage++;
      getMyAllLeaveRequestNextPage();
    }
  }

  Future<void> getMyAllLeaveRequestNextPage() async {
    await _fetchLeavePage(currentPage, reset: false);
  }

  Future<void> _fetchLeavePage(int page, {required bool reset}) async {
    if (isFetching) return;
    isFetching = true;

    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");

    final uri = Uri.parse(
        '$typedServerUrl/api/leave/user-request?employee_id=$employeeId&page=$page');

    final response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<dynamic> newResults = List.from(data['results'] ?? []);
      int totalCount = data['count'] ?? 0;

      setState(() {
        if (reset) {
          myAllRequests = (jsonDecode(response.body)['results'] as List)
              .map((e) => e as Map<String, dynamic>)
              .toList();
        } else {
          myAllRequests.addAll(
            (jsonDecode(response.body)['results'] as List)
                .map((e) => e as Map<String, dynamic>)
                .toList(),
          );
        }
        allMyRequestsCount = totalCount;

        if (myAllRequests.length >= totalCount) {
          hasMore = false;
        }
      });
    } else {
      hasMore = false;
    }

    isFetching = false;
  }

  Future<void> getMyAllLeaveRequestFirstPage() async {
    setState(() {
      isLoading = true;
      myAllRequests.clear();
      hasMore = true;
      currentPage = 1;
    });
    await _fetchLeavePage(currentPage, reset: true);
    setState(() {
      isLoading = false;
    });
  }

  Future<void> getCurrentEmployeeDetails() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerurl = prefs.getString("typed_url");
    var employeeID = prefs.getInt("employee_id");
    var uri = Uri.parse('$typedServerurl/api/employee/employees/$employeeID');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      setState(() {
        var employeeData = jsonDecode(response.body);
        employeeName = employeeData['employee_first_name'] +
            ' ' +
            (employeeData['employee_last_name'] ?? '');
      });
    }
  }

  Future<void> checkUserType() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/leave/check-type');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      setState(() {
        userCheck = true;
      });
    } else {
      setState(() {
        userCheck = false;
      });
    }
  }

  void setFileName() {
    setState(() {
      _fileNameController.text = fileName;
    });
  }

  Future<void> getAllLeaveTypeName() async {
    ///Fetch all leave types and show my leave availability
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var employeeID = prefs.getInt("employeeID");
    var uri =
    Uri.parse('$typedServerUrl/api/leave/employee-leave-type/$employeeID/');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      setState(() {
        leaveType = List<Map<String, dynamic>>.from(
          jsonDecode(response.body)['results'],
        );
        for (var leaveName in leaveType) {
          leaveItems.add(leaveName['name']);
        }
      });
    }
  }

  _showCreateSelectedDialog(BuildContext context, Map<String, dynamic> record) {
    String leaveTypeName = record['leave_type_id']['name'];
    int leaveTypeId = record['leave_type_id']['id'];
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            _fileNameController.addListener(() {
              setState(() {});
            });
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
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          Navigator.of(context).pop();
                          startDate = null;
                          endDate = null;
                          _validateDate = true;
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
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.03),
                          const Text(
                            "Leave Type",
                            style: TextStyle(color: Colors.black),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          DropdownButtonFormField<int>(
                            style: const TextStyle(
                              fontWeight: FontWeight.normal,
                              color: Colors.black,
                            ),
                            value: leaveTypeId,
                            items: [
                              DropdownMenuItem<int>(
                                value: leaveTypeId,
                                child: Text(leaveTypeName),
                              ),
                            ],
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding:
                              EdgeInsets.symmetric(horizontal: 10.0),
                            ),
                            onChanged: (int? newValue) {
                              setState(() {
                                leaveTypeId = newValue!;
                              });
                            },
                            disabledHint: const Text('Leave type pre-filled'),
                            isExpanded: true,
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.03),
                          const Text("Start Date",
                              style: TextStyle(color: Colors.black)),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          TextField(
                            readOnly: true,
                            controller: startDateSelect,
                            onTap: () async {
                              final selectedDate = await showCustomDatePicker(
                                  context, DateTime.now());
                              if (selectedDate != null) {
                                DateTime parsedDate = DateFormat('yyyy-MM-dd')
                                    .parse(selectedDate);
                                setState(() {
                                  startDate = parsedDate;
                                  startDateSelect.text =
                                      DateFormat('yyyy-MM-dd')
                                          .format(startDate!);
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
                              height:
                              MediaQuery.of(context).size.height * 0.03),
                          const Text("Start Date Breakdown",
                              style: TextStyle(color: Colors.black)),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: DropdownSearch<String>(
                              items:
                              breakdownMaps.values.toList().cast<String>(),
                              selectedItem: editStartDateBreakdown,
                              onChanged: (newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    editStartDateBreakdown = newValue;
                                    selectedStartDateValue = breakdownMaps
                                        .entries
                                        .firstWhere(
                                            (entry) => entry.value == newValue)
                                        .key;
                                    _validateStartDateBreakdown = false;
                                  });
                                }
                              },
                              dropdownDecoratorProps: DropDownDecoratorProps(
                                dropdownSearchDecoration: InputDecoration(
                                  errorText: _validateStartDateBreakdown
                                      ? 'Please select a Start Date Breakdown'
                                      : null,
                                  border: const OutlineInputBorder(),
                                  labelText: "Start Date Breakdown",
                                  labelStyle:
                                  TextStyle(color: Colors.grey[350]),
                                  contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 10.0),
                                ),
                              ),
                              popupProps: PopupProps.menu(
                                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.23), // Set your desired height
                                showSearchBox: false,
                              ),
                            ),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.03),
                          const Text("End Date",
                              style: TextStyle(color: Colors.black)),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          TextField(
                            readOnly: true,
                            controller: endDateSelect,
                            onTap: () async {
                              final selectedDate = await showCustomDatePicker(
                                  context, DateTime.now());
                              if (selectedDate != null) {
                                DateTime parsedDate = DateFormat('yyyy-MM-dd')
                                    .parse(selectedDate);
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
                              height:
                              MediaQuery.of(context).size.height * 0.03),
                          const Text("End Date Breakdown",
                              style: TextStyle(color: Colors.black)),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: DropdownSearch<String>(
                              items:
                              breakdownMaps.values.toList().cast<String>(),
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
                                  labelStyle:
                                  TextStyle(color: Colors.grey[350]),
                                  contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 10.0),
                                ),
                              ),
                              popupProps: PopupProps.menu(
                                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.23), // Set your desired height
                                showSearchBox: false,
                              ),
                            ),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.03),
                          const Text("Description",
                              style: TextStyle(color: Colors.black)),
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
                              setState(() {
                                _validateDescription = newValue.isEmpty;
                              });
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
                                  checkfile = true;
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
                                icon:
                                const Icon(Icons.close, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _fileNameController.clear();
                                  });
                                },
                              )
                                  : null,
                            ),
                            onChanged: (newValue) {
                              setState(() {});
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
                            if (startDate == null) {
                              setState(() {
                                isSaveClick = true;
                                _validateDate = true;
                                _validateStartDateBreakdown = false;
                                _validateEndDateBreakdown = false;
                                _validateEndDate = false;
                                _validateDescription = false;
                              });
                            } else if (editStartDateBreakdown == null) {
                              setState(() {
                                isSaveClick = true;
                                _validateStartDateBreakdown = true;
                                _validateEndDateBreakdown = false;
                                _validateDate = false;
                                _validateEndDate = false;
                                _validateDescription = false;
                              });
                            } else if (endDate == null) {
                              setState(() {
                                isSaveClick = true;
                                _validateEndDate = true;
                                _validateStartDateBreakdown = false;
                                _validateEndDateBreakdown = false;
                                _validateDate = false;
                                _validateDescription = false;
                              });
                            } else if (editEndDateBreakdown == null) {
                              setState(() {
                                isSaveClick = true;
                                _validateEndDateBreakdown = true;
                                _validateStartDateBreakdown = false;
                                _validateEndDate = false;
                                _validateDate = false;
                                _validateDescription = false;
                              });
                            } else if (descriptionSelect.text.isEmpty) {
                              setState(() {
                                isSaveClick = true;
                                _validateDescription = true;
                                _validateEndDateBreakdown = false;
                                _validateStartDateBreakdown = false;
                                _validateEndDate = false;
                                _validateDate = false;
                              });
                            } else {
                              setState(() {
                                _validateDescription = false;
                                _validateStartDateBreakdown = false;
                                _validateDate = false;
                                _validateEndDate = false;
                                _validateDescription = false;
                                isAction = true;
                              });
                              Map<String, dynamic> createdDetails = {
                                "leave_type_id": leaveTypeId,
                                'leave_type': leaveTypeName,
                                'start_date': startDateSelect.text,
                                'start_date_breakdown': selectedStartDateValue,
                                'end_date': endDateSelect.text,
                                'end_date_breakdown': selectedEndDateValue,
                                'description': descriptionSelect.text,
                              };
                              await createNewLeaveType(createdDetails,
                                  checkfile, fileName, filePath);
                              setState(() {
                                isAction = false;
                              });
                              if (_errorMessage == null) {
                                Navigator.of(context).pop(true);
                                showCreateAnimation();
                              } else {
                                Navigator.of(context).pop(true);
                                _showCreateSelectedDialog(context, record);
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
                        child:
                        const Text('Save', style: TextStyle(color: Colors.white)),
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

  _showCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            _fileNameController.addListener(() {
              setState(() {});
            });

            return Stack(
              children: [
                AlertDialog(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Add Leave",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
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
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.03),
                          const Text("Leave Type",
                              style: TextStyle(color: Colors.black)),
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
                                editleaveType = suggestion;
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
                                  maxHeight: MediaQuery.of(context).size.height * 0.23), // Limit height
                            ),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.03),
                          const Text("Start Date",
                              style: TextStyle(color: Colors.black)),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          TextField(
                            readOnly: true,
                            controller: startDateSelect,
                            onTap: () async {
                              final selectedDate = await showCustomDatePicker(
                                  context, DateTime.now());
                              if (selectedDate != null) {
                                DateTime parsedDate = DateFormat('yyyy-MM-dd')
                                    .parse(selectedDate);
                                setState(() {
                                  startDate = parsedDate;
                                  startDateSelect.text =
                                      DateFormat('yyyy-MM-dd')
                                          .format(startDate!);
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
                              height:
                              MediaQuery.of(context).size.height * 0.03),
                          const Text("Start Date Breakdown",
                              style: TextStyle(color: Colors.black)),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: DropdownSearch<String>(
                              items:
                              breakdownMaps.values.toList().cast<String>(),
                              selectedItem: editStartDateBreakdown,
                              onChanged: (newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    editStartDateBreakdown = newValue;
                                    selectedStartDateValue = breakdownMaps
                                        .entries
                                        .firstWhere(
                                            (entry) => entry.value == newValue)
                                        .key;
                                    _validateStartDateBreakdown = false;
                                  });
                                }
                              },
                              dropdownDecoratorProps: DropDownDecoratorProps(
                                dropdownSearchDecoration: InputDecoration(
                                  errorText: _validateStartDateBreakdown
                                      ? 'Please select a Start Date Breakdown'
                                      : null,
                                  border: const OutlineInputBorder(),
                                  labelText: "Start Date Breakdown",
                                  labelStyle:
                                  TextStyle(color: Colors.grey[350]),
                                  contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 10.0),
                                ),
                              ),
                              popupProps: PopupProps.menu(
                                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.23), // Set your desired height
                                showSearchBox: false,
                              ),
                            ),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.03),
                          const Text("End Date",
                              style: TextStyle(color: Colors.black)),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          TextField(
                            readOnly: true,
                            controller: endDateSelect,
                            onTap: () async {
                              final selectedDate = await showCustomDatePicker(
                                  context, DateTime.now());
                              if (selectedDate != null) {
                                DateTime parsedDate = DateFormat('yyyy-MM-dd')
                                    .parse(selectedDate);
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
                              height:
                              MediaQuery.of(context).size.height * 0.03),
                          const Text("End Date Breakdown",
                              style: TextStyle(color: Colors.black)),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: DropdownSearch<String>(
                              items:
                              breakdownMaps.values.toList().cast<String>(),
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
                                  labelStyle:
                                  TextStyle(color: Colors.grey[350]),
                                  contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 10.0),
                                ),
                              ),
                              popupProps: PopupProps.menu(
                                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.23), // Set your desired height
                                showSearchBox: false,
                              ),
                            ),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.03),
                          const Text("Description",
                              style: TextStyle(color: Colors.black)),
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
                              setState(() {
                                _validateDescription = newValue.isEmpty;
                              });
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
                                  checkfile = true;
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
                                icon:
                                const Icon(Icons.close, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _fileNameController.clear();
                                  });
                                },
                              )
                                  : null,
                            ),
                            onChanged: (newValue) {
                              setState(() {});
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
                            if (selectedLeaveId == null) {
                              setState(() {
                                isSaveClick = true;
                                _validateLeaveType = true;
                                _validateDate = false;
                                _validateStartDateBreakdown = false;
                                _validateEndDateBreakdown = false;
                                _validateEndDate = false;
                                _validateDescription = false;
                              });
                            } else if (startDate == null) {
                              setState(() {
                                isSaveClick = true;
                                _validateDate = true;
                                _validateLeaveType = false;
                                _validateStartDateBreakdown = false;
                                _validateEndDateBreakdown = false;
                                _validateEndDate = false;
                                _validateDescription = false;
                              });
                            } else if (editStartDateBreakdown == null) {
                              setState(() {
                                isSaveClick = true;
                                _validateStartDateBreakdown = true;
                                _validateEndDateBreakdown = false;
                                _validateLeaveType = false;
                                _validateDate = false;
                                _validateEndDateBreakdown = false;
                                _validateEndDate = false;
                                _validateDescription = false;
                              });
                            } else if (endDate == null) {
                              setState(() {
                                isSaveClick = true;
                                _validateEndDate = true;
                                _validateStartDateBreakdown = false;
                                _validateEndDateBreakdown = false;
                                _validateLeaveType = false;
                                _validateDate = false;
                                _validateEndDateBreakdown = false;
                                _validateDescription = false;
                              });
                            } else if (editEndDateBreakdown == null) {
                              setState(() {
                                isSaveClick = true;
                                _validateEndDateBreakdown = true;
                                _validateStartDateBreakdown = false;
                                _validateEndDate = false;
                                _validateLeaveType = false;
                                _validateDate = false;
                                _validateDescription = false;
                              });
                            } else if (descriptionSelect.text.isEmpty) {
                              setState(() {
                                isSaveClick = true;
                                _validateDescription = true;
                                _validateEndDateBreakdown = false;
                                _validateStartDateBreakdown = false;
                                _validateEndDate = false;
                                _validateLeaveType = false;
                                _validateDate = false;
                                _validateEndDateBreakdown = false;
                              });
                            } else {
                              setState(() {
                                _validateDescription = false;
                                _validateStartDateBreakdown = false;
                                _validateDate = false;
                                _validateEndDate = false;
                                _validateLeaveType = false;
                                _validateDescription = false;
                                isAction = true;
                              });
                              Map<String, dynamic> createdDetails = {
                                "leave_type_id": selectedLeaveId,
                                'leave_type': selectedLeaveType,
                                'start_date': startDateSelect.text,
                                'start_date_breakdown': selectedStartDateValue,
                                'end_date': endDateSelect.text,
                                'end_date_breakdown': selectedEndDateValue,
                                'description': descriptionSelect.text,
                              };
                              await createNewLeaveType(createdDetails,
                                  checkfile, fileName, filePath);
                              setState(() {
                                isAction = false;
                              });
                              if (_errorMessage == null) {
                                Navigator.of(context).pop(true);
                                showCreateAnimation();
                              } else {
                                Navigator.of(context).pop(true);
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
                        child:
                        const Text('Save', style: TextStyle(color: Colors.white)),
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

  void showCancelAnimation() {
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
                      "Leave Cancelled Successfully",
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

  _showUpdateDialog(BuildContext context, Map<String, dynamic> record,
      List<Map<String, dynamic>> currentRequests) {
    _typeAheadEditController.text = record['leave_type_id']['name'];
    leaveDescription.text = currentRequests[0]['description'];
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              _fileNameController.addListener(() {
                setState(() {});
              });
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
                                height: MediaQuery.of(context).size.height * 0.03),
                            const Text("Leave Type",
                                style: TextStyle(color: Colors.black)),
                            SizedBox(
                                height: MediaQuery.of(context).size.height * 0.01),
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
                                  editleaveType = suggestion;
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
                                    maxHeight: MediaQuery.of(context).size.height * 0.23), // Limit height
                              ),
                            ),
                            SizedBox(
                                height: MediaQuery.of(context).size.height * 0.03),
                            const Text("Start Date",
                                style: TextStyle(color: Colors.black)),
                            SizedBox(
                                height: MediaQuery.of(context).size.height * 0.01),
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: TextField(
                                readOnly: true,
                                controller: startDateInput,
                                decoration: InputDecoration(
                                  labelText: "Start Date",
                                  labelStyle: TextStyle(color: Colors.grey[350]),
                                  border: const OutlineInputBorder(),
                                  errorText: _validateDate
                                      ? 'Please select a start date'
                                      : null,
                                  contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 10.0),
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
                                      startDateInput.text = DateFormat('yyyy-MM-dd')
                                          .format(startDate!);
                                    });
                                  }
                                },
                              ),
                            ),
                            SizedBox(
                                height: MediaQuery.of(context).size.height * 0.03),
                            const Text(" Start Date Breakdown",
                                style: TextStyle(color: Colors.black)),
                            SizedBox(
                                height: MediaQuery.of(context).size.height * 0.01),
                            DropdownSearch<String>(
                              items: breakdownMaps.values.toList().cast<String>(),
                              selectedItem:
                              breakdownMaps[record['start_date_breakdown']],
                              onChanged: (newValue) {
                                selectedEndDateValue = breakdownMaps.entries
                                    .firstWhere((entry) => entry.value == newValue)
                                    .key;
                                editStartDateBreakdown = selectedEndDateValue;
                              },
                              popupProps: PopupProps.menu(
                                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.23), // Set your desired height
                                showSearchBox: false,
                              ),
                            ),
                            SizedBox(
                                height: MediaQuery.of(context).size.height * 0.03),
                            const Text("End Date", style: TextStyle(color: Colors.black)),
                            SizedBox(
                                height: MediaQuery.of(context).size.height * 0.01),
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: TextField(
                                readOnly: true,
                                controller: endDateInput,
                                decoration: InputDecoration(
                                  border: const OutlineInputBorder(),
                                  errorText: _validateEndDate
                                      ? 'Please select an end date'
                                      : null,
                                  labelText: "End Date",
                                  labelStyle: TextStyle(color: Colors.grey[350]),
                                  contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 10.0),
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
                                      endDateInput.text =
                                          DateFormat('yyyy-MM-dd').format(endDate!);
                                    });
                                  }
                                },
                              ),
                            ),
                            SizedBox(
                                height: MediaQuery.of(context).size.height * 0.03),
                            const Text("End Date Breakdown",
                                style: TextStyle(color: Colors.black)),
                            SizedBox(
                                height: MediaQuery.of(context).size.height * 0.01),
                            DropdownSearch<String>(
                              items: breakdownMaps.values.toList().cast<String>(),
                              selectedItem:
                              breakdownMaps[record['end_date_breakdown']],
                              onChanged: (newValue) {
                                selectedEndDateValue = breakdownMaps.entries
                                    .firstWhere((entry) => entry.value == newValue)
                                    .key;
                                editEndDateBreakdown = selectedEndDateValue;
                              },
                              popupProps: PopupProps.menu(
                                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.23), // Set your desired height
                                showSearchBox: false,
                              ),
                            ),
                            SizedBox(
                                height: MediaQuery.of(context).size.height * 0.03),
                            const Text("Description",
                                style: TextStyle(color: Colors.black)),
                            SizedBox(
                                height: MediaQuery.of(context).size.height * 0.01),
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: TextField(
                                controller: leaveDescription,
                                decoration: InputDecoration(
                                  hintText: "",
                                  border: const OutlineInputBorder(),
                                  contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 10.0),
                                  errorText: _validateDescription
                                      ? 'Description cannot be empty'
                                      : null,
                                ),
                                onChanged: (newValue) {
                                  record['description'] = newValue;
                                },
                              ),
                            ),
                            SizedBox(
                                height: MediaQuery.of(context).size.height * 0.02),
                            if (currentRequests.isNotEmpty &&
                                currentRequests[0]['attachment'] != null)
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
                                      currentRequests[0]['attachment'];
                                      if (pdfPath.endsWith('.png') ||
                                          pdfPath.endsWith('.jpg') ||
                                          pdfPath.endsWith('.jpeg') ||
                                          pdfPath.endsWith('.gif')) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ImageViewer(
                                              imagePath: baseUrl + pdfPath,
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
                                    checkfile = true;
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
                                  icon: const Icon(Icons.close, color: Colors.red),
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
                                  fileName = newValue;
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
                              if (leaveDescription.text.isEmpty) {
                                setState(() {
                                  isSaveClick = true;
                                  _validateDescription = true;
                                });
                              } else {
                                setState(() {
                                  _validateAttachment = false;
                                  isAction = true;
                                });
                                Map<String, dynamic> updatedDetails = {
                                  'id': record['id'],
                                  'end_date_breakdown': editEndDateBreakdown ??
                                      record['end_date_breakdown'],
                                  'start_date_breakdown': editStartDateBreakdown ??
                                      record['end_date_breakdown'],
                                  'status': record['status'],
                                  'leave_type': editleaveType ??
                                      record['leave_type_id']['name'],
                                  'leave_type_id': selectedLeaveId ??
                                      record['leave_type_id']['id'],
                                  'start_date': startDateInput.text,
                                  'end_date': endDateInput.text,
                                  'description': leaveDescription.text,
                                };

                                await updateRequest(
                                    updatedDetails, checkfile, fileName, filePath);
                                setState(() {
                                  isAction = false;
                                });

                                if (_errorMessage == null || _errorMessage!.isEmpty) {
                                  Navigator.of(context).pop(true);
                                  showUpdateAnimation();
                                } else {
                                  Navigator.of(context).pop(true);
                                  _showUpdateDialog(context, record, currentRequests);
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
                          child:
                          const Text('Save', style: TextStyle(color: Colors.white)),
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

  Future<void> getLeaveTypes() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var employeeID = prefs.getInt("employee_id");
    var uri = Uri.parse(
        '$typedServerUrl/api/leave/employee-leave-type/$employeeID/');
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

  Future<void> getMyAllLeaveRequest() async {
    ///Fetch all my leave request
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    if (currentPage != 0) {
      var uri = Uri.parse(
          '$typedServerUrl/api/leave/user-request?employee_id=$employeeId&page=$currentPage');
      var response = await http.get(uri, headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });
      if (response.statusCode == 200) {
        setState(() {
          myAllRequests.addAll(
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

          List<String> mapStrings = myAllRequests.map(serializeMap).toList();
          Set<String> uniqueMapStrings = mapStrings.toSet();
          myAllRequests = uniqueMapStrings.map(deserializeMap).toList();
          allMyRequestsCount = jsonDecode(response.body)['count'];
          setState(() {
            isLoading = false;
          });
        });
      }
    } else {
      currentPage = 1;
      var uri = Uri.parse(
          '$typedServerUrl/api/leave/user-request?employee_id=$employeeId');
      var response = await http.get(uri, headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });
      if (response.statusCode == 200) {
        setState(() {
          myAllRequests = List<Map<String, dynamic>>.from(
              jsonDecode(response.body)['results']);
          String serializeMap(Map<String, dynamic> map) {
            return jsonEncode(map);
          }

          Map<String, dynamic> deserializeMap(String jsonString) {
            return jsonDecode(jsonString);
          }

          List<String> mapStrings = myAllRequests.map(serializeMap).toList();
          Set<String> uniqueMapStrings = mapStrings.toSet();
          myAllRequests = uniqueMapStrings.map(deserializeMap).toList();
          allMyRequestsCount = jsonDecode(response.body)['count'];
          setState(() {
            isLoading = false;
          });
        });
      }
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

  Future<void> getUserLeaveRequest() async {
    ///Fetch all my leave request
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/leave/user-request/');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      setState(() {
        userRequests = List<Map<String, dynamic>>.from(
          jsonDecode(response.body)['results'],
        );
      });
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

  Future<void> createNewLeaveType(Map<String, dynamic> createdDetails,
      checkfile, String fileName, String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var employeeId = prefs.getInt("employee_id");
    for (var leaveType in leaveTypes) {
      if (leaveType['name'] == createdDetails['leave_type']) {
      }
    }
    var request = http.MultipartRequest(
        'POST', Uri.parse('$typedServerUrl/api/leave/user-request/'));
    request.fields['employee_id'] = employeeId.toString();
    request.fields['description'] = createdDetails['description'];
    request.fields['end_date_breakdown'] =
    createdDetails['end_date_breakdown'];
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
      await getMyAllLeaveRequest();
      getRequestedCount();
      getApprovedCount();
      getCancelledCount();
      getRejectedCount();
      setState(() {});
    } else if (response.statusCode == 400) {
      isSaveClick = true;
      var responseBody = await response.stream.bytesToString();
      var errorJson = jsonDecode(responseBody);
      if (DateTime.parse(createdDetails['end_date'])
          .isBefore(DateTime.parse(createdDetails['start_date']))) {
        _errorMessage = errorJson["end_date"].join(", ");
      } else if (errorJson.containsKey("description")) {
        _errorMessage = "Description cannot be greater than 225 characters.";
      } else if (errorJson.containsKey("start_date_breakdown")) {
        _errorMessage = errorJson["start_date_breakdown"].join(", ");
      } else if (errorJson.containsKey("end_date_breakdown")) {
        _errorMessage = errorJson["end_date_breakdown"].join(", ");
      } else if (errorJson.containsKey("non_field_errors")) {
        _errorMessage = errorJson["non_field_errors"].join(", ");
      } else if (errorJson.containsKey("attachment")) {
        _errorMessage = "Attachment field is required";
      } else {
        _errorMessage = "An unknown error occurred.";
      }
      Navigator.of(context).pop(true);
      _showCreateDialog(context);
    } else {
      var responseBody = await response.stream.bytesToString();

      var errorJson = jsonDecode(responseBody);
      setState(() {
        if (DateTime.parse(createdDetails['end_date'])
            .isBefore(DateTime.parse(createdDetails['start_date']))) {
          _errorMessage = errorJson["end_date"].join(", ");
        } else if (errorJson.containsKey("description")) {
          _errorMessage = "Description cannot be greater than 225 characters.";
        } else if (errorJson.containsKey("start_date_breakdown")) {
          _errorMessage = errorJson["start_date_breakdown"].join(", ");
        } else if (errorJson.containsKey("end_date_breakdown")) {
          _errorMessage = errorJson["end_date_breakdown"].join(", ");
        } else if (errorJson.containsKey("non_field_errors")) {
          _errorMessage = errorJson["non_field_errors"].join(", ");
        } else {
          _errorMessage = "An unknown error occurred.";
        }
      });
    }
  }

  Future<void> updateRequest(Map<String, dynamic> updatedDetails, checkfile,
      String fileName, String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var itemId = updatedDetails['id'];
    var request = http.MultipartRequest(
        'PUT', Uri.parse('$typedServerUrl/api/leave/user-request/$itemId/'));
    request.fields['description'] = updatedDetails['description'];
    request.fields['end_date_breakdown'] = updatedDetails['end_date_breakdown'];
    request.fields['start_date_breakdown'] =
    updatedDetails['start_date_breakdown'];
    request.fields['start_date'] = updatedDetails['start_date'];
    request.fields['end_date'] = updatedDetails['end_date'];
    request.fields['leave_type_id'] =
        updatedDetails['leave_type_id']?.toString() ?? '';

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
      await getMyAllLeaveRequest();
      await getUserLeaveRequest();
      await getCurrentEmployeeDetails();
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
          _errorMessage = "Description cannot be greater than 225 characters.";
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

  Future<void> getLeaveDetails() async {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    employeeId = args['employee_id'].toString();

    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/leave/user-request');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      setState(() {
        leaveResults = jsonDecode(response.body)['results'];
      });
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

  Future<void> deleteRequest(int leaveId) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/leave/user-request/$leaveId/');

    var response = await http.delete(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      setState(() {
        isSaveClick = false;
        myAllRequests.removeWhere((item) => item['id'] == leaveId);
      });
      await getMyAllLeaveRequest();
      getRequestedCount();
      getApprovedCount();
      getCancelledCount();
      getRejectedCount();
    }
    else {
      isSaveClick = true;
    }
  }

  Future<void> getMyLeaveRequest() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/leave/available-leave/');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      setState(() {
        myRequests = List<Map<String, dynamic>>.from(
          jsonDecode(response.body)['results'],
        );
      });
    }
  }

  Future<void> getRequestedCount() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");

    var typedServerUrl = prefs.getString("typed_url");

    var uri = Uri.parse(
        '$typedServerUrl/api/leave/user-request/?employee_id=$employeeId&status=requested');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });

    if (response.statusCode == 200) {
      setState(() {
        requestedCount = jsonDecode(response.body)['count'];
      });
    }
  }

  Future<void> getApprovedCount() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");

    var typedServerUrl = prefs.getString("typed_url");

    var uri = Uri.parse(
        '$typedServerUrl/api/leave/user-request/?employee_id=$employeeId&status=approved');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });

    if (response.statusCode == 200) {
      setState(() {
        approvedCount = jsonDecode(response.body)['count'];
      });
    }
  }

  Future<void> getCancelledCount() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");

    var typedServerUrl = prefs.getString("typed_url");

    var uri = Uri.parse(
        '$typedServerUrl/api/leave/user-request/?employee_id=$employeeId&status=cancelled');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });

    if (response.statusCode == 200) {
      setState(() {
        cancelledCount = jsonDecode(response.body)['count'];
      });
    }
  }

  Future<void> getRejectedCount() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");

    var typedServerUrl = prefs.getString("typed_url");

    var uri = Uri.parse(
        '$typedServerUrl/api/leave/user-request/?employee_id=$employeeId&status=rejected');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });

    if (response.statusCode == 200) {
      setState(() {
        rejectedCount = jsonDecode(response.body)['count'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
        automaticallyImplyLeading: false,
        title: const Text('My Leave Request',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
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
                        _validateLeaveType = false;
                        _validateDate = false;
                        _validateStartDateBreakdown = false;
                        _validateEndDateBreakdown = false;
                        _validateDescription = false;
                        _validateEndDate = false;
                        isAction = false;

                        _errorMessage = null;
                        selectedLeaveId = null;
                        editStartDateBreakdown = null;
                        editEndDateBreakdown = null;
                        startDateSelect.clear();
                        endDateSelect.clear();
                        descriptionSelect.clear();
                        _fileNameController.clear();
                        _typeAheadEditController.clear();
                      });
                      _showCreateDialog(context);
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(75, 50),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.0),
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                    child: const Text('CREATE', style: TextStyle(color: Colors.red)),
                  ),
                ),
                // ),
              ],
            ),
          ),
        ],
      ),
      body: isLoading
          ? _buildShimmerEffect()
          : Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            if (enoughDays)
              Container(
                padding: const EdgeInsets.all(8.0),
                color: Colors.red,
                child: const Text(
                  "Employee doesn't have enough leave days.",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    myRequests.isEmpty
                        ? const Text('No leaves')
                        : GridView.builder(
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemCount: myRequests.length,
                      itemBuilder: (context, index) {
                        final record = myRequests[index];
                        return buildLeaveTile(record, baseUrl, getToken);
                      },
                      padding: const EdgeInsets.only(top: 10.0),
                      gridDelegate:
                      SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 1,
                        crossAxisSpacing: 20.0,
                        mainAxisSpacing: 20.0,
                        childAspectRatio: 1.5,
                        mainAxisExtent:
                        MediaQuery.of(context).size.width * 0.7,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    labelColor: Colors.red,
                    indicatorColor: Colors.red,
                    unselectedLabelColor: Colors.grey,
                    isScrollable: true,
                    tabs: [
                      Tab(text: 'All ($allMyRequestsCount)'),
                      Tab(text: 'Requested ($requestedCount)'),
                      Tab(text: 'Approved ($approvedCount)'),
                      Tab(text: 'Cancelled ($cancelledCount)'),
                      Tab(text: 'Rejected ($rejectedCount)'),
                    ],
                  ),
                  // ),
                  SizedBox(
                      height:
                      MediaQuery.of(context).size.height * 0.02),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.3,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          allMyRequestsCount == 0
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
                                  "There are no Leave records to display",
                                  style: TextStyle(
                                      fontSize: 16.0,
                                      color: Colors.black,
                                      fontWeight:
                                      FontWeight.bold),
                                ),
                              ],
                            ),
                          )
                              : buildTabStatusContent(myAllRequests),
                          requestedCount == 0
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
                                  "There are no Leave records to display",
                                  style: TextStyle(
                                      fontSize: 16.0,
                                      color: Colors.black,
                                      fontWeight:
                                      FontWeight.bold),
                                ),
                              ],
                            ),
                          )
                              : buildTabStatusContent(myAllRequests
                              .where((record) =>
                          record['status'] == 'requested')
                              .toList()),
                          approvedCount == 0
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
                                  "There are no Leave records to display",
                                  style: TextStyle(
                                      fontSize: 16.0,
                                      color: Colors.black,
                                      fontWeight:
                                      FontWeight.bold),
                                ),
                              ],
                            ),
                          )
                              : buildTabStatusContent(myAllRequests
                              .where((record) =>
                          record['status'] == 'approved')
                              .toList()),
                          cancelledCount == 0
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
                                  "There are no Leave records to display",
                                  style: TextStyle(
                                      fontSize: 16.0,
                                      color: Colors.black,
                                      fontWeight:
                                      FontWeight.bold),
                                ),
                              ],
                            ),
                          )
                              : buildTabStatusContent(myAllRequests
                              .where((record) =>
                          record['status'] == 'cancelled')
                              .toList()),
                          rejectedCount == 0
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
                                  "There are no Leave records to display",
                                  style: TextStyle(
                                      fontSize: 16.0,
                                      color: Colors.black,
                                      fontWeight:
                                      FontWeight.bold),
                                ),
                              ],
                            ),
                          )
                              : buildTabStatusContent(myAllRequests
                              .where((record) =>
                          record['status'] == 'rejected')
                              .toList()),
                        ],
                      ),
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

  Widget _buildShimmerEffect() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          if (enoughDays)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              color: Colors.red,
              child: const Text(
                "Employee doesn't have enough leave days.",
                style: TextStyle(color: Colors.white),
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Shimmer.fromColors(
                    baseColor: grey300,
                    highlightColor: grey100,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.9,
                      height: MediaQuery.of(context).size.height * 0.2,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 3,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.7,
                              height: MediaQuery.of(context).size.height * 0.2,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8.0),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                    Colors.grey.shade400.withOpacity(0.3),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 40.0,
                                    height: 40.0,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.grey[300],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
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
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  labelColor: Colors.red,
                  indicatorColor: Colors.red,
                  unselectedLabelColor: Colors.grey,
                  isScrollable: true,
                  tabs: const [
                    Tab(text: 'All'),
                    Tab(text: 'Requested'),
                    Tab(text: 'Approved'),
                    Tab(text: 'Cancelled'),
                    Tab(text: 'Rejected'),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.3,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildShimmerTabContent(),
                        _buildShimmerTabContent(),
                        _buildShimmerTabContent(),
                        _buildShimmerTabContent(),
                        _buildShimmerTabContent(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerTabContent() {
    return Shimmer.fromColors(
      baseColor: grey300,
      highlightColor: grey100,
      child: ListView.builder(
        itemCount: 3,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
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

  /// Display my leave based on status
  Widget buildMyLeaveTab(
      breakdown,
      BuildContext context,
      Map<String, dynamic> record,
      fullName,
      String profile,
      stateInfo,
      String recordId,
      token
      ) {
    return GestureDetector(
      onTap: () async {
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
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: currentRequests.isNotEmpty
                          ? [
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
                                  if (record['leave_type_id']['icon'] !=
                                      null &&
                                      record['leave_type_id']['icon']
                                          .isNotEmpty)
                                    Positioned.fill(
                                      child: ClipOval(
                                        child: Image.network(
                                          baseUrl +
                                              record['leave_type_id']
                                              ['icon'],
                                          headers: {
                                            "Authorization": "Bearer $token",
                                          },
                                          fit: BoxFit.cover,
                                          errorBuilder: (BuildContext
                                          context,
                                              Object exception,
                                              StackTrace? stackTrace) {
                                            return const Icon(
                                                Icons
                                                    .calendar_month_outlined,
                                                color: Colors.grey);
                                          },
                                        ),
                                      ),
                                    ),
                                  if (record['leave_type_id']['icon'] ==
                                      null ||
                                      record['leave_type_id']['icon']
                                          .isEmpty)
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.grey[400],
                                        ),
                                        child: const Icon(Icons
                                            .calendar_month_outlined),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(
                                width: MediaQuery.of(context).size.width *
                                    0.01),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentRequests[0]['leave_type_id']
                                    ['name'] ??
                                        '',
                                    style: const TextStyle(
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                    maxLines: 2,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5.0, vertical: 2.0),
                                    decoration: BoxDecoration(
                                      borderRadius:
                                      BorderRadius.circular(10.0),
                                      color: _getStateInfo(
                                          currentRequests[0]
                                          ['status'])
                                          .color
                                          .withOpacity(0.1),
                                    ),
                                    child: Text(
                                      _getStateInfo(currentRequests[0]
                                      ['status'])
                                          .displayString,
                                      style: TextStyle(
                                        color: _getStateInfo(
                                            currentRequests[0]
                                            ['status'])
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
                                0.05),
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Start Date',
                              style:
                              TextStyle(color: grey700),
                            ),
                            Text('${currentRequests[0]['start_date']}'),
                          ],
                        ),
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Start Date Breakdown',
                              style:
                              TextStyle(color: grey700),
                            ),
                            Text(
                                '${breakdownMaps[currentRequests[0]['start_date_breakdown']]}'),
                          ],
                        ),
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'End Date',
                              style:
                              TextStyle(color: grey700),
                            ),
                            Text('${currentRequests[0]['end_date']}'),
                          ],
                        ),
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'End Date Breakdown',
                              style:
                              TextStyle(color: grey700),
                            ),
                            Text(
                                '${breakdownMaps[currentRequests[0]['end_date_breakdown']]}'),
                          ],
                        ),
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Requested Days',
                              style:
                              TextStyle(color: grey700),
                            ),
                            Text(
                                '${currentRequests[0]['requested_days']}'),
                          ],
                        ),
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Description',
                              style:
                              TextStyle(color: grey700),
                            ),
                          ],
                        ),
                        Container(
                          width: double.infinity,
                          height: 100,
                          decoration: BoxDecoration(
                            border:
                            Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(4.0),
                            color: Colors.transparent,
                          ),
                          padding: const EdgeInsets.all(8.0),
                          child: SingleChildScrollView(
                            child: Text(
                              '${currentRequests[0]['description']}',
                              style: const TextStyle(color: Colors.black),
                            ),
                          ),
                        ),
                        if (currentRequests.isNotEmpty &&
                            currentRequests[0]['attachment'] != null)
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Attachment',
                                style: TextStyle(
                                    color: grey700),
                              ),
                              TextButton(
                                onPressed: () {
                                  String pdfPath =
                                  currentRequests[0]['attachment'];
                                  if (pdfPath.endsWith('.png') ||
                                      pdfPath.endsWith('.jpg') ||
                                      pdfPath.endsWith('.jpeg') ||
                                      pdfPath.endsWith('.gif')) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ImageViewer(
                                            imagePath: baseUrl + pdfPath,
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
                      ]
                          : [const Text('No current requests available')],
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
                            if (profile.isNotEmpty)
                              Positioned.fill(
                                child: ClipOval(
                                  child: Image.network(
                                    baseUrl + profile,
                                    headers: {
                                      "Authorization": "Bearer $token",
                                    },
                                    fit: BoxFit.cover,
                                    errorBuilder: (BuildContext context,
                                        Object exception,
                                        StackTrace? stackTrace) {
                                      return const Icon(Icons.calendar_month_outlined,
                                          color: Colors.grey); // Fallback icon
                                    },
                                  ),
                                ),
                              ),
                            if (profile.isEmpty)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey[400],
                                  ),
                                  child: const Icon(Icons.calendar_month_outlined),
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(width: MediaQuery.of(context).size.width * 0.01),
                      Expanded(
                        child: Text(
                          fullName ?? '',
                          style: const TextStyle(
                              fontSize: 16.0, fontWeight: FontWeight.bold),
                          maxLines: 2,
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
                                    setState(() async {
                                      await getCurrentLeaveRequest(recordId);
                                      isSaveClick = true;
                                      _validateLeaveType = false;
                                      _validateDate = false;
                                      _validateStartDateBreakdown = false;
                                      _validateEndDateBreakdown = false;
                                      _validateDescription = false;
                                      _validateEndDate = false;
                                      isAction = false;

                                      _errorMessage = null;
                                      leaveDescription.clear();
                                      startDateInput.text =
                                          record['start_date'] ?? '';
                                      endDateInput.text =
                                          record['end_date'] ?? '';
                                      editStartDateBreakdown = null;
                                      editEndDateBreakdown = null;

                                      getAllLeaveTypeName();
                                      getMyAllLeaveRequest();
                                      _showUpdateDialog(
                                          context, record, currentRequests);
                                    });
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
                                                    var leaveId = record['id'];
                                                    await deleteRequest(leaveId);
                                                    // Navigator.pop(context);
                                                    Navigator.of(context)
                                                        .pop(true);
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
                      Text('Start Date',
                          style: TextStyle(color: grey700)),
                      Text('${record['start_date']}'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('End Date',
                          style: TextStyle(color: grey700)),
                      Text('${record['end_date']}'),
                    ],
                  ),
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Visibility(
                          visible: record['status'] == 'approved',
                          child: ElevatedButton(
                            onPressed: () {
                              if (DateTime.parse(record['start_date'])
                                  .isAfter(DateTime.now()) ||
                                  DateTime.parse(record['start_date'])
                                      .isAtSameMomentAs(DateTime.now())) {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      backgroundColor: Colors.white,
                                      title: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(" Cancel Request "),
                                          IconButton(
                                            icon: const Icon(Icons.close,
                                                color: Colors.grey),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ],
                                      ),
                                      content: SizedBox(
                                        width:
                                        MediaQuery.of(context).size.width *
                                            0.8,
                                        height:
                                        MediaQuery.of(context).size.height *
                                            0.2,
                                        child: Column(
                                          children: [
                                            const Text(
                                              "\nAre you sure you want to cancel this leave request?\n",
                                              style: TextStyle(fontSize: 15.0),
                                            ),
                                            SizedBox(
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                    0.01),
                                            TextField(
                                              controller: descriptionLeaveType,
                                              decoration: const InputDecoration(
                                                hintText: "",
                                                border: OutlineInputBorder(),
                                                contentPadding:
                                                EdgeInsets.symmetric(
                                                    horizontal: 10.0),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      actions: [
                                        ElevatedButton(
                                          onPressed: () async {
                                            var cancelId = record['id'];
                                            var description =
                                                descriptionLeaveType
                                                    .text; // Get description
                                            await cancelRequest(
                                                cancelId, description);
                                            Navigator.of(context).pop(true);
                                            showCancelAnimation();
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius.circular(8.0),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 50, vertical: 12),
                                          ),
                                          child: const Text(
                                            "Cancel",
                                            style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: record['status'] == 'approved' &&
                                  (DateTime.parse(record['start_date'])
                                      .isAfter(DateTime.now()) ||
                                      DateTime.parse(record['start_date'])
                                          .isAtSameMomentAs(DateTime.now()))
                                  ? Colors.grey[350]
                                  : Colors.grey[50],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 50, vertical: 12),
                            ),
                            child: const Text(
                              'Cancel',
                              style:
                              TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // ),
          ),
        ),
      ),
    );
  }

  Widget buildLeaveTile(Map<String, dynamic> record, baseUrl, token) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isSaveClick = true;
          _validateLeaveType = false;
          _validateDate = false;
          _validateStartDateBreakdown = false;
          _validateEndDateBreakdown = false;
          _validateDescription = false;
          _validateEndDate = false;
          isAction = false;

          _errorMessage = null;
          selectedLeaveId = null;
          editStartDateBreakdown = null;
          editEndDateBreakdown = null;
          startDateSelect.clear();
          endDateSelect.clear();
          descriptionSelect.clear();
          _fileNameController.clear();
        });
        _showCreateSelectedDialog(context, record);
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                    height: MediaQuery.of(context).size.height * 0.2,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 20.0),
                                  child: Container(
                                    width: 40.0,
                                    height: 40.0,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.grey, width: 1.0),
                                    ),
                                    child: Stack(
                                      children: [
                                        if (record['leave_type_id']['icon'] !=
                                            null &&
                                            record['leave_type_id']['icon']
                                                .isNotEmpty)
                                          Positioned.fill(
                                            child: ClipOval(
                                              child: Image.network(
                                                baseUrl +
                                                    record['leave_type_id']
                                                    ['icon'],
                                                headers: {
                                                  "Authorization": "Bearer $token",
                                                },
                                                fit: BoxFit.cover,
                                                errorBuilder: (BuildContext
                                                context,
                                                    Object exception,
                                                    StackTrace? stackTrace) {
                                                  return const Icon(
                                                      Icons
                                                          .calendar_month_outlined,
                                                      color: Colors.grey);
                                                },
                                              ),
                                            ),
                                          ),
                                        if (record['leave_type_id']['icon'] ==
                                            null ||
                                            record['leave_type_id']['icon']
                                                .isEmpty)
                                          Positioned.fill(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.grey[400],
                                              ),
                                              child: const Icon(Icons
                                                  .calendar_month_outlined),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.01),
                                Expanded(
                                  // Add Expanded here
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 10.0),
                                    child: Text(
                                      record['leave_type_id']['name'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(left: 20.0),
                                child: Text(
                                  'Available Leave',
                                  style: TextStyle(
                                    fontWeight: FontWeight.normal,
                                    fontSize: 14.0,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 20.0),
                                child: Text(
                                  '${record['available_days']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.normal,
                                    fontSize: 14.0,
                                    color: Colors.black,
                                  ),
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
                              const Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(left: 20.0),
                                  child: Text(
                                    'Carryforward Leave',
                                    style: TextStyle(
                                      fontWeight: FontWeight.normal,
                                      fontSize: 14.0,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 20.0),
                                child: Text(
                                  '${record['carryforward_days']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.normal,
                                    fontSize: 14.0,
                                    color: Colors.black,
                                  ),
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
                              const Padding(
                                padding: EdgeInsets.only(left: 20.0),
                                child: Text(
                                  'Total Leaves',
                                  style: TextStyle(
                                    fontWeight: FontWeight.normal,
                                    fontSize: 14.0,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 20.0),
                                child: Text(
                                  '${record['total_leave_days']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.normal,
                                    fontSize: 14.0,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  Widget buildTabLoadingStatusContent(
      List<Map<String, dynamic>> myAllRequests) {
    return Padding(
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
    );
  }

  Widget buildTabStatusContent(List<Map<String, dynamic>> myAllRequests) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            shrinkWrap: true,
            itemCount: myAllRequests.length,
            itemBuilder: (context, index) {
              final record = myAllRequests[index];
              final recordId = record['id'].toString();
              final breakdown = _getBreakdown(record['start_date_breakdown']);
              final fullName = record['leave_type_id']['name'] ?? '';

              final profile = record['leave_type_id']?['icon'] ?? '';
              final stateInfo = _getStateInfo(record['status']);
              return buildMyLeaveTab(
                breakdown,
                context,
                record,
                fullName,
                profile,
                stateInfo,
                recordId,
                getToken
              );
            },
          ),
        ),
      ],
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
