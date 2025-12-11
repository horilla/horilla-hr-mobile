import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:multiselect_dropdown_flutter/multiselect_dropdown_flutter.dart';
import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:shimmer/shimmer.dart';
import '../../res/consts/app_colors.dart';

class SelectedLeaveType extends StatefulWidget {
  const SelectedLeaveType({super.key});

  @override
  _SelectedLeaveType createState() => _SelectedLeaveType();
}

class _SelectedLeaveType extends State<SelectedLeaveType> {
  int? typeId;
  int maxCount = 5;
  String? typeName;
  List<Map<String, dynamic>> leaveType = [];
  List<dynamic> leaveTypes = [];
  List<dynamic> selectedEmployeeIds = [];
  List<String> selectedEmployeeItems = [];
  List<String> selectedItems = [];
  List<Map<String, dynamic>> requestsEmployeesName = [];
  List<String> selectedEmployeeNames = [];
  Map<String, dynamic> typeDetails = {};
  Map<String, dynamic> allAssign = {};
  var employeeItems = [];
  var employeeItemsId = [];
  final _controller = NotchBottomBarController(index: -1);
  final List<Widget> bottomBarPages = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late String baseUrl = '';
  late Map<String, dynamic> arguments;
  bool isAction = true;
  bool permissionLeaveAssignCheck = false;
  bool permissionAllocationCheck = false;
  bool isLoading = true;
  bool permissionLeaveTypeCheck = false;
  bool permissionLeaveRequestCheck = false;
  bool permissionLeaveOverviewCheck = false;
  bool permissionMyLeaveRequestCheck = false;
  bool permissionLeaveAllocationCheck = false;
  late String getToken = '';


  @override
  void initState() {
    super.initState();
    getSelectedLeaveType();
    getAllAssignedLeave();
    getAssignedLeaveType();
    getBaseUrl();
    getEmployees();
    prefetchData();
    fetchToken();
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

  void showAssignAnimation() {
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
                      "Leave Assigned Successfully",
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

  Future<void> getAllAssignedLeave() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/leave/assign-leave/');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      setState(() {
        allAssign = jsonDecode(response.body);
      });
    }
  }

  void assignLeaves(List<int> employeeIds) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    for (int employeeId in employeeIds) {
      var uri = Uri.parse(
          '$typedServerUrl/api/leave/assign-leave/?employee_id=$employeeId&leave_type_id=$typeId');

      var response = await http.put(uri, headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });
      if (response.statusCode == 200) {
        setState(() {});
      }
    }
  }

  Future<void> assignLeave(
      List<dynamic> selectedEmployeeIds, String typeName) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse(
        '$typedServerUrl/api/leave/assign-leave/?leave_type_id=$typeName');
    var response = await http.post(uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "employee_ids": selectedEmployeeIds,
          "leave_type_ids": [typeId],
        }));
  }

  Future<void> getEmployees() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");

    employeeItems.clear();
    employeeItemsId.clear();

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
            String fullName = "${employee['employee_first_name'] ?? ''} ${employee['employee_last_name'] ?? ''}".trim();
            employeeItems.add(fullName);
            employeeItemsId.add(employee['id']);
          }
        });

        page++;
      } else {
        // Stop on any unexpected status code (not 200)
        print("Error fetching employees: ${response.statusCode}");
        hasMore = false;
      }
    }
  }

  Future<void> getAssignedLeaveType() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse(
        '$typedServerUrl/api/leave/assign-leave/?leave_type_id=$typeId');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      setState(() {
        leaveType = List<Map<String, dynamic>>.from(
          jsonDecode(response.body)['results'],
        );
      });
    }
  }

  Future<void> getSelectedLeaveType() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/leave/leave-type/$typeId');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      setState(() {
        typeDetails = jsonDecode(response.body);
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    typeId = args['selectedTypeId'].toInt();
    String typeName = args['selectedTypeName']!.toString();
    return Scaffold(
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
        automaticallyImplyLeading: false,
        title: Text(
          '${typeDetails['name'] ?? args['selectedTypeName']}',
          style:
          const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: isLoading
            ? Shimmer.fromColors(
          baseColor: grey300,
          highlightColor: grey100,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20.0, 0.0, 16.0, 15.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: ListView.builder(
              itemCount: 10,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Container(
                    width: double.infinity,
                    height: 40,
                    color: Colors.grey,
                  ),
                );
              },
            ),
          ),
        )
            : Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: SingleChildScrollView(
            child: Container(
              // color:Colors.white,
              padding: const EdgeInsets.fromLTRB(20.0, 0.0, 16.0, 15.0),
              width: MediaQuery.of(context).size.width * 0.95,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                      height: MediaQuery.of(context).size.height * 0.04),
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
                            if (typeDetails['icon'] != null && typeDetails['icon'].isNotEmpty)
                              Positioned.fill(
                                child: ClipOval(
                                  child: Image.network(
                                    baseUrl + typeDetails['icon'],
                                    headers: {
                                      "Authorization": "Bearer $getToken", // Changed from token to getToken
                                    },
                                    fit: BoxFit.cover,
                                    errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                                      return const Icon(Icons.calendar_month_outlined, color: Colors.grey);
                                    },
                                  ),
                                ),
                              ),
                            if (typeDetails['icon'] == null ||
                                typeDetails['icon'].isEmpty)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey[400],
                                  ),
                                  child: const Icon(
                                      Icons.calendar_month_outlined),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16.0),
                      Expanded(
                        child: Text(
                          typeDetails['name'] ?? "Unknown",
                          style: const TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold),
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                      height: MediaQuery.of(context).size.height * 0.04),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Period In',
                        style:
                        TextStyle(fontSize: 16.0, color: Colors.grey),
                      ),
                      Text(
                        '${typeDetails['period_in'] ?? "Unknown"}',
                        style: const TextStyle(fontSize: 16.0),
                      ),
                    ],
                  ),
                  SizedBox(
                      height: MediaQuery.of(context).size.height * 0.00),
                  const Divider(
                    thickness: 0.0,
                  ),
                  SizedBox(
                      height: MediaQuery.of(context).size.height * 0.00),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Count',
                        style:
                        TextStyle(fontSize: 16.0, color: Colors.grey),
                      ),
                      Text(
                        '${typeDetails['count'] ?? "Unknown"}',
                        style: const TextStyle(fontSize: 16.0),
                      ),
                    ],
                  ),
                  SizedBox(
                      height: MediaQuery.of(context).size.height * 0.00),
                  const Divider(
                    thickness: 0.0,
                  ),
                  SizedBox(
                      height: MediaQuery.of(context).size.height * 0.00),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Days',
                        style:
                        TextStyle(fontSize: 16.0, color: Colors.grey),
                      ),
                      Text(
                        '${typeDetails['total_days'] ?? "Unknown"}',
                        style: const TextStyle(fontSize: 16.0),
                      ),
                    ],
                  ),
                  SizedBox(
                      height: MediaQuery.of(context).size.height * 0.00),
                  const Divider(
                    thickness: 0.0,
                  ),
                  SizedBox(
                      height: MediaQuery.of(context).size.height * 0.00),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Reset',
                        style:
                        TextStyle(fontSize: 16.0, color: Colors.grey),
                      ),
                      Text(
                        '${typeDetails['reset'] ?? "Unknown"}',
                        style: const TextStyle(fontSize: 16.0),
                      ),
                    ],
                  ),
                  SizedBox(
                      height: MediaQuery.of(context).size.height * 0.00),
                  const Divider(
                    thickness: 0.0,
                  ),
                  SizedBox(
                      height: MediaQuery.of(context).size.height * 0.00),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Carryforward Type',
                        style:
                        TextStyle(fontSize: 16.0, color: Colors.grey),
                      ),
                      Text(
                        '${typeDetails['carryforward_type'] ?? "Unknown"}',
                        style: const TextStyle(fontSize: 16.0),
                      ),
                    ],
                  ),
                  SizedBox(
                      height: MediaQuery.of(context).size.height * 0.00),
                  const Divider(
                    thickness: 0.0,
                  ),
                  SizedBox(
                      height: MediaQuery.of(context).size.height * 0.00),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Is Paid',
                        style:
                        TextStyle(fontSize: 16.0, color: Colors.grey),
                      ),
                      Text(
                        '${typeDetails['payment'] ?? "Unknown"}',
                        style: const TextStyle(fontSize: 16.0),
                      ),
                    ],
                  ),
                  SizedBox(
                      height: MediaQuery.of(context).size.height * 0.00),
                  const Divider(
                    thickness: 0.0,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Require Approval',
                        style:
                        TextStyle(fontSize: 16.0, color: Colors.grey),
                      ),
                      Text(
                        '${typeDetails['require_approval'] ?? "Unknown"}',
                        style: const TextStyle(fontSize: 16.0),
                      ),
                    ],
                  ),
                  SizedBox(
                      height: MediaQuery.of(context).size.height * 0.00),
                  const Divider(
                    thickness: 0.0,
                  ),
                  SizedBox(
                      height: MediaQuery.of(context).size.height * 0.00),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Require Attachment',
                        style:
                        TextStyle(fontSize: 16.0, color: Colors.grey),
                      ),
                      Text(
                        '${typeDetails['require_attachment'] ?? "Unknown"}',
                        style: const TextStyle(fontSize: 16.0),
                      ),
                    ],
                  ),
                  SizedBox(
                      height: MediaQuery.of(context).size.height * 0.00),
                  const Divider(
                    thickness: 0.0,
                  ),
                  SizedBox(
                      height: MediaQuery.of(context).size.height * 0.05),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Visibility(
                        visible: employeeItems.isNotEmpty,
                        child: Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              setState(() {
                                isAction =
                                false; // Hide loading indicator
                              });
                              setState(() {
                                selectedEmployeeNames.clear();
                              });
                              setState(() {});
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext context) {
                                  return StatefulBuilder(
                                    builder: (context, setState) {
                                      return Stack(
                                        children: [
                                          AlertDialog(
                                            backgroundColor: Colors.white,
                                            title: Row(
                                              mainAxisAlignment:
                                              MainAxisAlignment
                                                  .spaceBetween,
                                              children: [
                                                const Text(
                                                  "Assign Leave",
                                                  style: TextStyle(
                                                    fontWeight:
                                                    FontWeight.bold,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                      Icons.close,
                                                      color: Colors.grey),
                                                  onPressed: () {
                                                    Navigator.of(context)
                                                        .pop();
                                                  },
                                                ),
                                              ],
                                            ),
                                            content: Container(
                                              width:
                                              MediaQuery.of(context)
                                                  .size
                                                  .width *
                                                  0.8,
                                              height:
                                              MediaQuery.of(context)
                                                  .size
                                                  .height *
                                                  0.3,
                                              constraints: BoxConstraints(
                                                maxHeight:
                                                MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                    0.8,
                                              ),
                                              child:
                                              SingleChildScrollView(
                                                child: Column(
                                                  crossAxisAlignment:
                                                  CrossAxisAlignment
                                                      .start,
                                                  children: [
                                                    const Text(
                                                      "Employee\n",
                                                      style: TextStyle(
                                                          fontSize: 15.0),
                                                    ),
                                                    Wrap(
                                                      spacing: 8.0,
                                                      runSpacing: 8.0,
                                                      children: [
                                                        for (int i = 0;
                                                        i <
                                                            selectedEmployeeNames
                                                                .length;
                                                        i++)
                                                          Chip(
                                                            label: Text(
                                                                selectedEmployeeNames[
                                                                i]),
                                                            onDeleted:
                                                                () {
                                                              setState(
                                                                      () {
                                                                    selectedEmployeeNames
                                                                        .removeAt(
                                                                        i);
                                                                    selectedEmployeeIds
                                                                        .removeAt(
                                                                        i);
                                                                  });
                                                            },
                                                          ),
                                                      ],
                                                    ),
                                                    SizedBox(
                                                        height: MediaQuery.of(
                                                            context)
                                                            .size
                                                            .height *
                                                            0.01),
                                                    MultiSelectDropdown
                                                        .simpleList(
                                                      list: employeeItems,
                                                      initiallySelected: const [],
                                                      onChange:
                                                          (selectedItems) {
                                                        setState(() {
                                                          selectedEmployeeNames
                                                              .clear();
                                                          selectedEmployeeIds
                                                              .clear();
                                                          if (selectedItems
                                                              .contains(
                                                              'Select All')) {
                                                            selectedEmployeeNames =
                                                                List.from(
                                                                    employeeItems);
                                                            selectedEmployeeIds =
                                                                List.from(
                                                                    employeeItemsId);
                                                            selectedEmployeeNames
                                                                .remove(
                                                                'Select All');
                                                          } else {
                                                            for (var item
                                                            in selectedItems) {
                                                              selectedEmployeeNames
                                                                  .add(
                                                                  item);
                                                              int index =
                                                              employeeItems
                                                                  .indexOf(item);
                                                              if (index !=
                                                                  -1) {
                                                                selectedEmployeeIds.add(
                                                                    employeeItemsId[
                                                                    index]);
                                                              }
                                                            }
                                                          }
                                                        });
                                                      },
                                                      includeSearch: true,
                                                      includeSelectAll:
                                                      true,
                                                      isLarge: false,
                                                      checkboxFillColor:
                                                      Colors.grey,
                                                      boxDecoration:
                                                      BoxDecoration(
                                                        border: Border.all(
                                                            color: Colors
                                                                .redAccent),
                                                        borderRadius:
                                                        BorderRadius
                                                            .circular(
                                                            10),
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
                                                    setState(() {
                                                      isAction = true;
                                                    });
                                                    await assignLeave(
                                                        selectedEmployeeIds,
                                                        typeName);
                                                    setState(() {
                                                      isAction = false;
                                                    });
                                                    getAssignedLeaveType();
                                                    Navigator.of(context)
                                                        .pop(true);
                                                    showAssignAnimation();
                                                  },
                                                  style: ButtonStyle(
                                                    backgroundColor:
                                                    MaterialStateProperty
                                                        .all<Color>(
                                                        Colors
                                                            .green),
                                                    shape: MaterialStateProperty
                                                        .all<
                                                        RoundedRectangleBorder>(
                                                      RoundedRectangleBorder(
                                                        borderRadius:
                                                        BorderRadius
                                                            .circular(
                                                            6.0),
                                                      ),
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    'Assign',
                                                    style: TextStyle(
                                                        color:
                                                        Colors.white),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (isAction)
                                            const Center(
                                              child:
                                              CircularProgressIndicator(),
                                            ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 50, vertical: 12),
                            ),
                            child: const Text(
                              'Assign',
                              style: TextStyle(
                                  fontSize: 18, color: Colors.white),
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
              // Handle errors here if needed
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
        bottomBarWidth: MediaQuery.of(context).size.width * 50,
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
