import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:multiselect_dropdown_flutter/multiselect_dropdown_flutter.dart';
import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:shimmer/shimmer.dart';
import '../../res/consts/app_colors.dart';

class AllAssignedLeave extends StatefulWidget {
  const AllAssignedLeave({super.key});

  @override
  _AllAssignedLeave createState() => _AllAssignedLeave();
}

class _AllAssignedLeave extends State<AllAssignedLeave> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _controller = NotchBottomBarController(index: -1);
  final List<Widget> bottomBarPages = [];
  List<Map<String, dynamic>> leaveType = [];
  List<dynamic> leaveTypes = [];
  List<Map<String, dynamic>> requestsEmployeesName = [];
  List<Map<String, dynamic>> allEmployeeList = [];
  List<dynamic> filteredRecords = [];
  List<String> createItems = [];
  List<dynamic> selectedLeaveIds = [];
  List<String> selectedEmployeeNames = [];
  List<int> selectedEmployeeIds = [];
  List<String> selectedLeaveItems = [];
  List<String> selectedEmpItems = [];
  List<dynamic> createRecords = [];
  List<String> selectedEmployeeItems = [];
  List<dynamic> leaveItems = [];
  List<Map<String, dynamic>> allLeaveList = [];
  List<int> assignedTypeItem = [];
  var employeeItems = [];
  var employeeItemsId = [];
  var leaveItemsId = [];
  int? selectedLeaveId;
  int maxCount = 5;
  bool isLoading = true;
  bool isAction = true;
  bool _isShimmer = true;
  bool _isShimmerVisible = true;
  bool permissionLeaveTypeCheck = false;
  bool permissionLeaveAssignCheck = false;
  bool permissionLeaveRequestCheck = false;
  bool permissionLeaveOverviewCheck = false;
  bool permissionMyLeaveRequestCheck = false;
  bool permissionLeaveAllocationCheck = false;
  String searchText = '';
  String? selectedLeaveType;
  late String baseUrl = '';
  late Map<String, dynamic> arguments;
  late String getToken = '';


  @override
  void initState() {
    super.initState();
    leaveType.clear();
    getLeaveType();
    getAssignedLeaveType();
    getLeaveTypes();
    getEmployees();
    fetchToken();
    getBaseUrl();
    prefetchData();
    _simulateLoading();
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

  Future<void> _simulateLoading() async {
    await Future.delayed(const Duration(seconds: 20));
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

  Future<void> getEmployees() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");

    employeeItems.clear();
    employeeItemsId.clear();
    allEmployeeList = [];

    for (var page = 1;; page++) {
      var uri = Uri.parse(
          '$typedServerUrl/api/employee/employee-selector/?page=$page');
      var response = await http.get(uri, headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'];

        // ✅ Stop the loop if no more data
        if (results.isEmpty) break;

        setState(() {
          for (var employee in results) {
            String fullName =
            "${employee['employee_first_name'] ?? ''} ${employee['employee_last_name'] ?? ''}".trim();
            employeeItems.add(fullName);
            employeeItemsId.add(employee['id']);
          }
          allEmployeeList.addAll(List<Map<String, dynamic>>.from(results));
        });
      } else {
        print('Error fetching employees: ${response.statusCode}');
        break;
      }
    }
  }

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
        for (var type in jsonDecode(response.body)['results']) {
          String fullName = type['name'];

          leaveItems.add(fullName);
          leaveItemsId.add(type['id']);
        }
        allLeaveList = List<Map<String, dynamic>>.from(
          jsonDecode(response.body)['results'],
        );
      });
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

  Future<void> getLeaveType() async {
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
        var assignedType = jsonDecode(response.body)['results'];
        for (var recAssignedType in assignedType) {
          assignedTypeItem.add(recAssignedType['id']);
        }
      });
    }
  }

  _showCreateDialog(BuildContext context) {
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
                      const Text('Assign Leaves'),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () {
                          selectedLeaveIds.clear();
                          selectedEmployeeIds.clear();
                          selectedEmployeeNames.clear();
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                  content: SingleChildScrollView(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.95,
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          const Text("Leave Type"),
                          MultiSelectDropdown.simpleList(
                            list: leaveItems,
                            initiallySelected: const [],
                            onChange: (selectedItems) {
                              setState(() {
                                selectedLeaveIds.clear();
                                selectedLeaveIds.addAll(selectedItems);
                              });
                            },
                            includeSearch: true,
                            includeSelectAll: true,
                            isLarge: true,
                            numberOfItemsLabelToShow: 3,
                            checkboxFillColor: Colors.grey,
                            boxDecoration: BoxDecoration(
                              border: Border.all(color: Colors.redAccent),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          // Display selected leave names
                          Wrap(
                            spacing: 8.0,
                            children: selectedLeaveIds.map((leave) {
                              return Chip(
                                label: Text(leave),
                                deleteIcon: const Icon(Icons.cancel),
                                onDeleted: () {
                                  setState(() {
                                    selectedLeaveIds.remove(leave);
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Text("Employee"),
                          ),
                          MultiSelectDropdown.simpleList(
                            list: employeeItems,
                            initiallySelected: const [],
                            onChange: (selectedItems) {
                              setState(() {
                                selectedEmployeeNames.clear();
                                selectedEmployeeIds.clear();
                                if (selectedItems.contains('Select All')) {
                                  selectedEmployeeNames =
                                      List.from(employeeItems);
                                  selectedEmployeeIds =
                                      List.from(employeeItemsId);
                                  selectedEmployeeNames.remove('Select All');
                                } else {
                                  for (var item in selectedItems) {
                                    selectedEmployeeNames.add(item);
                                    int index = employeeItems.indexOf(item);
                                    if (index != -1) {
                                      selectedEmployeeIds
                                          .add(employeeItemsId[index]);
                                    }
                                  }
                                }
                              });
                            },
                            includeSearch: true,
                            includeSelectAll: true,
                            isLarge: true,
                            width: 300,
                            numberOfItemsLabelToShow: 2,
                            checkboxFillColor: Colors.grey,
                            boxDecoration: BoxDecoration(
                              border: Border.all(color: Colors.redAccent),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          // Display selected employee names
                          Wrap(
                            spacing: 8.0,
                            children: selectedEmployeeNames.map((name) {
                              return Chip(
                                label: Text(name),
                                deleteIcon: const Icon(Icons.cancel),
                                onDeleted: () {
                                  setState(() {
                                    int index =
                                    selectedEmployeeNames.indexOf(name);
                                    if (index != -1) {
                                      selectedEmployeeNames.removeAt(index);
                                      selectedEmployeeIds.removeAt(index);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                isAction = true;
                                await createAssignedLeaveType(
                                    selectedEmployeeIds, selectedLeaveIds);
                                await getAssignedLeaveType();
                                setState(() {
                                  isAction = false;
                                });
                                buildTabContentAttendance(
                                    leaveType, searchText, getToken);
                                Navigator.of(context).pop(true);
                                showAssignAnimation();
                              },
                              style: ButtonStyle(
                                backgroundColor:
                                MaterialStateProperty.all<Color>(
                                    Colors.red),
                                shape: MaterialStateProperty.all<
                                    RoundedRectangleBorder>(
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
                    ),
                  ),
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

  Future<void> createAssignedLeaveType(
      selectedEmployeeIds, selectedLeaveIds) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    for (var leave in selectedLeaveIds) {
      var uri = Uri.parse('$typedServerUrl/api/leave/assign-leave/');
      for (var allLeave in allLeaveList) {
        if (allLeave['name'] == leave) {
          var leaveId = allLeave['id'];
          var body = jsonEncode({
            "employee_ids": selectedEmployeeIds,
            "leave_type_ids": [leaveId],
          });

          var response = await http.post(uri,
              headers: {
                "Content-Type": "application/json",
                "Authorization": "Bearer $token",
              },
              body: body);
        }
      }
    }
  }

  Future<void> getAssignedLeaveType() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    int page = 1;
    bool hasMoreData = true;

    List<Map<String, dynamic>> allLeaveTypes = [];

    while (hasMoreData) {
      var uri = Uri.parse(
          '$typedServerUrl/api/leave/assign-leave/?leave_type_id=$assignedTypeItem&page=$page');
      var response = await http.get(uri, headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        List<dynamic> results = responseData['results'];

        if (results.isNotEmpty) {
          allLeaveTypes.addAll(
            List<Map<String, dynamic>>.from(results),
          );
          page++;
        } else {
          hasMoreData = false;
        }

        setState(() {
          leaveType = allLeaveTypes;
          isLoading = false;
        });
      } else {
        setState(() {
          _isShimmerVisible = false;
          hasMoreData = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> filterRecords(String searchText) {
    List<Map<String, dynamic>> allEmployeeRecords = allEmployeeList;

    List<Map<String, dynamic>> allRecords = [];
    allRecords.addAll(allEmployeeRecords);

    List<Map<String, dynamic>> filteredRecords = allRecords.where((record) {
      String firstName =
      record['employee_first_name'].toString().toLowerCase();
      String lastName = record['employee_last_name'].toString().toLowerCase();
      String fullName = '$firstName $lastName';
      String search = searchText.toLowerCase();
      return fullName.startsWith(search);
    }).toList();

    return filteredRecords;
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
        title: const Row(
          children: [
            Text(
              'Assigned Leave',
              style: TextStyle(
                fontSize: 20,
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
                isAction = false;
                _showCreateDialog(context);
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(75, 50),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4.0),
                ),
                textStyle: const TextStyle(color: Colors.red),
                side: BorderSide(
                  color: Colors.red,
                  width: MediaQuery.of(context).size.width * 0.002,
                ),
              ),
              child: const Text(
                'ASSIGN',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
      body: _isShimmerVisible
          ? _buildLoadingWidget()
          : _buildAllAssignedLeaveWidget(),
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

  Widget _buildLoadingWidget() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 10.0, right: 10.0),
              child: Row(
                children: [
                  Expanded(
                    child: Card(
                      margin: const EdgeInsets.all(8),
                      elevation: 0,
                      child: Shimmer.fromColors(
                        baseColor: grey300,
                        highlightColor: grey100,
                        period: const Duration(seconds: 30),
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
            SizedBox(height: MediaQuery.of(context).size.height * 0.05),
            buildTabContentAttendance(leaveType, searchText, getToken),
          ],
        ),
      ),
    );
  }

  Widget _buildAllAssignedLeaveWidget() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 10.0, right: 10.0),
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
                            setState(() {
                              searchText = employeeSearchValue;
                              filteredRecords = filterRecords(searchText);
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
                              child: Icon(Icons.search,
                                  color: Colors.blueGrey.shade300),
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
            SizedBox(height: MediaQuery.of(context).size.height * 0.05),
            buildTabContentAttendance(leaveType, searchText, getToken),
          ],
        ),
      ),
    );
  }

  Widget buildTabContentAttendance(
      List<Map<String, dynamic>> leaveType, String searchText, token) {
    List<Map<String, dynamic>> filteredLeaveType = leaveType.where((leave) {
      String employeeFullName =
      leave['employee_id']['full_name'].toString().toLowerCase();
      return employeeFullName.contains(searchText.toLowerCase());
    }).toList();

    Map<String, List<Map<String, dynamic>>> leaveGroups = {};
    for (var record in filteredLeaveType) {
      final leaveName = record['leave_type_id']['name'] ?? 'Unnamed Leave Type';
      final leaveIcon =
          record['leave_type_id']['icon'] ?? Icons.calendar_month_outlined;
      leaveGroups.putIfAbsent(leaveName, () => []).add(record);
    }

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Column(
              children: leaveGroups.entries.map((entry) {
                final leaveName = entry.key;
                final leaveRecords = entry.value;
                return Theme(
                  data: ThemeData().copyWith(
                    dividerColor: Colors.white,
                    splashColor: Colors.white,
                    highlightColor: Colors.white,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: _isShimmerVisible
                          ? Shimmer.fromColors(
                        baseColor: grey300,
                        highlightColor: grey100,
                        period: const Duration(seconds: 30),
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
                      )
                          : ExpansionTile(
                        collapsedBackgroundColor: Colors.red.shade50,
                        backgroundColor: Colors.red.shade100,
                        title: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: leaveRecords.isNotEmpty &&
                                    leaveRecords[0]['leave_type_id']
                                    ['icon'] !=
                                        null
                                    ? Colors.transparent
                                    : Colors.white,
                              ),
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
                                    if (leaveRecords[0]['leave_type_id']
                                    ['icon'] !=
                                        null &&
                                        leaveRecords[0]['leave_type_id']
                                        ['icon']
                                            .isNotEmpty)
                                      Positioned.fill(
                                        child: ClipOval(
                                          child: Image.network(
                                            baseUrl +
                                                leaveRecords[0]
                                                ['leave_type_id']
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
                                    if (leaveRecords[0]['leave_type_id']
                                    ['icon'] ==
                                        null ||
                                        leaveRecords[0]['leave_type_id']
                                        ['icon']
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
                            const SizedBox(width: 8),
                            Text('$leaveName (${leaveRecords.length})',
                                style: const TextStyle(fontSize: 15)),
                          ],
                        ),
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxHeight: 200.0,
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.stretch,
                                children: leaveRecords.map((record) {
                                  final fullName =
                                  record['employee_id']['full_name'];
                                  final profile = record['employee_id']
                                  ['employee_profile'];

                                  return Container(
                                    color: Colors.white,
                                    child: ListTile(
                                      leading: Container(
                                        width: 40.0,
                                        height: 40.0,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: Colors.grey,
                                              width: 1.0),
                                        ),
                                        child: Stack(
                                          children: [
                                            if (profile != null &&
                                                profile.isNotEmpty)
                                              Positioned.fill(
                                                child: ClipOval(
                                                  child: Image.network(
                                                    baseUrl + profile,
                                                    headers: {
                                                      "Authorization": "Bearer $token",
                                                    },
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (BuildContext
                                                    context,
                                                        Object
                                                        exception,
                                                        StackTrace?
                                                        stackTrace) {
                                                      return const Icon(
                                                          Icons.person,
                                                          color: Colors
                                                              .grey);
                                                    },
                                                  ),
                                                ),
                                              ),
                                            if (profile == null ||
                                                profile.isEmpty)
                                              Positioned.fill(
                                                child: Container(
                                                  decoration:
                                                  BoxDecoration(
                                                    shape:
                                                    BoxShape.circle,
                                                    color:
                                                    Colors.grey[400],
                                                  ),
                                                  child:
                                                  const Icon(Icons.person),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      title: Text(fullName),
                                      tileColor: Colors.white,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
