import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:horilla/employee_views/rotating_shift.dart';
import 'package:horilla/employee_views/rotating_work_type.dart';
import 'package:horilla/employee_views/shift_request.dart';
import 'package:horilla/employee_views/work_type_request.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../res/consts/app_colors.dart';

class EmployeeFormPage extends StatefulWidget {
  const EmployeeFormPage({Key? key}) : super(key: key);

  @override
  State<EmployeeFormPage> createState() => _EmployeeFormPageState();
}

class _EmployeeFormPageState extends State<EmployeeFormPage>
    with SingleTickerProviderStateMixin {
  TextEditingController employeeNameController = TextEditingController();
  TextEditingController badgeController = TextEditingController();
  TextEditingController workEmailController = TextEditingController();
  TextEditingController workPhoneController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController cityController = TextEditingController();
  TextEditingController contactNameController = TextEditingController();
  TextEditingController descriptionSelect = TextEditingController();
  TextEditingController createRequestedDateController = TextEditingController();
  TextEditingController createRotateStartDateController =
  TextEditingController();
  TextEditingController bankNameController = TextEditingController();
  TextEditingController accountNumberController = TextEditingController();
  TextEditingController branchController = TextEditingController();
  TextEditingController bankCodeOneController = TextEditingController();
  TextEditingController bankAddressController = TextEditingController();
  TextEditingController bankCodeTwoController = TextEditingController();
  TextEditingController createRequestedTillController = TextEditingController();
  final List<Widget> bottomBarPages = [];
  final ScrollController _vertical = ScrollController();
  String empId = '';
  String jobRuleName = '';
  String? _errorMessage;
  String? selectedCreateEmployeeId;
  String? selectedEditEmployeeId;
  String? selectedEditPositionId;
  String? selectedEditDepartmentId;
  String? selectedEditWorkType;
  String? selectedEditShift;
  String? selectedCreateShift;
  String? selectedEditRequestedWorkType;
  String? selectedEditRotatedShift;
  String? selectedCreateRotatedShift;
  String? selectedCreateWorkType;
  String? selectedEmployeeWorkType;
  String? selectedEmployeeJobRole;
  String? selectedReportingManager;
  String? selectedEmployeeType;
  String? selectedCompany;
  String? selectedCreateRotatingWorkType;
  String? selectedShiftId;
  String? selectedEditShiftId;
  String employeeWorkInfoId = '';
  String employeeBankDetailsId = '';
  String? editEmployee;
  String? editPosition;
  String? editDepartment;
  String? createEmployee;
  String? editWorkType;
  String? editShift;
  String? createShift;
  String? editRequestedWorkType;
  String? editRotatedShift;
  String? createRotatedShift;
  String? createWorkType;
  String? employeeWorkType;
  String? employeeJobRole;
  String? reportingManager;
  String? employeeType;
  String? company;
  String? createRotatingWorkType;
  String? selectedCreateBasedOnValue;
  String fileName = '';
  String filePath = '';
  Map<String, String> shiftIdMap = {};
  Map<String, String> managerIdMap = {};
  Map<String, String> employeeTypeIdMap = {};
  Map<String, dynamic> employeeWorkInfoRecord = {};
  Map<String, dynamic> employeeJobRuleRecord = {};
  Map<String, dynamic> employeeBankRecord = {};
  Map<String, dynamic> employeeDetails = {};
  Map<String, String> employeeIdMap = {};
  Map<String, String> positionIdMap = {};
  Map<String, String> departmentIdMap = {};
  Map<String, String> workTypeIdMap = {};
  Map<String, String> companyIdMap = {};
  Map<String, String> jobRuleIdMap = {};
  Map<String, String> requestedWorkTypeIdMap = {};
  Map<String, String> rotateShiftIdMap = {};
  NotchBottomBarController _controller = NotchBottomBarController(index: -1);
  int maxCount = 5;
  int? employeeId;
  late TabController _tabController;
  late Map<String, dynamic> arguments;
  late String baseUrl = '';
  List<String> shiftDetails = [];
  List<dynamic> employeeWorkTypeRequest = [];
  List<dynamic> employeeRotatingWorkTypeRequest = [];
  List<dynamic> employeeShiftRequest = [];
  List<dynamic> employeeRotatingShiftRequest = [];
  List<Map<String, dynamic>> requests = [];
  List<String> employeeItems = [];
  List<String> employeeJobPositionRecord = [];
  List<String> reportingManagerRecord = [];
  List<String> employeeTypeRecord = [];
  List<String> companyRecord = [];
  List<String> employeeJobDepartmentRecord = [];
  List<String> workTypeItems = [];
  List<String> jobRuleItems = [];
  List<String> requestedWorkTypeItems = [];
  List<String> rotateShiftItems = [];
  List<String> workTypeItem = [];
  int employeeWorkTypeRequestCount = 0;
  int employeeRotatingWorkTypeRequestCount = 0;
  int employeeShiftRequestCount = 0;
  int employeeRotatingShiftRequestCount = 0;
  int initialTabIndex = 2;
  bool isLoading = true;
  bool _validateWorkType = false;
  bool _validateBankName = false;
  bool _validateAccountNumber = false;
  bool _validateBranch = false;
  bool _validateBankCodeOne = false;
  bool _validateBankAddress = false;
  bool _validateCity = false;
  bool _validateBankCodeTwo = false;
  bool _validateShift = false;
  bool _validateDepartment = false;
  bool _validateJobRule = false;
  bool _validateJobPosition = false;
  bool _validateMail = false;
  bool _validateEmployeeType = false;
  bool _validateSalary = false;
  bool _validateManager = false;
  bool _validateCompany = false;
  bool _validateWorkLocation = false;
  bool _validateJoiningDate = false;
  bool _validateEndDate = false;
  bool _validateSalaryPerHour = false;
  bool _validateDob = false;
  bool isAction = false;
  bool checkFile = false;
  bool isLoadingImage = false;
  XFile? pickedFile;
  late String getToken = '';


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    prefetchData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getEmployeeDetails();
      getBaseUrl();
      getWorkTypeRequest();
      getRotatingWorkTypeRequest();
      getShiftRequest();
      getRotatingShiftRequest();
      _loadEmployeeData();
      getEmployees();
      getWorkType();
      getRotatingWorkType();
      getRotatingShift();
      getRequestingShift();
      getEmployeeJobPosition();
      getEmployeeJobDepartment();
      getReportingManager();
      getCompanies();
      getEmployeeType();
      _simulateLoading();
      fetchToken();
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
    await Future.delayed(const Duration(seconds: 2));
    setState(() {});
  }

  Future<void> _loadEmployeeData() async {
    final prefs = await SharedPreferences.getInstance();
    employeeId = prefs.getInt("employee_id");
  }

  void initializeController() {
    if (employeeDetails['id'] != null && employeeDetails['id'] == employeeId) {
      setState(() {
        _controller = NotchBottomBarController(index: 2);
      });
    } else {
      setState(() {
        _controller = NotchBottomBarController(index: -1);
      });
    }
  }

  Future<void> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    var typedServerUrl = prefs.getString("typed_url");
    setState(() {
      baseUrl = typedServerUrl ?? '';
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

  Future<void> getEmployeeDetails() async {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    empId = args['employee_id'].toString();
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/employee/employees/$empId');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      setState(() {
        employeeDetails = jsonDecode(response.body);
        getEmployeeWorkInformation();
        getEmployeeBankInformation();
        _loadEmployeeData().then((_) {
          initializeController();
        });
        setState(() {
          isLoading = false;
        });
      });
    }
  }

  Future<void> getWorkTypeRequest() async {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    empId = args['employee_id'].toString();

    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");

    List<dynamic> allResults = [];
    int totalCount = 0;

    for (var page = 1;; page++) {
      var uri = Uri.parse(
        '$typedServerUrl/api/base/worktype-requests?employee_id=$empId&page=$page',
      );

      var response = await http.get(uri, headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'];

        if (results.isEmpty) break; // ✅ stop if no more data

        allResults.addAll(results);
        totalCount = data['count'];
      } else {
        print('Failed to load work type requests. Status: ${response.statusCode}');
        break;
      }
    }

    setState(() {
      employeeWorkTypeRequest = allResults;
      employeeWorkTypeRequestCount = totalCount;
    });
  }

  Future<void> getRotatingWorkTypeRequest() async {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    empId = args['employee_id'].toString();

    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");

    List<dynamic> allResults = [];
    int totalCount = 0;

    for (var page = 1;; page++) {
      var uri = Uri.parse(
        '$typedServerUrl/api/base/rotating-worktype-assigns/?employee_id=$empId&page=$page',
      );

      var response = await http.get(uri, headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'];

        if (results.isEmpty) break;

        allResults.addAll(results);
        totalCount = data['count'];
      } else {
        print('Failed to fetch rotating work type requests: ${response.statusCode}');
        break;
      }
    }

    setState(() {
      employeeRotatingWorkTypeRequest = allResults;
      employeeRotatingWorkTypeRequestCount = totalCount;
    });
  }

  Future<void> getShiftRequest() async {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    empId = args['employee_id'].toString();

    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");

    List<dynamic> allResults = [];
    int totalCount = 0;

    for (var page = 1;; page++) {
      var uri = Uri.parse(
        '$typedServerUrl/api/base/shift-requests/?employee_id=$empId&page=$page',
      );

      var response = await http.get(uri, headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'];

        if (results.isEmpty) break; // ✅ Exit loop when no more results

        allResults.addAll(results);
        totalCount = data['count'];
      } else {
        print('Failed to fetch shift requests: ${response.statusCode}');
        break;
      }
    }

    // ✅ Set state once with full data
    setState(() {
      employeeShiftRequest = allResults;
      employeeShiftRequestCount = totalCount;
    });
  }

  Future<void> getRotatingShiftRequest() async {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    empId = args['employee_id'].toString();

    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");

    List<dynamic> allResults = [];
    int totalCount = 0;

    for (var page = 1;; page++) {
      var uri = Uri.parse(
        '$typedServerUrl/api/base/rotating-shift-assigns/?employee_id=$empId&page=$page',
      );

      var response = await http.get(uri, headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'];

        if (results.isEmpty) break; // ✅ Stop if no more results

        allResults.addAll(results);
        totalCount = data['count'];
      } else {
        print('Error fetching rotating shift requests: ${response.statusCode}');
        break;
      }
    }

    // ✅ Update UI once after collecting all data
    setState(() {
      employeeRotatingShiftRequest = allResults;
      employeeRotatingShiftRequestCount = totalCount;
    });
  }

  Future<void> getEmployeeWorkInformation() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    employeeWorkInfoId = employeeDetails['employee_work_info_id'];
    var uri = Uri.parse(
        '$typedServerUrl/api/employee/employee-work-information/$employeeWorkInfoId');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      setState(() {
        employeeWorkInfoRecord = jsonDecode(response.body);
        getEmployeeJobRole();
      });
    }
  }

  Future<void> getEmployeeJobRole() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");

    for (var page = 1;; page++) {
      var uri = Uri.parse('$typedServerUrl/api/base/job-roles/?page=$page');
      var response = await http.get(uri, headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });

      if (response.statusCode == 200) {
        var responseBody = jsonDecode(response.body);

        if (responseBody['results'] == null || responseBody['results'].isEmpty) {
          break; // ✅ No more pages
        }

        employeeJobRuleRecord = responseBody;

        for (var rule in responseBody['results']) {
          final jobRule = rule['job_role'] ?? '';
          String jobRuleId = "${rule['id']}";

          jobRuleItems.add(jobRule);
          jobRuleIdMap[jobRule] = jobRuleId;

          if (rule['id'] == employeeWorkInfoRecord['job_role_id']) {
            jobRuleName = rule['job_role'];
          }
        }
      } else {
        print('Failed to fetch job roles. Status code: ${response.statusCode}');
        break; // ✅ Prevent infinite loop on failure
      }
    }

    setState(() {});
  }

  Future<void> getEmployeeJobPosition() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");

    for (var page = 1;; page++) {
      var uri = Uri.parse('$typedServerUrl/api/base/job-positions/?page=$page');
      var response = await http.get(uri, headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });

      if (response.statusCode == 200) {
        var responseBody = jsonDecode(response.body);
        var results = responseBody['results'];

        if (results == null || results.isEmpty) {
          break; // ✅ Exit loop when no more pages
        }

        for (var position in results) {
          final positionName = position['job_position'] ?? '';
          String positionId = "${position['id']}";
          employeeJobPositionRecord.add(positionName);
          positionIdMap[positionName] = positionId;
        }
      } else {
        print("Failed to fetch job positions: ${response.statusCode}");
        break; // ✅ Exit on error
      }
    }

    setState(() {}); // ✅ Optional: update UI after loading all pages
  }

  Future<void> getReportingManager() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");

    for (var page = 1;; page++) {
      var uri = Uri.parse('$typedServerUrl/api/employee/employees/?page=$page');
      var response = await http.get(uri, headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });

      if (response.statusCode == 200) {
        var responseBody = jsonDecode(response.body);
        var results = responseBody['results'];

        if (results == null || results.isEmpty) {
          break; // ✅ No more data, exit loop
        }

        for (var employee in results) {
          String firstName = "${employee['employee_first_name']}";
          String employeeId = "${employee['id']}";
          reportingManagerRecord.add(firstName);
          managerIdMap[firstName] = employeeId;
        }
      } else {
        print('Failed to fetch reporting managers: ${response.statusCode}');
        break; // ✅ Stop on error to avoid infinite looping
      }
    }
  }

  Future<void> getEmployeeType() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/employee/employee-type');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      for (var type in jsonDecode(response.body)) {
        String employeeTypeName = "${type['employee_type']}";
        String typeId = "${type['id']}";
        employeeTypeRecord.add(employeeTypeName);
        employeeTypeIdMap[employeeTypeName] = typeId;
      }
    }
  }

  Future<void> getCompanies() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");

    for (var page = 1;; page++) {
      var uri = Uri.parse('$typedServerUrl/api/base/companies/?page=$page');
      var response = await http.get(uri, headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });

      if (response.statusCode == 200) {
        var responseBody = jsonDecode(response.body);
        var results = responseBody['results'];

        if (results == null || results.isEmpty) {
          break; // ✅ Exit loop if no more companies
        }

        for (var company in results) {
          String companyName = "${company['company']}";
          String companyId = "${company['id']}";
          companyRecord.add(companyName);
          companyIdMap[companyName] = companyId;
        }
      } else {
        print('Failed to fetch companies: ${response.statusCode}');
        break; // ✅ Exit on API error
      }
    }
  }

  Future<void> getEmployeeJobDepartment() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");

    for (var page = 1;; page++) {
      var uri = Uri.parse('$typedServerUrl/api/base/departments/?page=$page');
      var response = await http.get(uri, headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });

      if (response.statusCode == 200) {
        var responseBody = jsonDecode(response.body);
        var results = responseBody['results'];

        if (results == null || results.isEmpty) {
          break; // ✅ Stop when no more departments
        }

        for (var department in results) {
          final departmentName = department['department'] ?? '';
          String departmentId = "${department['id']}";
          employeeJobDepartmentRecord.add(departmentName);
          departmentIdMap[departmentName] = departmentId;
        }
      } else {
        print('Failed to fetch departments: ${response.statusCode}');
        break; // ✅ Prevent infinite loop on error
      }
    }
  }

  Future<void> getEmployeeBankInformation() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    employeeBankDetailsId = employeeDetails['employee_bank_details_id'];
    var uri = Uri.parse(
        '$typedServerUrl/api/employee/employee-bank-details/$employeeBankDetailsId');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      setState(() {
        employeeBankRecord = jsonDecode(response.body);
      });
    }
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  Future<void> getEmployees() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");

    for (var page = 1;; page++) {
      var uri = Uri.parse(
          '$typedServerUrl/api/employee/employee-selector?page=$page');
      var response = await http.get(uri, headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });

      if (response.statusCode == 200) {
        var responseBody = jsonDecode(response.body);
        var results = responseBody['results'];

        if (results == null || results.isEmpty) {
          break; // ✅ Stop if no more employees
        }

        setState(() {
          for (var employee in results) {
            final firstName = employee['employee_first_name'] ?? '';
            final lastName = employee['employee_last_name'] ?? '';
            final fullName = (firstName.isEmpty ? '' : firstName) +
                (lastName.isEmpty ? '' : ' $lastName');
            String employeeId = "${employee['id']}";
            employeeItems.add(fullName);
            employeeIdMap[fullName] = employeeId;
          }
        });
      } else {
        print('Failed to fetch employees: ${response.statusCode}');
        break; // ✅ Prevent infinite looping on error
      }
    }
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

  Future<void> getRotatingWorkType() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/base/rotating-worktypes');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      List<dynamic> responseBody = jsonDecode(response.body);
      setState(() {
        for (var rec in responseBody) {
          final requestedWorkType = rec['name'] ?? '';
          String requestedWorkTypeId = "${rec['id']}";
          requestedWorkTypeItems.add(requestedWorkType);
          requestedWorkTypeIdMap[requestedWorkType] = requestedWorkTypeId;
        }
      });
    }
  }

  Future<void> getRotatingShift() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/base/rotating-shifts/');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      List<dynamic> responseBody = jsonDecode(response.body);
      setState(() {
        for (var rec in responseBody) {
          final rotatedShift = rec['name'] ?? '';
          String rotatedShiftId = "${rec['id']}";
          rotateShiftItems.add(rotatedShift);
          rotateShiftIdMap[rotatedShift] = rotatedShiftId;
        }
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

  Future<void> updateEmployeePersonalDetails(
      Map<String, dynamic> updatedDetails) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    String employeeId = updatedDetails['id'].toString();
    var uri = Uri.parse('$typedServerUrl/api/employee/employees/$employeeId/');
    var response = await http.put(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "badge_id": updatedDetails['badge_id'],
        "employee_first_name": updatedDetails['employee_first_name'],
        "employee_last_name": updatedDetails['employee_last_name'],
        "email": updatedDetails['email'],
        "phone": updatedDetails['phone'],
        "dob": updatedDetails['dob'],
        "gender": updatedDetails['gender'],
        "qualification": updatedDetails['qualification'],
        "experience": updatedDetails['experience'],
        "address": updatedDetails['address'],
        "country": updatedDetails['country'],
        "state": updatedDetails['state'],
        "city": updatedDetails['city'],
        "zip": updatedDetails['zip'],
        "emergency_contact": updatedDetails['emergency_contact'],
        "emergency_contact_name": updatedDetails['emergency_contact_name'],
        "emergency_contact_relation":
        updatedDetails['emergency_contact_relation'],
        "marital_status": updatedDetails['marital_status'],
        "children": updatedDetails['children'],
      }),
    );
    if (response.statusCode == 200) {
      _errorMessage = null;
      getEmployeeDetails();
      setState(() {});
    } else {
      var responseData = jsonDecode(response.body);
      if (responseData.containsKey('non_field_errors')) {
        _errorMessage = responseData['non_field_errors'].join('\n');
        setState(() {});
      }
      if (responseData.containsKey('employee_first_name')) {
        _errorMessage = "employee first name field may not be blank";
        setState(() {});
      }
      if (responseData.containsKey('email')) {
        _errorMessage = "email field may not be blank";
        setState(() {});
      }
      if (responseData.containsKey('phone')) {
        _errorMessage = "phone field may not be blank";
        setState(() {});
      }
      if (responseData.containsKey('experience')) {
        _errorMessage = "experience field may not be blank";
        setState(() {});
      }
      if (responseData.containsKey('children')) {
        _errorMessage = "children field may not be blank";
        setState(() {});
      }
      setState(() {});
    }
  }

  Future<void> updateEmployeeImage(Map<String, dynamic> updatedDetails,
      checkFile, String fileName, String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    String employeeId = updatedDetails['id'].toString();

    var request = http.MultipartRequest('PUT',
        Uri.parse('$typedServerUrl/api/employee/employees/$employeeId/'));

    if (checkFile) {
      var attachment =
      await http.MultipartFile.fromPath('employee_profile', filePath);
      request.files.add(attachment);
    }
    request.headers['Authorization'] = 'Bearer $token';
    var response = await request.send();
    if (response.statusCode == 200) {
      _errorMessage = null;
      getEmployeeDetails();
      setState(() {});
      setState(() {
        isLoadingImage = false;
      });
    } else {
      var responseBody = await response.stream.bytesToString();
      var errorJson = jsonDecode(responseBody);
      if (errorJson.containsKey('non_field_errors')) {
        _errorMessage = errorJson['non_field_errors'].join('\n');
        setState(() {});
      }
      setState(() {});
    }
  }

  Future<void> updateEmployeeWorkInfoDetails(
      Map<String, dynamic> updatedDetails) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    String employeeWorkId = updatedDetails['id'].toString();
    var uri = Uri.parse(
        '$typedServerUrl/api/employee/employee-work-information/$employeeWorkId/');
    var response = await http.put(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "department_id": updatedDetails['department_id'],
        "job_position_id": updatedDetails['job_position_id'],
        "shift_id": updatedDetails['shift_id'],
        "work_type_id": updatedDetails['work_type_id'],
        "job_role_id": updatedDetails['job_role_id'],
        "email": updatedDetails['email'],
        "basic_salary": updatedDetails['basic_salary'],
        "location": updatedDetails['location'],
        "date_joining": updatedDetails['date_joining'],
        "contract_end_date": updatedDetails['contract_end_date'],
        "salary_hour": updatedDetails['salary_hour'],
        "reporting_manager_id": updatedDetails['reporting_manager_id'],
        "company_id": updatedDetails['company_id'],
        "employee_type_id": updatedDetails['employee_type_id'],
      }),
    );
    if (response.statusCode == 200) {
      _errorMessage = null;
      getEmployeeWorkInformation();
      setState(() {});
    } else {
      var responseData = jsonDecode(response.body);
      if (responseData.containsKey('non_field_errors')) {
        _errorMessage = responseData['non_field_errors'].join('\n');
        setState(() {});
      } else if (responseData.containsKey('email')) {
        _errorMessage = responseData['email'].join('\n');
        setState(() {});
      } else if (responseData.containsKey('department_id')) {
        _errorMessage = responseData['department_id'].join('\n');
        setState(() {});
      } else if (responseData.containsKey('job_position_id')) {
        _errorMessage = responseData['job_position_id'].join('\n');
        setState(() {});
      } else if (responseData.containsKey('shift_id')) {
        _errorMessage = responseData['shift_id'].join('\n');
        setState(() {});
      } else if (responseData.containsKey('work_type_id')) {
        _errorMessage = responseData['work_type_id'].join('\n');
        setState(() {});
      } else if (responseData.containsKey('job_role_id')) {
        _errorMessage = responseData['job_role_id'].join('\n');
        setState(() {});
      } else if (responseData.containsKey('basic_salary')) {
        _errorMessage = responseData['basic_salary'].join('\n');
        setState(() {});
      } else if (responseData.containsKey('reporting_manager_id')) {
        _errorMessage = responseData['reporting_manager_id'].join('\n');
        setState(() {});
      } else if (responseData.containsKey('work_type_id')) {
        _errorMessage = responseData['work_type_id'].join('\n');
        setState(() {});
      } else if (responseData.containsKey('company_id')) {
        _errorMessage = responseData['company_id'].join('\n');
        setState(() {});
      } else if (responseData.containsKey('location')) {
        _errorMessage = responseData['location'].join('\n');
        setState(() {});
      } else if (responseData.containsKey('date_joining')) {
        _errorMessage = responseData['date_joining'].join('\n');
        setState(() {});
      } else if (responseData.containsKey('contract_end_date')) {
        _errorMessage = responseData['contract_end_date'].join('\n');
        setState(() {});
      } else if (responseData.containsKey('salary_hour')) {
        _errorMessage = responseData['salary_hour'].join('\n');
        setState(() {});
      }
      setState(() {});
    }
  }

  Future<void> updateEmployeeBankInfoDetails(
      Map<String, dynamic> updatedDetails) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    String employeeBankId = updatedDetails['id']?.toString() ?? '';
    var headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
    var body = jsonEncode({
      "employee_id": employeeDetails['id'],
      "bank_name": updatedDetails['bank_name'],
      "account_number": updatedDetails['account_number'],
      "branch": updatedDetails['branch_name'],
      "any_other_code1": updatedDetails['bank_one_code'],
      "address": updatedDetails['bank_address'],
      "city": updatedDetails['city'],
      "any_other_code2": updatedDetails['bank_two_code'],
    });
    http.Response response;
    if (employeeBankId.isEmpty) {
      var uri =
      Uri.parse('$typedServerUrl/api/employee/employee-bank-details/');
      response = await http.post(uri, headers: headers, body: body);
    } else {
      var uri = Uri.parse(
          '$typedServerUrl/api/employee/employee-bank-details/$employeeBankId/');
      response = await http.put(uri, headers: headers, body: body);
    }
    if (response.statusCode == 201) {
      _errorMessage = null;
      getEmployeeDetails();
      setState(() {});
    } else if (response.statusCode == 200) {
      await getEmployeeBankInformation();
      setState(() {});
    } else {
      var responseData = jsonDecode(response.body);
      if (responseData.containsKey('non_field_errors')) {
        _errorMessage = responseData['non_field_errors'].join('\n');
        setState(() {});
      }
      setState(() {});
    }
  }

  Future<void> createWorkTypeRequest(
      Map<String, dynamic> createdDetails) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/base/worktype-requests/');
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
        "work_type_id": createdDetails['work_type_id'],
      }),
    );
    if (response.statusCode == 201) {
      _errorMessage = null;
      getWorkTypeRequest();
      setState(() {});
    } else {
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

  Future<void> createRotatingWorkTypeRequest(
      Map<String, dynamic> createdDetails) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/base/rotating-worktype-assigns/');
    var response = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "employee_id": createdDetails['employee_id'],
        "rotating_work_type_id": createdDetails['rotate_work_type_id'],
        "start_date": createdDetails['start_date'],
        "based_on": createdDetails['based_on'],
        "rotate_after_day": createdDetails['rotate_after_day'],
      }),
    );
    if (response.statusCode == 201) {
      _errorMessage = null;
      getRotatingWorkTypeRequest();
      setState(() {});
    } else {
      var responseData = jsonDecode(response.body);
      if (responseData.containsKey('non_field_errors')) {
        _errorMessage = responseData['non_field_errors'].join('\n');
        setState(() {});
      }
      if (responseData.containsKey('rotating_work_type_id')) {
        _errorMessage = responseData['rotating_work_type_id'].join('\n');
        setState(() {});
      }
      if (responseData.containsKey('start_date')) {
        _errorMessage = responseData['start_date'].join('\n');
        setState(() {});
      }
      if (responseData.containsKey('based_on')) {
        _errorMessage = responseData['based_on'].join('\n');
        setState(() {});
      }
      if (responseData.containsKey('rotate_after_day')) {
        _errorMessage = responseData['rotate_after_day'].join('\n');
        setState(() {});
      }
      if (responseData.containsKey('employee_id')) {
        _errorMessage = responseData['employee_id'].join('\n');
        setState(() {});
      }
      setState(() {});
    }
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
      _errorMessage = null;
      getShiftRequest();
      setState(() {});
    } else {
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

  Future<void> createRotatingShiftRequest(
      Map<String, dynamic> createdDetails) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/base/rotating-shift-assigns/');
    var response = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "employee_id": createdDetails['employee_id'],
        "rotating_shift_id": createdDetails['rotating_shift_id'],
        "start_date": createdDetails['start_date'],
        "based_on": createdDetails['based_on'],
        "rotate_after_day": createdDetails['rotate_after_day'],
      }),
    );
    if (response.statusCode == 201) {
      _errorMessage = null;
      getRotatingShiftRequest();
      setState(() {});
    } else {
      var responseData = jsonDecode(response.body);
      if (responseData.containsKey('non_field_errors')) {
        _errorMessage = responseData['non_field_errors'].join('\n');
        setState(() {});
      }
      if (responseData.containsKey('rotating_work_type_id')) {
        _errorMessage = responseData['rotating_work_type_id'].join('\n');
        setState(() {});
      }
      if (responseData.containsKey('start_date')) {
        _errorMessage = responseData['start_date'].join('\n');
        setState(() {});
      }
      if (responseData.containsKey('based_on')) {
        _errorMessage = responseData['based_on'].join('\n');
        setState(() {});
      }
      if (responseData.containsKey('rotate_after_day')) {
        _errorMessage = responseData['rotate_after_day'].join('\n');
        setState(() {});
      }
      if (responseData.containsKey('employee_id')) {
        _errorMessage = responseData['employee_id'].join('\n');
        setState(() {});
      }
      setState(() {});
    }
  }

  Future<XFile?> uploadFile(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? pickedFile =
    await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      return pickedFile;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No image selected'),
          backgroundColor: redColor,
        ),
      );
      return null;
    }
  }

  Future<void> _pickImage(int id) async {
    isLoadingImage = true;
    XFile? file = await uploadFile(context);
    if (file != null) {
      setState(() async {
        pickedFile = file;
        fileName = file.name;
        filePath = file.path;
        checkFile = true;
        Map<String, dynamic> updatedDetails = {
          "id": id,
        };
        await updateEmployeeImage(
            updatedDetails, checkFile, fileName, filePath);
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

  void _showEditPersonalInfo(
      BuildContext context, Map<String, dynamic> employeeDetails) {
    TextEditingController badgeIdController = TextEditingController(
        text: employeeDetails['badge_id']?.toString() ?? '');
    TextEditingController firstNameController = TextEditingController(
        text: employeeDetails['employee_first_name']?.toString() ?? '');
    TextEditingController lastNameController = TextEditingController(
        text: employeeDetails['employee_last_name']?.toString() ?? '');
    TextEditingController emailController =
    TextEditingController(text: employeeDetails['email']?.toString() ?? '');
    TextEditingController phoneController =
    TextEditingController(text: employeeDetails['phone']?.toString() ?? '');
    TextEditingController birthController =
    TextEditingController(text: employeeDetails['dob']?.toString() ?? '');
    TextEditingController genderController = TextEditingController(
        text: employeeDetails['gender']?.toString() ?? '');
    TextEditingController qualificationController = TextEditingController(
        text: employeeDetails['qualification']?.toString() ?? '');
    TextEditingController experienceController = TextEditingController(
        text: employeeDetails['experience']?.toString() ?? '0');
    TextEditingController addressController = TextEditingController(
        text: employeeDetails['address']?.toString() ?? '');
    TextEditingController countryController = TextEditingController(
        text: employeeDetails['country']?.toString() ?? '');
    TextEditingController stateController =
    TextEditingController(text: employeeDetails['state']?.toString() ?? '');
    TextEditingController cityController =
    TextEditingController(text: employeeDetails['city']?.toString() ?? '');
    TextEditingController zipCodeController =
    TextEditingController(text: employeeDetails['zip']?.toString() ?? '');
    TextEditingController emergencyContactController = TextEditingController(
        text: employeeDetails['emergency_contact']?.toString() ?? '');
    TextEditingController contactNameController = TextEditingController(
        text: employeeDetails['emergency_contact_name']?.toString() ?? '');
    TextEditingController emergencyContactRelationController =
    TextEditingController(
        text: employeeDetails['emergency_contact_relation']?.toString() ??
            '');
    TextEditingController martialStatusController = TextEditingController(
        text: employeeDetails['marital_status']?.toString() ?? '');
    TextEditingController childrenController = TextEditingController(
        text: employeeDetails['children']?.toString() ?? '0');
    final name = employeeDetails['employee_first_name'];
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
                      Text(
                        "Edit $name",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: blackColor,
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
                                style: TextStyle(
                                    color: redColor,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.03),
                          Text(
                            'Badge ID',
                            style: TextStyle(color: blackColor),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          TextField(
                            controller: badgeIdController,
                            decoration: InputDecoration(
                              labelText: "Badge ID",
                              labelStyle: TextStyle(color: labelTextColor),
                              border: const OutlineInputBorder(),
                              contentPadding:
                              const EdgeInsets.symmetric(horizontal: 10.0),
                            ),
                            onChanged: (newValue) {
                              badgeIdController.text = newValue;
                            },
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
                                      'First Name',
                                      style: TextStyle(color: blackColor),
                                    ),
                                    SizedBox(
                                        height:
                                        MediaQuery.of(context).size.height *
                                            0.01),
                                    TextField(
                                      controller: firstNameController,
                                      decoration: InputDecoration(
                                        labelText: "First Name",
                                        labelStyle:
                                        TextStyle(color: labelTextColor),
                                        border: const OutlineInputBorder(),
                                        contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 10.0),
                                      ),
                                      onChanged: (newValue) {
                                        firstNameController.text = newValue;
                                      },
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
                                      "Last Name",
                                      style: TextStyle(color: blackColor),
                                    ),
                                    SizedBox(
                                        height:
                                        MediaQuery.of(context).size.height *
                                            0.01),
                                    TextField(
                                      controller: lastNameController,
                                      decoration: InputDecoration(
                                        labelText: "Last Name",
                                        labelStyle:
                                        TextStyle(color: labelTextColor),
                                        border: const OutlineInputBorder(),
                                        contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 10.0),
                                      ),
                                      onChanged: (newValue) {
                                        lastNameController.text = newValue;
                                      },
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
                                      'Email',
                                      style: TextStyle(color: blackColor),
                                    ),
                                    SizedBox(
                                        height:
                                        MediaQuery.of(context).size.height *
                                            0.01),
                                    TextField(
                                      controller: emailController,
                                      decoration: InputDecoration(
                                        labelText: "Email",
                                        labelStyle:
                                        TextStyle(color: labelTextColor),
                                        border: const OutlineInputBorder(),
                                        contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 10.0),
                                      ),
                                      onChanged: (newValue) {
                                        emailController.text = newValue;
                                      },
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
                                      "Phone",
                                      style: TextStyle(color: blackColor),
                                    ),
                                    SizedBox(
                                        height:
                                        MediaQuery.of(context).size.height *
                                            0.01),
                                    TextField(
                                      controller: phoneController,
                                      decoration: InputDecoration(
                                        labelText: "Phone",
                                        labelStyle:
                                        TextStyle(color: labelTextColor),
                                        border: const OutlineInputBorder(),
                                        contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 10.0),
                                      ),
                                      onChanged: (newValue) {
                                        phoneController.text = newValue;
                                      },
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
                                      'Date of Birth',
                                      style: TextStyle(color: blackColor),
                                    ),
                                    SizedBox(
                                        height:
                                        MediaQuery.of(context).size.height *
                                            0.01),
                                    TextField(
                                      readOnly: true,
                                      controller: birthController,
                                      onTap: () async {
                                        final selectedDate =
                                        await showCustomDatePicker(
                                            context, DateTime.now());
                                        if (selectedDate != null) {
                                          DateTime parsedDate =
                                          DateFormat('yyyy-MM-dd')
                                              .parse(selectedDate);
                                          setState(() {
                                            birthController.text =
                                                DateFormat('yyyy-MM-dd')
                                                    .format(parsedDate);
                                          });
                                        }
                                        _validateDob = false;
                                      },
                                      decoration: InputDecoration(
                                        border: const OutlineInputBorder(),
                                        labelText: "Date of Birth",
                                        labelStyle:
                                        TextStyle(color: labelTextColor),
                                        contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 10.0),
                                        errorText: _validateDob
                                            ? 'Please Choose a DOB'
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
                                      "Gender",
                                      style: TextStyle(color: blackColor),
                                    ),
                                    SizedBox(
                                        height:
                                        MediaQuery.of(context).size.height *
                                            0.01),
                                    DropdownButtonFormField<String>(
                                      style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        color: blackColor,
                                      ),
                                      value: genderController.text.isNotEmpty
                                          ? genderController.text
                                          : null,
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'male',
                                          child: Text('Male'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'female',
                                          child: Text('Female'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'other',
                                          child: Text('Other'),
                                        ),
                                      ],
                                      onChanged: (newValue) {
                                        genderController.text = newValue!;
                                      },
                                      decoration: InputDecoration(
                                        labelText: "Gender",
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
                                      'Qualification',
                                      style: TextStyle(color: blackColor),
                                    ),
                                    SizedBox(
                                        height:
                                        MediaQuery.of(context).size.height *
                                            0.01),
                                    TextField(
                                      controller: qualificationController,
                                      decoration: InputDecoration(
                                        labelText: "Qualification",
                                        labelStyle:
                                        TextStyle(color: labelTextColor),
                                        border: const OutlineInputBorder(),
                                        contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 10.0),
                                      ),
                                      onChanged: (newValue) {
                                        qualificationController.text = newValue;
                                      },
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
                                      "Experience",
                                      style: TextStyle(color: blackColor),
                                    ),
                                    SizedBox(
                                        height:
                                        MediaQuery.of(context).size.height *
                                            0.01),
                                    TextField(
                                      controller: experienceController,
                                      decoration: InputDecoration(
                                        labelText: "Experience",
                                        labelStyle:
                                        TextStyle(color: labelTextColor),
                                        border: const OutlineInputBorder(),
                                        contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 10.0),
                                      ),
                                      onChanged: (newValue) {
                                        experienceController.text = newValue;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.03),
                          Text(
                            'Address',
                            style: TextStyle(color: blackColor),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          TextField(
                            controller: addressController,
                            decoration: InputDecoration(
                              labelText: "Address",
                              labelStyle: TextStyle(color: labelTextColor),
                              border: const OutlineInputBorder(),
                              contentPadding:
                              const EdgeInsets.symmetric(horizontal: 10.0),
                            ),
                            onChanged: (newValue) {
                              addressController.text = newValue;
                            },
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
                                      'City',
                                      style: TextStyle(color: blackColor),
                                    ),
                                    SizedBox(
                                        height:
                                        MediaQuery.of(context).size.height *
                                            0.01),
                                    TextField(
                                      controller: cityController,
                                      decoration: InputDecoration(
                                        labelText: "City",
                                        labelStyle:
                                        TextStyle(color: labelTextColor),
                                        border: const OutlineInputBorder(),
                                        contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 10.0),
                                      ),
                                      onChanged: (newValue) {
                                        cityController.text = newValue;
                                      },
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
                                      "Zip Code",
                                      style: TextStyle(color: blackColor),
                                    ),
                                    SizedBox(
                                        height:
                                        MediaQuery.of(context).size.height *
                                            0.01),
                                    TextField(
                                      controller: zipCodeController,
                                      decoration: InputDecoration(
                                        labelText: "Zip Code",
                                        labelStyle:
                                        TextStyle(color: labelTextColor),
                                        border: const OutlineInputBorder(),
                                        contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 10.0),
                                      ),
                                      onChanged: (newValue) {
                                        zipCodeController.text = newValue;
                                      },
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
                                      'Emergency Contact',
                                      style: TextStyle(color: blackColor),
                                    ),
                                    SizedBox(
                                        height:
                                        MediaQuery.of(context).size.height *
                                            0.01),
                                    TextField(
                                      controller: emergencyContactController,
                                      decoration: InputDecoration(
                                        labelText: "Emergency Contact",
                                        labelStyle:
                                        TextStyle(color: labelTextColor),
                                        border: const OutlineInputBorder(),
                                        contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 10.0),
                                      ),
                                      onChanged: (newValue) {
                                        emergencyContactController.text =
                                            newValue;
                                      },
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
                                      "Contact Name",
                                      style: TextStyle(color: blackColor),
                                    ),
                                    SizedBox(
                                        height:
                                        MediaQuery.of(context).size.height *
                                            0.01),
                                    TextField(
                                      controller: contactNameController,
                                      decoration: InputDecoration(
                                        labelText: "Contact Name",
                                        labelStyle:
                                        TextStyle(color: labelTextColor),
                                        border: const OutlineInputBorder(),
                                        contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 10.0),
                                      ),
                                      onChanged: (newValue) {
                                        contactNameController.text = newValue;
                                      },
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
                                      'Contact Relation',
                                      style: TextStyle(color: blackColor),
                                    ),
                                    SizedBox(
                                        height:
                                        MediaQuery.of(context).size.height *
                                            0.01),
                                    TextField(
                                      controller:
                                      emergencyContactRelationController,
                                      decoration: InputDecoration(
                                        labelText: "Emergency Contact Relation",
                                        labelStyle:
                                        TextStyle(color: labelTextColor),
                                        border: const OutlineInputBorder(),
                                        contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 10.0),
                                      ),
                                      onChanged: (newValue) {
                                        emergencyContactRelationController
                                            .text = newValue;
                                      },
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
                                      "Marital Status",
                                      style: TextStyle(color: blackColor),
                                    ),
                                    SizedBox(
                                        height:
                                        MediaQuery.of(context).size.height *
                                            0.01),
                                    DropdownButtonFormField<String>(
                                      style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        color: blackColor,
                                      ),
                                      value: martialStatusController
                                          .text.isNotEmpty
                                          ? martialStatusController.text
                                          : null,
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'single',
                                          child: Text('Single'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'married',
                                          child: Text('Married'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'divorced',
                                          child: Text('Divorced'),
                                        ),
                                      ],
                                      onChanged: (newValue) {
                                        martialStatusController.text =
                                        newValue!;
                                      },
                                      decoration: InputDecoration(
                                        labelText: "Marital Status",
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
                            ],
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.03),
                          Text(
                            'Children',
                            style: TextStyle(color: blackColor),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          TextField(
                            controller: childrenController,
                            decoration: InputDecoration(
                              labelText: "Children",
                              labelStyle: TextStyle(color: labelTextColor),
                              border: const OutlineInputBorder(),
                              contentPadding:
                              const EdgeInsets.symmetric(horizontal: 10.0),
                            ),
                            onChanged: (newValue) {
                              childrenController.text = newValue;
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
                          if (birthController.text.isEmpty) {
                            _validateDob = true;
                            Navigator.of(context).pop(true);
                            _showEditPersonalInfo(context, employeeDetails);
                          } else {
                            setState(() {
                              isAction = true;
                            });
                            Map<String, dynamic> updatedDetails = {
                              'id': employeeDetails['id'],
                              "badge_id": badgeIdController.text,
                              "employee_first_name": firstNameController.text,
                              "employee_last_name": lastNameController.text,
                              "email": emailController.text,
                              "phone": phoneController.text,
                              "dob": birthController.text,
                              "gender": genderController.text,
                              "qualification": qualificationController.text,
                              "experience": experienceController.text,
                              "address": addressController.text,
                              "country": countryController.text,
                              "state": stateController.text,
                              "city": cityController.text,
                              "zip": zipCodeController.text,
                              "emergency_contact":
                              emergencyContactController.text,
                              "emergency_contact_name":
                              contactNameController.text,
                              "emergency_contact_relation":
                              emergencyContactRelationController.text,
                              "marital_status": martialStatusController.text,
                              "children": childrenController.text,
                            };
                            await updateEmployeePersonalDetails(updatedDetails);
                            setState(() {
                              isAction = false;
                            });
                            if (_errorMessage == null ||
                                _errorMessage!.isEmpty) {
                              Navigator.of(context).pop(true);
                              showUpdatePersonalAnimation();
                            } else {
                              Navigator.of(context).pop(true);
                              _showEditPersonalInfo(context, employeeDetails);
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

  void _showEditWorkInfo(BuildContext context, firstName,
      Map<String, dynamic> employeeWorkInfoRecord) {
    TextEditingController departmentController = TextEditingController(
        text: employeeWorkInfoRecord['department_name']?.toString() ?? '');
    TextEditingController jobPositionController = TextEditingController(
        text: employeeWorkInfoRecord['job_position_name']?.toString() ?? '');
    TextEditingController jobRoleController =
    TextEditingController(text: jobRuleName);
    TextEditingController shiftInfoController = TextEditingController(
        text: employeeWorkInfoRecord['shift_name']?.toString() ?? '');
    TextEditingController workTypeController = TextEditingController(
        text: employeeWorkInfoRecord['work_type_name']?.toString() ?? '');
    TextEditingController employeeTypeController = TextEditingController(
        text: employeeWorkInfoRecord['employee_type_name']?.toString() ?? '');
    TextEditingController salaryController = TextEditingController(
        text: employeeWorkInfoRecord['basic_salary']?.toString() ?? '');
    TextEditingController reportingManagerController = TextEditingController(
        text: employeeWorkInfoRecord['reporting_manager_first_name']
            ?.toString() ??
            '');
    TextEditingController companyController = TextEditingController(
        text: employeeWorkInfoRecord['company_name']?.toString() ?? '');
    TextEditingController workLocationController = TextEditingController(
        text: employeeWorkInfoRecord['location']?.toString() ?? '');
    TextEditingController workMailController = TextEditingController(
        text: employeeWorkInfoRecord['email']?.toString() ?? '');
    TextEditingController joiningDateController = TextEditingController(
        text: employeeWorkInfoRecord['date_joining']?.toString() ?? '');
    TextEditingController endDateController = TextEditingController(
        text: employeeWorkInfoRecord['contract_end_date']?.toString() ?? '');
    TextEditingController salaryPerHourController = TextEditingController(
        text: employeeWorkInfoRecord['salary_hour']?.toString() ?? '');
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
                      Text(
                        "Edit $firstName",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: blackColor,
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
                                style: TextStyle(
                                    color: redColor,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.03),
                          Text(
                            'Department',
                            style: TextStyle(color: blackColor),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          TypeAheadField<String>(
                            textFieldConfiguration: TextFieldConfiguration(
                              controller: departmentController,
                              decoration: InputDecoration(
                                labelText: 'Search Department',
                                labelStyle: TextStyle(color: labelTextColor),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10.0),
                                border: const OutlineInputBorder(),
                                errorText: _validateDepartment
                                    ? 'Please Choose a Department'
                                    : null,
                              ),
                            ),
                            suggestionsCallback: (pattern) {
                              return employeeJobDepartmentRecord
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
                                editDepartment = suggestion;
                                selectedEditDepartmentId =
                                departmentIdMap[suggestion];
                              });
                              departmentController.text = suggestion;
                              _validateDepartment = false;
                            },
                            noItemsFoundBuilder: (context) => const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'No Department Found',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                            errorBuilder: (context, error) => Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Error: $error',
                                style: TextStyle(fontSize: 16),
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
                            "Job Position",
                            style: TextStyle(color: blackColor),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          TypeAheadField<String>(
                            textFieldConfiguration: TextFieldConfiguration(
                              controller: jobPositionController,
                              decoration: InputDecoration(
                                labelText: 'Search Job Position',
                                labelStyle: TextStyle(color: labelTextColor),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10.0),
                                border: const OutlineInputBorder(),
                                errorText: _validateJobPosition
                                    ? 'Please Choose a Job Position'
                                    : null,
                              ),
                            ),
                            suggestionsCallback: (pattern) {
                              return employeeJobPositionRecord
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
                                editPosition = suggestion;
                                selectedEditPositionId =
                                positionIdMap[suggestion];
                              });
                              jobPositionController.text = suggestion;
                              _validateJobPosition = false;
                            },
                            noItemsFoundBuilder: (context) => const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'No Job Positions Found',
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
                            'Shift Information',
                            style: TextStyle(color: blackColor),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          TypeAheadField<String>(
                            textFieldConfiguration: TextFieldConfiguration(
                              controller: shiftInfoController,
                              decoration: InputDecoration(
                                labelText: 'Search Shift',
                                labelStyle: TextStyle(color: labelTextColor),
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10.0),
                                errorText: _validateShift
                                    ? 'Please Choose a Shift Information'
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
                                editShift = suggestion;
                                selectedEditShiftId = shiftIdMap[suggestion];
                              });
                              shiftInfoController.text = suggestion;
                              _validateShift = false;
                            },
                            noItemsFoundBuilder: (context) => const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'No Shift Information Found',
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
                            "Work Type",
                            style: TextStyle(color: blackColor),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          TypeAheadField<String>(
                            textFieldConfiguration: TextFieldConfiguration(
                              controller: workTypeController,
                              decoration: InputDecoration(
                                labelText: 'Search Work Type',
                                labelStyle: TextStyle(color: labelTextColor),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10.0),
                                border: const OutlineInputBorder(),
                                errorText: _validateWorkType
                                    ? 'Please Choose a Work Type'
                                    : null,
                              ),
                            ),
                            suggestionsCallback: (pattern) {
                              return workTypeItems
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
                                workTypeController.text = suggestion;
                                employeeWorkType = suggestion;
                                selectedEmployeeWorkType =
                                workTypeIdMap[suggestion];
                              });
                              _validateWorkType = false;
                            },
                            noItemsFoundBuilder: (context) => const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'No WorkTypes Found',
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
                            'Job Role',
                            style: TextStyle(color: blackColor),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          TypeAheadField<String>(
                            textFieldConfiguration: TextFieldConfiguration(
                              controller: jobRoleController,
                              decoration: InputDecoration(
                                labelText: 'Search Job Role',
                                labelStyle: TextStyle(color: labelTextColor),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10.0),
                                border: const OutlineInputBorder(),
                                errorText: _validateJobRule
                                    ? 'Please Choose a Job Rule'
                                    : null,
                              ),
                            ),
                            suggestionsCallback: (pattern) {
                              return jobRuleItems
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
                                jobRoleController.text = suggestion;
                                employeeJobRole = suggestion;
                                selectedEmployeeJobRole =
                                jobRuleIdMap[suggestion];
                              });
                              _validateJobRule = false;
                            },
                            noItemsFoundBuilder: (context) => const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'No Job Role Found',
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
                            "Work Mail",
                            style: TextStyle(color: blackColor),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          TextField(
                            controller: workMailController,
                            decoration: InputDecoration(
                              labelText: "Work Mail",
                              labelStyle: TextStyle(color: labelTextColor),
                              border: const OutlineInputBorder(),
                              contentPadding:
                              const EdgeInsets.symmetric(horizontal: 10.0),
                              errorText: _validateMail
                                  ? 'Please Choose a Work Mail'
                                  : null,
                            ),
                            onChanged: (newValue) {
                              workMailController.text = newValue;
                              _validateMail = false;
                            },
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.03),
                          Text(
                            'Employee Type',
                            style: TextStyle(color: blackColor),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          TypeAheadField<String>(
                            textFieldConfiguration: TextFieldConfiguration(
                              controller: employeeTypeController,
                              decoration: InputDecoration(
                                labelText: 'Employee Type',
                                labelStyle: TextStyle(color: labelTextColor),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10.0),
                                border: const OutlineInputBorder(),
                                errorText: _validateEmployeeType
                                    ? 'Please Choose a Employee Type'
                                    : null,
                              ),
                            ),
                            suggestionsCallback: (pattern) {
                              return employeeTypeRecord
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
                                employeeTypeController.text = suggestion;
                                employeeType = suggestion;
                                selectedEmployeeType =
                                employeeTypeIdMap[suggestion];
                              });
                              _validateEmployeeType = false;
                            },
                            noItemsFoundBuilder: (context) => const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'No Employee Type Found',
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
                            "Salary",
                            style: TextStyle(color: blackColor),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          TextField(
                            controller: salaryController,
                            decoration: InputDecoration(
                              labelText: "Salary",
                              labelStyle: TextStyle(color: labelTextColor),
                              border: const OutlineInputBorder(),
                              contentPadding:
                              const EdgeInsets.symmetric(horizontal: 10.0),
                              errorText: _validateSalary
                                  ? 'Salary can not be empty'
                                  : null,
                            ),
                            onChanged: (newValue) {
                              salaryController.text = newValue;
                              _validateSalary = false;
                            },
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.03),
                          Text(
                            'Reporting Manager',
                            style: TextStyle(color: blackColor),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          TypeAheadField<String>(
                            textFieldConfiguration: TextFieldConfiguration(
                              controller: reportingManagerController,
                              decoration: InputDecoration(
                                labelText: 'Search Reporting Manager',
                                labelStyle: TextStyle(color: labelTextColor),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10.0),
                                border: const OutlineInputBorder(),
                                errorText: _validateManager
                                    ? 'Please Choose a Reporting Manager'
                                    : null,
                              ),
                            ),
                            suggestionsCallback: (pattern) {
                              return reportingManagerRecord
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
                                reportingManagerController.text = suggestion;
                                reportingManager = suggestion;
                                selectedReportingManager =
                                managerIdMap[suggestion];
                              });
                              _validateManager = false;
                            },
                            noItemsFoundBuilder: (context) => const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'No Reporting Manager Found',
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
                            "Company",
                            style: TextStyle(color: blackColor),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          TypeAheadField<String>(
                            textFieldConfiguration: TextFieldConfiguration(
                              controller: companyController,
                              decoration: InputDecoration(
                                labelText: 'Search a Company',
                                labelStyle: TextStyle(color: labelTextColor),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10.0),
                                border: const OutlineInputBorder(),
                                errorText: _validateCompany
                                    ? 'Please Choose a Company'
                                    : null,
                              ),
                            ),
                            suggestionsCallback: (pattern) {
                              return companyRecord
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
                                companyController.text = suggestion;
                                company = suggestion;
                                selectedCompany = companyIdMap[suggestion];
                              });
                              _validateCompany = false;
                            },
                            noItemsFoundBuilder: (context) => const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'No Company Found',
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
                            'Work Location',
                            style: TextStyle(color: blackColor),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          TextField(
                            controller: workLocationController,
                            decoration: InputDecoration(
                              labelText: "Work Location",
                              labelStyle: TextStyle(color: labelTextColor),
                              border: const OutlineInputBorder(),
                              contentPadding:
                              const EdgeInsets.symmetric(horizontal: 10.0),
                              errorText: _validateWorkLocation
                                  ? 'Please Add Work Location'
                                  : null,
                            ),
                            onChanged: (newValue) {
                              workLocationController.text = newValue;
                              _validateWorkLocation = false;
                            },
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.03),
                          Text(
                            "Joining Date",
                            style: TextStyle(color: blackColor),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          TextField(
                            readOnly: true,
                            controller: joiningDateController,
                            onTap: () async {
                              final selectedDate = await showCustomDatePicker(
                                  context, DateTime.now());
                              if (selectedDate != null) {
                                DateTime parsedDate = DateFormat('yyyy-MM-dd')
                                    .parse(selectedDate);
                                setState(() {
                                  joiningDateController.text =
                                      DateFormat('yyyy-MM-dd')
                                          .format(parsedDate);
                                });
                              }
                              _validateJoiningDate = false;
                            },
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: "Joining Date",
                              labelStyle: TextStyle(color: labelTextColor),
                              contentPadding:
                              const EdgeInsets.symmetric(horizontal: 10.0),
                              errorText: _validateJoiningDate
                                  ? 'Please Choose a Joining Date'
                                  : null,
                            ),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.03),
                          Text(
                            'End Date',
                            style: TextStyle(color: blackColor),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          TextField(
                            readOnly: true,
                            controller: endDateController,
                            onTap: () async {
                              final selectedDate = await showCustomDatePicker(
                                  context, DateTime.now());
                              if (selectedDate != null) {
                                DateTime parsedDate = DateFormat('yyyy-MM-dd')
                                    .parse(selectedDate);
                                setState(() {
                                  endDateController.text =
                                      DateFormat('yyyy-MM-dd')
                                          .format(parsedDate);
                                });
                              }
                              _validateEndDate = false;
                            },
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: "End Date",
                              labelStyle: TextStyle(color: labelTextColor),
                              contentPadding:
                              const EdgeInsets.symmetric(horizontal: 10.0),
                              errorText: _validateEndDate
                                  ? 'Please Choose a End Date'
                                  : null,
                            ),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.03),
                          Text(
                            "Salary Per Hour",
                            style: TextStyle(color: blackColor),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          TextField(
                            controller: salaryPerHourController,
                            decoration: InputDecoration(
                              labelText: "Salary Per Hour",
                              labelStyle: TextStyle(color: labelTextColor),
                              border: const OutlineInputBorder(),
                              contentPadding:
                              const EdgeInsets.symmetric(horizontal: 10.0),
                              errorText: _validateSalaryPerHour
                                  ? 'Please Add Salary Per Hour'
                                  : null,
                            ),
                            onChanged: (newValue) {
                              salaryPerHourController.text = newValue;
                              _validateSalaryPerHour = false;
                            },
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.03),
                        ],
                      ),
                    ),
                  ),
                  actions: <Widget>[
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () async {
                          if (joiningDateController.text.isEmpty) {
                            setState(() {
                              _validateJoiningDate = true;
                              _validateEndDate = false;
                              Navigator.of(context).pop(true);
                              _showEditWorkInfo(
                                  context, firstName, employeeWorkInfoRecord);
                            });
                          } else if (endDateController.text.isEmpty) {
                            setState(() {
                              _validateJoiningDate = false;
                              _validateEndDate = true;
                              Navigator.of(context).pop(true);
                              _showEditWorkInfo(
                                  context, firstName, employeeWorkInfoRecord);
                            });
                          } else {
                            setState(() {
                              isAction = true;
                            });
                            Map<String, dynamic> updatedDetails = {
                              'id': employeeWorkInfoRecord['id'],
                              "department_id": selectedEditDepartmentId ??
                                  employeeWorkInfoRecord['department_id'],
                              "job_position_id": selectedEditPositionId ??
                                  employeeWorkInfoRecord['job_position_id'],
                              "shift_id": selectedEditShiftId ??
                                  employeeWorkInfoRecord['shift_id'],
                              "work_type_id": selectedEmployeeWorkType ??
                                  employeeWorkInfoRecord['work_type_id'],
                              "job_role_id": selectedEmployeeJobRole ??
                                  employeeWorkInfoRecord['job_role_id'],
                              "email": workMailController.text,
                              "basic_salary": salaryController.text,
                              "reporting_manager_id":
                              selectedReportingManager ??
                                  employeeWorkInfoRecord[
                                  'reporting_manager_id'],
                              "company_id": selectedCompany ??
                                  employeeWorkInfoRecord['company_id'],
                              "employee_type_id": selectedEmployeeType ??
                                  employeeWorkInfoRecord['employee_type_id'],
                              "location": workLocationController.text,
                              "date_joining": joiningDateController.text,
                              "contract_end_date": endDateController.text,
                              "salary_hour": salaryPerHourController.text,
                            };
                            await updateEmployeeWorkInfoDetails(updatedDetails);
                            setState(() {
                              isAction = false;
                            });
                            if (_errorMessage == null ||
                                _errorMessage!.isEmpty) {
                              Navigator.of(context).pop(true);
                              showUpdateWorkInfoAnimation();
                            } else {
                              Navigator.of(context).pop(true);
                              _showEditWorkInfo(
                                  context, firstName, employeeWorkInfoRecord);
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

  void _showEditBankInfo(BuildContext context, firstName,
      Map<String, dynamic> employeeBankRecord) {
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
                      Text(
                        "Edit $firstName",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: blackColor,
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
                                style: TextStyle(
                                    color: redColor,
                                    fontWeight: FontWeight.bold),
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
                                      'Bank Name',
                                      style: TextStyle(color: blackColor),
                                    ),
                                    SizedBox(
                                        height:
                                        MediaQuery.of(context).size.height *
                                            0.01),
                                    TextField(
                                      controller: bankNameController,
                                      decoration: InputDecoration(
                                        labelText: "Bank Name",
                                        labelStyle:
                                        TextStyle(color: labelTextColor),
                                        border: const OutlineInputBorder(),
                                        contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 10.0),
                                        errorText: _validateBankName
                                            ? 'Please Add a Bank Name'
                                            : null,
                                      ),
                                      onChanged: (newValue) {
                                        bankNameController.text = newValue;
                                        _validateBankName = false;
                                      },
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
                                      "Account Number",
                                      style: TextStyle(color: blackColor),
                                    ),
                                    SizedBox(
                                        height:
                                        MediaQuery.of(context).size.height *
                                            0.01),
                                    TextField(
                                      controller: bankNameController,
                                      decoration: InputDecoration(
                                        labelText: "Account Number",
                                        labelStyle:
                                        TextStyle(color: labelTextColor),
                                        border: const OutlineInputBorder(),
                                        contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 10.0),
                                        errorText: _validateAccountNumber
                                            ? 'Please Add a Account Number'
                                            : null,
                                      ),
                                      onChanged: (newValue) {
                                        bankNameController.text = newValue;
                                        _validateAccountNumber = false;
                                      },
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
                                      'Branch',
                                      style: TextStyle(color: blackColor),
                                    ),
                                    SizedBox(
                                        height:
                                        MediaQuery.of(context).size.height *
                                            0.01),
                                    TextField(
                                      controller: branchController,
                                      decoration: InputDecoration(
                                        labelText: "Branch",
                                        labelStyle:
                                        TextStyle(color: labelTextColor),
                                        border: const OutlineInputBorder(),
                                        contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 10.0),
                                        errorText: _validateBranch
                                            ? 'Please Add a Branch Name'
                                            : null,
                                      ),
                                      onChanged: (newValue) {
                                        branchController.text = newValue;
                                        _validateBranch = false;
                                      },
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
                                      "Bank Code #1",
                                      style: TextStyle(color: blackColor),
                                    ),
                                    SizedBox(
                                        height:
                                        MediaQuery.of(context).size.height *
                                            0.01),
                                    TextField(
                                      controller: bankCodeOneController,
                                      decoration: InputDecoration(
                                        labelText: "Bank Code #1",
                                        labelStyle:
                                        TextStyle(color: labelTextColor),
                                        border: const OutlineInputBorder(),
                                        contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 10.0),
                                        errorText: _validateBankCodeOne
                                            ? 'Please Add Bank Code #1'
                                            : null,
                                      ),
                                      onChanged: (newValue) {
                                        bankCodeOneController.text = newValue;
                                        _validateBankCodeOne = false;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.03),
                          Text(
                            "Bank Address",
                            style: TextStyle(color: blackColor),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.01),
                          TextField(
                            controller: bankAddressController,
                            decoration: InputDecoration(
                              labelText: "Bank Address",
                              labelStyle: TextStyle(color: labelTextColor),
                              border: const OutlineInputBorder(),
                              contentPadding:
                              const EdgeInsets.symmetric(horizontal: 10.0),
                              errorText: _validateBankAddress
                                  ? 'Please Add Bank Address'
                                  : null,
                            ),
                            onChanged: (newValue) {
                              bankAddressController.text = newValue;
                              _validateBankAddress = false;
                            },
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
                                      'City',
                                      style: TextStyle(color: blackColor),
                                    ),
                                    SizedBox(
                                        height:
                                        MediaQuery.of(context).size.height *
                                            0.01),
                                    TextField(
                                      controller: cityController,
                                      decoration: InputDecoration(
                                        labelText: "City",
                                        labelStyle:
                                        TextStyle(color: labelTextColor),
                                        border: const OutlineInputBorder(),
                                        contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 10.0),
                                        errorText: _validateCity
                                            ? 'Please Add a City Name'
                                            : null,
                                      ),
                                      onChanged: (newValue) {
                                        cityController.text = newValue;
                                        _validateCity = false;
                                      },
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
                                      "Bank Code #2",
                                      style: TextStyle(color: blackColor),
                                    ),
                                    SizedBox(
                                        height:
                                        MediaQuery.of(context).size.height *
                                            0.01),
                                    TextField(
                                      controller: bankCodeTwoController,
                                      decoration: InputDecoration(
                                        labelText: "Bank Code #2",
                                        labelStyle:
                                        TextStyle(color: labelTextColor),
                                        border: const OutlineInputBorder(),
                                        contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 10.0),
                                        errorText: _validateBankCodeTwo
                                            ? 'Please Add Bank Code #2'
                                            : null,
                                      ),
                                      onChanged: (newValue) {
                                        bankCodeTwoController.text = newValue;
                                        _validateBankCodeTwo = false;
                                      },
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
                          if (bankNameController.text.isEmpty) {
                            setState(() {
                              _validateBankName = true;
                              _validateAccountNumber = false;
                              _validateBranch = false;
                              _validateBankCodeOne = false;
                              _validateBankAddress = false;
                              Navigator.of(context).pop(true);
                              _showEditBankInfo(
                                  context, firstName, employeeBankRecord);
                            });
                          } else if (bankNameController.text.isEmpty) {
                            setState(() {
                              _validateBankName = false;
                              _validateAccountNumber = true;
                              _validateBranch = false;
                              _validateBankCodeOne = false;
                              _validateBankAddress = false;
                              Navigator.of(context).pop(true);
                              _showEditBankInfo(
                                  context, firstName, employeeBankRecord);
                            });
                          } else if (branchController.text.isEmpty) {
                            setState(() {
                              _validateBankName = false;
                              _validateAccountNumber = false;
                              _validateBranch = true;
                              _validateBankCodeOne = false;
                              _validateBankAddress = false;
                              Navigator.of(context).pop(true);
                              _showEditBankInfo(
                                  context, firstName, employeeBankRecord);
                            });
                          } else if (bankCodeOneController.text.isEmpty) {
                            setState(() {
                              _validateBankName = false;
                              _validateAccountNumber = false;
                              _validateBranch = false;
                              _validateBankCodeOne = true;
                              _validateBankAddress = false;
                              Navigator.of(context).pop(true);
                              _showEditBankInfo(
                                  context, firstName, employeeBankRecord);
                            });
                          } else if (bankAddressController.text.isEmpty) {
                            setState(() {
                              _validateBankName = false;
                              _validateAccountNumber = false;
                              _validateBranch = false;
                              _validateBankCodeOne = false;
                              _validateBankAddress = true;
                              Navigator.of(context).pop(true);
                              _showEditBankInfo(
                                  context, firstName, employeeBankRecord);
                            });
                          } else {
                            setState(() {
                              isAction = true;
                            });
                            Map<String, dynamic> updatedDetails = {
                              "id": employeeBankRecord['id'],
                              "employee_id": employeeBankRecord['employee_id'],
                              "bank_name": bankNameController.text,
                              "account_number": bankNameController.text,
                              "branch_name": branchController.text,
                              "bank_one_code": bankCodeOneController.text,
                              "bank_address": bankAddressController.text,
                              "city": cityController.text,
                              "bank_two_code": bankCodeTwoController.text,
                            };
                            await updateEmployeeBankInfoDetails(updatedDetails);
                            setState(() {
                              isAction = false;
                            });
                            if (_errorMessage == null ||
                                _errorMessage!.isEmpty) {
                              Navigator.of(context).pop(true);
                              showUpdateBankInfoAnimation();
                            } else {
                              Navigator.of(context).pop(true);
                              _showEditBankInfo(
                                  context, firstName, employeeBankRecord);
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

  void _showEditOptions(BuildContext context, employeeDetails, firstName,
      employeeWorkInfoRecord, employeeBankRecord) {
    List<PopupMenuEntry<String>> menuItems = [
      const PopupMenuItem(
        value: 'personal',
        child: Text('Personal Info'),
      ),
      const PopupMenuItem(
        value: 'bank',
        child: Text('Bank Info'),
      ),
    ];

    if (employeeDetails['id'] != null && employeeDetails['id'] != employeeId) {
      menuItems.insert(
          1,
          const PopupMenuItem(
            value: 'work',
            child: Text('Work Info'),
          ));
    }

    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(100, 80, 0, 0),
      items: menuItems,
    ).then((value) {
      if (value == 'personal') {
        isAction = false;
        _errorMessage = null;
        _showEditPersonalInfo(context, employeeDetails);
      } else if (value == 'work') {
        isAction = false;
        _errorMessage = null;
        _showEditWorkInfo(context, firstName, employeeWorkInfoRecord);
      } else if (value == 'bank') {
        isAction = false;
        _errorMessage = null;
        bankNameController.text =
            employeeBankRecord['bank_name']?.toString() ?? '';
        bankNameController.text =
            employeeBankRecord['account_number']?.toString() ?? '';
        branchController.text = employeeBankRecord['branch']?.toString() ?? '';
        bankCodeOneController.text =
            employeeBankRecord['any_other_code1']?.toString() ?? '';
        bankAddressController.text =
            employeeBankRecord['address']?.toString() ?? '';
        cityController.text = employeeBankRecord['city']?.toString() ?? '';
        bankCodeTwoController.text =
            employeeBankRecord['any_other_code2']?.toString() ?? '';
        _showEditBankInfo(context, firstName, employeeBankRecord);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final firstName = employeeDetails['employee_first_name'] ?? '';
    final lastName = employeeDetails['employee_last_name'] ?? '';
    final fullName = (firstName.isEmpty ? '' : firstName) +
        (lastName.isEmpty ? '' : ' $lastName');
    employeeNameController.text = fullName;
    badgeController.text = employeeDetails['badge_id'] ?? '';
    emailController.text = employeeDetails['email'] ?? '';
    phoneController.text = employeeDetails['phone'] ?? '';
    workEmailController.text = employeeDetails['email'] ?? '';
    workPhoneController.text = employeeDetails['phone'] ?? '';
    final args =
    ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    bool permissionCheck = args?['permission_check'] ?? false;
    bool checkManager = permissionCheck ||
        (employeeDetails['id'] != null && employeeDetails['id'] == employeeId);
    return Scaffold(
      backgroundColor: whiteColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: redColor,
        actions: [
          if (checkManager)
            Visibility(
              visible: employeeDetails['id'] != null,
              child: IconButton(
                icon: const Icon(Icons.edit),
                color: whiteColor,
                onPressed: () => _showEditOptions(context, employeeDetails,
                    firstName, employeeWorkInfoRecord, employeeBankRecord),
              ),
            ),
          Visibility(
            visible: employeeDetails['id'] != null &&
                employeeDetails['id'] == employeeId,
            child: IconButton(
              icon: const Icon(Icons.logout),
                            color: whiteColor,
              onPressed: () async {
                await clearToken();
                Navigator.pushNamed(context, '/login');
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
              child: isLoading
                  ? _buildLoadingWidget()
                  : _buildEmployeeDetailsWidget(getToken)),
        ],
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
        durationInMilliSeconds: 500,
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
                Navigator.pushNamed(
                    context, '/employee_checkin_checkout');
              });
              break;
            case 2:
              Future.delayed(const Duration(milliseconds: 1000), () {
                Navigator.pushNamed(context, '/employees_form',
                    arguments: arguments);
              });
              break;
          }
        },
      )
          : null,
    );
  }

  void showUpdateWorkInfoAnimation() {
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
                      "Information Updated Successfully",
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

  void showUpdateBankInfoAnimation() {
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
                      "Information Updated Successfully",
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

  void showUpdatePersonalAnimation() {
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
                      "Information Updated Successfully",
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

  Widget _buildLoadingWidget() {
    final args =
    ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    bool permissionCheck = args?['permission_check'] ?? false;
    bool showWorkTypeAndShiftTab = permissionCheck ||
        (employeeDetails['id'] != null && employeeDetails['id'] == employeeId);
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Column(
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.15,
              alignment: Alignment.topCenter,
              color: redColor,
              child: Padding(
                padding: const EdgeInsets.only(left: 17.0),
                child: SingleChildScrollView(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Shimmer.fromColors(
                        baseColor: grey300,
                        highlightColor: grey100,
                        child: CircleAvatar(
                          radius: 30.0,
                          backgroundColor: whiteColor,
                        ),
                      ),
                      const SizedBox(width: 16.0),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 100,
                            height: 15,
                            color: whiteColor,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 80,
                            height: 15,
                            color: whiteColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(17.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  Transform.translate(
                    offset: const Offset(0, -45.0),
                    child: Column(
                      children: [
                        Shimmer.fromColors(
                          baseColor: grey300,
                          highlightColor: grey100,
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: grey300,
                                ),
                              ],
                              borderRadius: BorderRadius.circular(10.0),
                              border: Border.all(
                                color: grey300,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                                vertical: 4.0, horizontal: 8.0),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 4.0, horizontal: 8.0),
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding:
                                        const EdgeInsets.only(top: 12.0),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  Flexible(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .start,
                                                      children: [
                                                        const Row(
                                                          mainAxisSize:
                                                          MainAxisSize.min,
                                                          children: [
                                                            Padding(
                                                              padding: EdgeInsets
                                                                  .only(
                                                                  right:
                                                                  8.0),
                                                              child: Icon(
                                                                  Icons.email,
                                                                  color: Colors
                                                                      .red,
                                                                  size: 15),
                                                            ),
                                                            Text(
                                                              ' Work Email',
                                                              style: TextStyle(
                                                                fontSize: 15.0,
                                                                fontWeight:
                                                                FontWeight
                                                                    .bold,
                                                                color: Colors
                                                                    .black,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        TextField(
                                                          decoration:
                                                          const InputDecoration(
                                                            icon: Icon(
                                                                Icons.email,
                                                                color: Colors
                                                                    .white,
                                                                size: 13),
                                                            border: InputBorder
                                                                .none,
                                                          ),
                                                          controller:
                                                          workEmailController,
                                                          enabled: false,
                                                          style:
                                                          TextStyle(
                                                            fontSize: 13.0,
                                                            color: blackColor,
                                                          ),
                                                          maxLines: 2,
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                ],
                                              ),
                                            ),
                                            Flexible(
                                              child: Column(
                                                crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisSize:
                                                    MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.phone,
                                                          color: redColor,
                                                          size: 15),
                                                      Text(
                                                        '   Work Phone',
                                                        style: TextStyle(
                                                          fontSize: 15.0,
                                                          fontWeight:
                                                          FontWeight.bold,
                                                          color: blackColor,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  GestureDetector(
                                                    onTap: () {
                                                      _launchDial(
                                                          workPhoneController
                                                              .text);
                                                    },
                                                    child: TextField(
                                                      decoration:
                                                      InputDecoration(
                                                        icon: Icon(Icons.phone,
                                                            color: whiteColor,
                                                            size: 13),
                                                        border:
                                                        InputBorder.none,
                                                      ),
                                                      controller:
                                                      workPhoneController,
                                                      enabled: false,
                                                      style: TextStyle(
                                                        fontSize: 13.0,
                                                        color: infoColor,
                                                      ),
                                                      maxLines: 2,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Flexible(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                    CrossAxisAlignment
                                                        .start,
                                                    children: [
                                                      Row(
                                                        mainAxisSize:
                                                        MainAxisSize.min,
                                                        children: [
                                                          Padding(
                                                            padding:
                                                            EdgeInsets.only(
                                                                right: 8.0),
                                                            child: Icon(
                                                                Icons.email,
                                                                color:
                                                                redColor,
                                                                size: 15),
                                                          ),
                                                          Text(
                                                            ' Email',
                                                            style: TextStyle(
                                                              fontSize: 15.0,
                                                              fontWeight:
                                                              FontWeight
                                                                  .bold,
                                                              color:
                                                              blackColor,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      TextField(
                                                        decoration:
                                                        InputDecoration(
                                                          icon: Icon(
                                                              Icons
                                                                  .email_outlined,
                                                              color:
                                                              whiteColor,
                                                              size: 13),
                                                          border:
                                                          InputBorder.none,
                                                        ),
                                                        controller:
                                                        emailController,
                                                        enabled: false,
                                                        style: TextStyle(
                                                          fontSize: 13.0,
                                                          color: blackColor,
                                                        ),
                                                        maxLines: 2,
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                          Flexible(
                                            child: Column(
                                              crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisSize:
                                                  MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.phone,
                                                        color: redColor,
                                                        size: 15),
                                                    Text(
                                                      '   Phone',
                                                      style: TextStyle(
                                                        fontSize: 15.0,
                                                        fontWeight:
                                                        FontWeight.bold,
                                                        color: blackColor,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                GestureDetector(
                                                  onTap: () {
                                                    _launchDial(
                                                        phoneController.text);
                                                  },
                                                  child: TextField(
                                                    decoration:
                                                    InputDecoration(
                                                      icon: Icon(Icons.phone,
                                                          color: whiteColor,
                                                          size: 13),
                                                      border: InputBorder.none,
                                                    ),
                                                    controller: phoneController,
                                                    enabled: false,
                                                    style: const TextStyle(
                                                      fontSize: 13.0,
                                                      color: Colors.blue,
                                                    ),
                                                    maxLines: 2,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                TabBar(
                                  isScrollable: true,
                                  controller: _tabController,
                                  indicatorColor: redColor,
                                  labelColor: redColor,
                                  unselectedLabelColor: iconSecondaryColor,
                                  labelStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                  tabs: [
                                    const Tab(text: 'About'),
                                    if (showWorkTypeAndShiftTab)
                                      const Tab(text: 'Work Type & Shift'),
                                  ],
                                ),
                                SizedBox(
                                  height:
                                  MediaQuery.of(context).size.height * 0.5,
                                  child: TabBarView(
                                    controller: _tabController,
                                    children: [
                                      Shimmer.fromColors(
                                        baseColor: grey300,
                                        highlightColor: grey100,
                                        child: buildTabContentAbout(
                                          context,
                                          employeeDetails,
                                          employeeWorkInfoRecord,
                                          employeeBankRecord,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeeDetailsWidget(token) {
    final args =
    ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    bool permissionCheck = args?['permission_check'] ?? false;
    bool showWorkTypeAndShiftTab = permissionCheck ||
        (employeeDetails['id'] != null && employeeDetails['id'] == employeeId);
    return Scrollbar(
      controller: _vertical,
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Column(
            children: [
              Container(
                color: redColor,
                alignment: Alignment.topCenter,
                height: MediaQuery.of(context).size.height * 0.15,
                child: Padding(
                  padding: const EdgeInsets.only(left: 17.0),
                  child: SingleChildScrollView(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (isLoadingImage)
                          const CircleAvatar(
                            radius: 30.0,
                            backgroundColor: Colors.transparent,
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else
                          CircleAvatar(
                            radius: 30.0,
                            backgroundColor: Colors.transparent,
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
                                            employeeDetails['employee_profile'],
                                        headers: {
                                          "Authorization": "Bearer $token",
                                        },
                                        fit: BoxFit.cover,
                                        errorBuilder: (BuildContext context,
                                            Object exception,
                                            StackTrace? stackTrace) {
                                          return const Icon(Icons.person);
                                        },
                                      ),
                                    ),
                                  ),
                                if (employeeDetails['employee_profile'] ==
                                    null ||
                                    employeeDetails['employee_profile'].isEmpty)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: disabledColor,
                                      ),
                                      child: const Icon(Icons.person),
                                    ),
                                  ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: InkWell(
                                    onTap: () async {
                                      await _pickImage(employeeDetails['id']);
                                    },
                                    child: CircleAvatar(
                                      radius: 12.0,
                                      backgroundColor: redColor,
                                      child: Icon(
                                        Icons.camera_alt,
                                        size: 12.0,
                                        color: whiteColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(width: 16.0),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              employeeNameController.text,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: whiteColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              badgeController.text,
                              style: TextStyle(
                                fontWeight: FontWeight.normal,
                                fontSize: 12,
                                color: whiteColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(17.0),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    Transform.translate(
                      offset: const Offset(0, -45),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  spreadRadius: 5,
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                              color: whiteColor,
                              borderRadius: BorderRadius.circular(10.0),
                              border: Border.all(
                                color: grey300,
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 4.0, horizontal: 8.0),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12.0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Flexible(
                                                child: Column(
                                                  crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisSize:
                                                      MainAxisSize.min,
                                                      children: [
                                                        Padding(
                                                          padding:
                                                          EdgeInsets.only(
                                                              right: 8.0),
                                                          child: Icon(
                                                              Icons.email,
                                                              color: redColor,
                                                              size: 15),
                                                        ),
                                                        Text(
                                                          ' Work Email',
                                                          style: TextStyle(
                                                            fontSize: 15.0,
                                                            fontWeight:
                                                            FontWeight.bold,
                                                            color: blackColor,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    TextField(
                                                      decoration:
                                                      InputDecoration(
                                                        icon: Icon(Icons.email,
                                                            color: whiteColor,
                                                            size: 13),
                                                        border:
                                                        InputBorder.none,
                                                      ),
                                                      controller:
                                                      workEmailController,
                                                      enabled: false,
                                                      // Adjust as needed
                                                      style: TextStyle(
                                                        fontSize: 13.0,
                                                        color: blackColor,
                                                      ),
                                                      maxLines: 2,
                                                    ),
                                                  ],
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                        Flexible(
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.phone,
                                                      color: redColor,
                                                      size: 15),
                                                  Text(
                                                    '   Work Phone',
                                                    style: TextStyle(
                                                      fontSize: 15.0,
                                                      fontWeight:
                                                      FontWeight.bold,
                                                      color: blackColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              GestureDetector(
                                                onTap: () {
                                                  _launchDial(
                                                      workPhoneController.text);
                                                },
                                                child: TextField(
                                                  decoration:
                                                  InputDecoration(
                                                    icon: Icon(Icons.phone,
                                                        color: whiteColor,
                                                        size: 13),
                                                    border: InputBorder.none,
                                                  ),
                                                  controller:
                                                  workPhoneController,
                                                  enabled: false,
                                                  style: const TextStyle(
                                                    fontSize: 13.0,
                                                    color: Colors.blue,
                                                  ),
                                                  maxLines: 2,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Flexible(
                                              child: Column(
                                                crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisSize:
                                                    MainAxisSize.min,
                                                    children: [
                                                      Padding(
                                                        padding:
                                                        EdgeInsets.only(
                                                            right: 8.0),
                                                        child: Icon(Icons.email,
                                                            color: redColor,
                                                            size: 15),
                                                      ),
                                                      Text(
                                                        ' Email',
                                                        style: TextStyle(
                                                          fontSize: 15.0,
                                                          fontWeight:
                                                          FontWeight.bold,
                                                          color: blackColor,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  TextField(
                                                    decoration:
                                                    InputDecoration(
                                                      icon: Icon(
                                                          Icons.email_outlined,
                                                          color: whiteColor,
                                                          size: 13),
                                                      border: InputBorder.none,
                                                    ),
                                                    controller: emailController,
                                                    enabled: false,
                                                    style: TextStyle(
                                                      fontSize: 13.0,
                                                      color: blackColor,
                                                    ),
                                                    maxLines: 2,
                                                  ),
                                                ],
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                      Flexible(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.phone,
                                                    color: redColor,
                                                    size: 15),
                                                Text(
                                                  '   Phone',
                                                  style: TextStyle(
                                                    fontSize: 15.0,
                                                    fontWeight: FontWeight.bold,
                                                    color: blackColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                _launchDial(
                                                    phoneController.text);
                                              },
                                              child: TextField(
                                                decoration:
                                                InputDecoration(
                                                  icon: Icon(Icons.phone,
                                                      color: whiteColor,
                                                      size: 13),
                                                  border: InputBorder.none,
                                                ),
                                                controller: phoneController,
                                                enabled: false,
                                                style: const TextStyle(
                                                  fontSize: 13.0,
                                                  color: Colors.blue,
                                                ),
                                                maxLines: 2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                TabBar(
                                  isScrollable: true,
                                  controller: _tabController,
                                  labelColor: Colors.red,
                                  indicatorColor: redColor,
                                  unselectedLabelColor: iconSecondaryColor,
                                  labelStyle: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                  tabs: [
                                    const Tab(text: 'About'),
                                    if (showWorkTypeAndShiftTab)
                                      const Tab(text: 'Work Type & Shift'),
                                  ],
                                ),
                                SizedBox(
                                  height:
                                  MediaQuery.of(context).size.height * 0.46,
                                  child: TabBarView(
                                    controller: _tabController,
                                    children: [
                                      buildTabContentAbout(
                                        context,
                                        employeeDetails,
                                        employeeWorkInfoRecord,
                                        employeeBankRecord,
                                      ),
                                      buildTabContentWorkTypeAndShift(
                                        context,
                                        employeeWorkTypeRequest,
                                        employeeWorkTypeRequestCount,
                                        employeeRotatingWorkTypeRequest,
                                        employeeRotatingWorkTypeRequestCount,
                                        employeeShiftRequest,
                                        employeeShiftRequestCount,
                                        employeeRotatingShiftRequest,
                                        employeeRotatingShiftRequestCount,
                                        employeeDetails,
                                        baseUrl,
                                        employeeItems,
                                        employeeIdMap,
                                        workTypeIdMap,
                                        workTypeItem,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
        ],
      ),
    );
  }

  Widget buildTabContentAbout(
      BuildContext context,
      Map<String, dynamic> employeeDetails,
      Map<String, dynamic> employeeWorkInfoRecord,
      Map<String, dynamic> employeeBankRecord) {
    TextEditingController dateOfBirthController = TextEditingController();
    TextEditingController genderController = TextEditingController();
    TextEditingController addressController = TextEditingController();
    TextEditingController countryController = TextEditingController();
    TextEditingController stateController = TextEditingController();
    TextEditingController cityController = TextEditingController();
    TextEditingController qualificationController = TextEditingController();
    TextEditingController experienceController = TextEditingController();
    TextEditingController maritalStatusController = TextEditingController();
    TextEditingController childrenController = TextEditingController();
    TextEditingController emergencyContactController = TextEditingController();
    TextEditingController emergencyContactNameController =
    TextEditingController();
    TextEditingController departmentController = TextEditingController();
    TextEditingController jobPositionController = TextEditingController();
    TextEditingController shiftController = TextEditingController();
    TextEditingController workTypeController = TextEditingController();
    TextEditingController employeeTypeController = TextEditingController();
    TextEditingController salaryController = TextEditingController();
    TextEditingController reportingManagerController = TextEditingController();
    TextEditingController companyController = TextEditingController();
    TextEditingController locationController = TextEditingController();
    TextEditingController joiningDateController = TextEditingController();
    TextEditingController endDateController = TextEditingController();
    TextEditingController tagsController = TextEditingController();
    TextEditingController bankNameController = TextEditingController();
    TextEditingController accountNumberController = TextEditingController();
    TextEditingController branchController = TextEditingController();
    TextEditingController bankAddressController = TextEditingController();
    TextEditingController bankCountryController = TextEditingController();
    TextEditingController bankStateController = TextEditingController();
    var dob = employeeDetails['dob'];
    dateOfBirthController.text = (dob != null && dob.isNotEmpty) ? dob : 'None';
    var gender = employeeDetails['gender'];
    genderController.text =
    (gender != null && gender.isNotEmpty) ? gender : 'None';
    var address = employeeDetails['address'];
    addressController.text =
    (address != null && address.isNotEmpty) ? address : 'None';
    var country = employeeDetails['country'];
    countryController.text =
    (country != null && country.isNotEmpty) ? country : 'None';
    var state = employeeDetails['state'];
    stateController.text = (state != null && state.isNotEmpty) ? state : 'None';
    var city = employeeDetails['city'];
    cityController.text = (city != null && city.isNotEmpty) ? city : 'None';
    var qualification = employeeDetails['qualification'];
    qualificationController.text =
    (qualification != null && qualification.isNotEmpty)
        ? qualification
        : 'None';
    experienceController.text =
        employeeDetails['experience']?.toString() ?? 'None';
    maritalStatusController.text = employeeDetails['marital_status'] ?? 'None';
    childrenController.text = employeeDetails['children']?.toString() ?? 'None';
    var emergencyContact = employeeDetails['emergency_contact'];
    emergencyContactController.text =
    (emergencyContact != null && emergencyContact.isNotEmpty)
        ? emergencyContact
        : 'None';
    var emergencyContactName = employeeDetails['emergency_contact_name'];
    emergencyContactNameController.text =
    (emergencyContactName != null && emergencyContactName.isNotEmpty)
        ? emergencyContactName
        : 'None';
    departmentController.text =
        employeeWorkInfoRecord['department_name'] ?? 'None';
    jobPositionController.text =
        employeeWorkInfoRecord['job_position_name'] ?? 'None';
    shiftController.text = employeeWorkInfoRecord['shift_name'] ?? 'None';
    workTypeController.text =
        employeeWorkInfoRecord['work_type_name'] ?? 'None';
    employeeTypeController.text =
        employeeWorkInfoRecord['employee_type_name'] ?? 'None';
    salaryController.text =
        employeeWorkInfoRecord['basic_salary']?.toString() ?? 'None';
    reportingManagerController.text =
        employeeWorkInfoRecord['reporting_manager_first_name'] ?? 'None';
    companyController.text = employeeWorkInfoRecord['company_name'] ?? 'None';
    locationController.text = employeeWorkInfoRecord['location'] ?? 'None';
    joiningDateController.text =
        employeeWorkInfoRecord['date_joining'] ?? 'None';
    endDateController.text =
        employeeWorkInfoRecord['contract_end_date'] ?? 'None';
    tagsController.text = (employeeWorkInfoRecord['tags'] is List &&
        employeeWorkInfoRecord['tags'].isNotEmpty)
        ? employeeWorkInfoRecord['tags'].join(', ')
        : (employeeWorkInfoRecord['tags']?.toString() ?? 'None');
    bankNameController.text = employeeBankRecord['bank_name'] ?? 'None';
    accountNumberController.text =
        employeeBankRecord['account_number']?.toString() ?? 'None';
    branchController.text = employeeBankRecord['branch'] ?? 'None';
    bankAddressController.text = employeeBankRecord['address'] ?? 'None';
    bankCountryController.text = employeeBankRecord['country'] ?? 'None';
    bankStateController.text = employeeBankRecord['state'] ?? 'None';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.white),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.only(
                  bottom: kBottomNavigationBarHeight + 80.0),
              itemCount: 3,
              itemBuilder: (context, index) {
                String titleText = "";
                IconData? titleIcon;
                switch (index) {
                  case 0:
                    titleText = "Personal Information";
                    titleIcon = Icons.person_outlined;
                    break;
                  case 1:
                    titleText = "Work Information";
                    titleIcon = Icons.work_history_outlined;
                    break;
                  case 2:
                    titleText = "Bank Information";
                    titleIcon = Icons.account_balance;
                    break;
                }
                return Container(
                  padding: const EdgeInsets.all(4.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: ExpansionTile(
                      backgroundColor: Colors.red.shade100,
                      collapsedBackgroundColor: Colors.red.shade50,
                      title: titleIcon != null
                          ? Row(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.0493,
                            child: Icon(titleIcon, color: Colors.red),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              titleText,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      )
                          : Text(titleText),
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (index == 0)
                              Container(
                                color: whiteColor,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: whiteColor,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.5),
                                        spreadRadius: 1,
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(10),
                                      bottomRight: Radius.circular(10),
                                    ),
                                    border: Border.all(
                                      color: grey300,
                                      width: 1,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          children: [
                                            TextField(
                                              decoration: const InputDecoration(
                                                labelText: 'Date of Birth',
                                                labelStyle: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20,
                                                    color: Colors.black),
                                                enabled: false,
                                                border: InputBorder.none,
                                              ),
                                              controller: dateOfBirthController,
                                              maxLines: null,
                                              style: const TextStyle(
                                                  color: Colors.grey),
                                            ),
                                            TextField(
                                              decoration: const InputDecoration(
                                                labelText: 'Gender',
                                                labelStyle: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20,
                                                    color: Colors.black),
                                                enabled: false,
                                                border: InputBorder.none,
                                              ),
                                              controller: genderController,
                                              maxLines: null,
                                              style: const TextStyle(
                                                  color: Colors.grey),
                                            ),
                                            TextField(
                                              decoration: const InputDecoration(
                                                labelText: 'Address',
                                                labelStyle: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20,
                                                    color: Colors.black),
                                                enabled: false,
                                                border: InputBorder.none,
                                              ),
                                              controller: addressController,
                                              maxLines: null,
                                              style: const TextStyle(
                                                  color: Colors.grey),
                                            ),
                                            TextField(
                                              decoration: const InputDecoration(
                                                labelText: 'Country',
                                                labelStyle: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20,
                                                    color: Colors.black),
                                                enabled: false,
                                                border: InputBorder.none,
                                              ),
                                              controller: countryController,
                                              maxLines: null,
                                              style: const TextStyle(
                                                  color: Colors.grey),
                                            ),
                                            TextField(
                                              decoration: const InputDecoration(
                                                labelText: 'State',
                                                labelStyle: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20,
                                                    color: Colors.black),
                                                enabled: false,
                                                border: InputBorder.none,
                                              ),
                                              controller: stateController,
                                              maxLines: null,
                                              style: const TextStyle(
                                                  color: Colors.grey),
                                            ),
                                            TextField(
                                              decoration: const InputDecoration(
                                                labelText: 'City',
                                                labelStyle: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20,
                                                    color: Colors.black),
                                                enabled: false,
                                                border: InputBorder.none,
                                              ),
                                              controller: cityController,
                                              maxLines: null,
                                              style: const TextStyle(
                                                  color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          children: [
                                            TextField(
                                              decoration: const InputDecoration(
                                                labelText: 'Qualification',
                                                labelStyle: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20,
                                                    color: Colors.black),
                                                enabled: false,
                                                border: InputBorder.none,
                                              ),
                                              controller:
                                              qualificationController,
                                              maxLines: null,
                                              style: const TextStyle(
                                                  color: Colors.grey),
                                            ),
                                            TextField(
                                              decoration: const InputDecoration(
                                                labelText: 'Experience',
                                                labelStyle: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20,
                                                    color: Colors.black),
                                                enabled: false,
                                                border: InputBorder.none,
                                              ),
                                              controller: experienceController,
                                              maxLines: null,
                                              style: const TextStyle(
                                                  color: Colors.grey),
                                            ),
                                            TextField(
                                              decoration: const InputDecoration(
                                                labelText: 'Marital Status',
                                                labelStyle: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20,
                                                    color: Colors.black),
                                                enabled: false,
                                                border: InputBorder.none,
                                              ),
                                              controller:
                                              maritalStatusController,
                                              maxLines: null,
                                              style: const TextStyle(
                                                  color: Colors.grey),
                                            ),
                                            TextField(
                                              decoration: const InputDecoration(
                                                labelText: 'Children',
                                                labelStyle: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20,
                                                    color: Colors.black),
                                                enabled: false,
                                                border: InputBorder.none,
                                              ),
                                              controller: childrenController,
                                              maxLines: null,
                                              style: const TextStyle(
                                                  color: Colors.grey),
                                            ),
                                            TextField(
                                              decoration: const InputDecoration(
                                                labelText: 'Emergency Contact',
                                                labelStyle: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20,
                                                    color: Colors.black),
                                                enabled: false,
                                                border: InputBorder.none,
                                              ),
                                              controller:
                                              emergencyContactController,
                                              maxLines: null,
                                              style: const TextStyle(
                                                  color: Colors.grey),
                                            ),
                                            TextField(
                                              decoration: InputDecoration(
                                                labelText: 'Contact Name',
                                                labelStyle: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 20,
                                                  color: blackColor,
                                                ),
                                                enabled: false,
                                                border: InputBorder.none,
                                              ),
                                              controller:
                                              emergencyContactNameController,
                                              maxLines: null,
                                              style: const TextStyle(
                                                  color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (index == 1)
                              Container(
                                color: whiteColor,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: whiteColor,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.5),
                                        spreadRadius: 1,
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(10),
                                      bottomRight: Radius.circular(10),
                                    ),
                                    border: Border.all(
                                      color: grey300,
                                      width: 1,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          children: [
                                            TextField(
                                              decoration: const InputDecoration(
                                                labelText: 'Department',
                                                labelStyle: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20,
                                                    color: Colors.black),
                                                enabled: false,
                                                border: InputBorder.none,
                                              ),
                                              controller: departmentController,
                                              maxLines: null,
                                              style: const TextStyle(
                                                  color: Colors.grey),
                                            ),
                                            TextField(
                                              decoration: const InputDecoration(
                                                labelText: 'Job Position',
                                                labelStyle: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20,
                                                    color: Colors.black),
                                                enabled: false,
                                                border: InputBorder.none,
                                              ),
                                              controller: jobPositionController,
                                              maxLines: null,
                                              style: const TextStyle(
                                                  color: Colors.grey),
                                            ),
                                            TextField(
                                              decoration: const InputDecoration(
                                                labelText: 'Shift Information',
                                                labelStyle: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20,
                                                    color: Colors.black),
                                                enabled: false,
                                                border: InputBorder.none,
                                              ),
                                              controller: shiftController,
                                              maxLines: null,
                                              style: const TextStyle(
                                                  color: Colors.grey),
                                            ),
                                            TextField(
                                              decoration: const InputDecoration(
                                                labelText: 'Work Type',
                                                // Original label text
                                                labelStyle: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20,
                                                    color: Colors.black),
                                                enabled: false,
                                                border: InputBorder.none,
                                              ),
                                              controller: workTypeController,
                                              maxLines: null,
                                              style: const TextStyle(
                                                  color: Colors.grey),
                                            ),
                                            TextField(
                                              decoration: const InputDecoration(
                                                labelText: 'Employee Type',
                                                labelStyle: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20,
                                                    color: Colors.black),
                                                enabled: false,
                                                border: InputBorder.none,
                                              ),
                                              controller:
                                              employeeTypeController,
                                              maxLines: null,
                                              style: const TextStyle(
                                                  color: Colors.grey),
                                            ),
                                            TextField(
                                              decoration: const InputDecoration(
                                                labelText: 'Salary',
                                                // Original label text
                                                labelStyle: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20,
                                                    color: Colors.black),
                                                enabled: false,
                                                border: InputBorder.none,
                                              ),
                                              controller: salaryController,
                                              maxLines: null,
                                              style: const TextStyle(
                                                  color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          children: [
                                            TextField(
                                              decoration: const InputDecoration(
                                                labelText: 'Reporting Manager',
                                                labelStyle: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20,
                                                    color: Colors.black),
                                                enabled: false,
                                                border: InputBorder.none,
                                              ),
                                              controller:
                                              reportingManagerController,
                                              maxLines: null,
                                              style: const TextStyle(
                                                  color: Colors.grey),
                                            ),
                                            TextField(
                                              decoration: const InputDecoration(
                                                labelText: 'Company',
                                                labelStyle: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20,
                                                    color: Colors.black),
                                                enabled: false,
                                                border: InputBorder.none,
                                              ),
                                              controller: companyController,
                                              maxLines: null,
                                              style: const TextStyle(
                                                  color: Colors.grey),
                                            ),
                                            TextField(
                                              decoration: const InputDecoration(
                                                labelText: 'Work Location',
                                                labelStyle: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20,
                                                    color: Colors.black),
                                                enabled: false,
                                                border: InputBorder.none,
                                              ),
                                              controller: locationController,
                                              maxLines: null,
                                              style: const TextStyle(
                                                  color: Colors.grey),
                                            ),
                                            TextField(
                                              decoration: const InputDecoration(
                                                labelText: 'Joining Date',
                                                labelStyle: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20,
                                                    color: Colors.black),
                                                enabled: false,
                                                border: InputBorder.none,
                                              ),
                                              controller: joiningDateController,
                                              maxLines: null,
                                              style: const TextStyle(
                                                  color: Colors.grey),
                                            ),
                                            TextField(
                                              decoration: const InputDecoration(
                                                labelText: 'End Date',
                                                labelStyle: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20,
                                                    color: Colors.black),
                                                enabled: false,
                                                border: InputBorder.none,
                                              ),
                                              controller: endDateController,
                                              maxLines: null,
                                              style: const TextStyle(
                                                  color: Colors.grey),
                                            ),
                                            TextField(
                                              decoration: const InputDecoration(
                                                labelText: 'Tags',
                                                labelStyle: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20,
                                                    color: Colors.black),
                                                enabled: false,
                                                border: InputBorder.none,
                                              ),
                                              controller: tagsController,
                                              maxLines: null,
                                              style: const TextStyle(
                                                  color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (index == 2)
                              Container(
                                color: whiteColor,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: whiteColor,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.5),
                                        spreadRadius: 1,
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(10),
                                      bottomRight: Radius.circular(10),
                                    ),
                                    border: Border.all(
                                      color: grey300,
                                      width: 1,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          children: [
                                            TextField(
                                              decoration: InputDecoration(
                                                labelText: 'Bank Name',
                                                labelStyle: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 20,
                                                  color: blackColor,
                                                ),
                                                border: InputBorder.none,
                                              ),
                                              controller: bankNameController,
                                              readOnly: true,
                                              maxLines: null,
                                              style: const TextStyle(
                                                  color: Colors.grey),
                                            ),
                                            TextField(
                                              decoration: const InputDecoration(
                                                labelText: 'Account Number',
                                                labelStyle: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20,
                                                    color: Colors.black),
                                                enabled: false,
                                                border: InputBorder.none,
                                              ),
                                              controller:
                                              accountNumberController,
                                              maxLines: null,
                                              style: const TextStyle(
                                                  color: Colors.grey),
                                            ),
                                            TextField(
                                              decoration: const InputDecoration(
                                                labelText: 'Branch',
                                                labelStyle: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20,
                                                    color: Colors.black),
                                                enabled: false,
                                                border: InputBorder.none,
                                              ),
                                              controller: branchController,
                                              maxLines: null,
                                              style: const TextStyle(
                                                  color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          children: [
                                            TextField(
                                              decoration: const InputDecoration(
                                                labelText: 'Bank Address',
                                                labelStyle: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20,
                                                    color: Colors.black),
                                                enabled: false,
                                                border: InputBorder.none,
                                              ),
                                              controller: bankAddressController,
                                              maxLines: null,
                                              style: const TextStyle(
                                                  color: Colors.grey),
                                            ),
                                            TextField(
                                              decoration: const InputDecoration(
                                                labelText: 'Country',
                                                labelStyle: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20,
                                                    color: Colors.black),
                                                enabled: false,
                                                border: InputBorder.none,
                                              ),
                                              controller: countryController,
                                              maxLines: null,
                                              style: const TextStyle(
                                                  color: Colors.grey),
                                            ),
                                            TextField(
                                              decoration: const InputDecoration(
                                                labelText: 'State',
                                                labelStyle: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20,
                                                    color: Colors.black),
                                                enabled: false,
                                                border: InputBorder.none,
                                              ),
                                              controller: stateController,
                                              maxLines: null,
                                              style: const TextStyle(
                                                  color: Colors.grey),
                                            ),
                                          ],
                                        ),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTabContentWorkTypeAndShift(
      BuildContext context,
      List<dynamic> employeeWorkTypeRequest,
      employeeWorkTypeRequestCount,
      List<dynamic> employeeRotatingWorkTypeRequest,
      employeeRotatingWorkTypeRequestCount,
      List<dynamic> employeeShiftRequest,
      employeeShiftRequestCount,
      List<dynamic> employeeRotatingShiftRequest,
      employeeRotatingShiftRequestCount,
      Map<String, dynamic> employeeDetails,
      baseUrl,
      employeeItems,
      employeeIdMap,
      workTypeIdMap,
      workTypeItems) {
    final firstName = employeeDetails['employee_first_name'] ?? '';
    final lastName = employeeDetails['employee_last_name'] ?? '';
    final fullName = (firstName.isEmpty ? '' : firstName) +
        (lastName.isEmpty ? '' : ' $lastName');
    final employeeId = employeeDetails['id'].toString();
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: ListView(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WorkTypeRequestPage(
                      selectedEmployerId: employeeId,
                      selectedEmployeeFullName: fullName),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: 15.0),
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Work Type Request',
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: blackColor,
                          ),
                          enabled: false,
                          border: InputBorder.none,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width * 0.07,
                            height: MediaQuery.of(context).size.height * 0.03,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.redAccent,
                            ),
                            child: Center(
                              child: Text(
                                employeeWorkTypeRequestCount.toString(),
                                style: TextStyle(
                                  color: whiteColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Icon(Icons.arrow_forward_ios,
                            color: grey600, size: 16),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RotatingWorkTypePage(
                      selectedEmployerId: employeeId,
                      selectedEmployeeFullName: fullName),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: 15.0),
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Rotating Work Type',
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: blackColor,
                          ),
                          enabled: false,
                          border: InputBorder.none,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width * 0.07,
                            height: MediaQuery.of(context).size.height * 0.03,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.redAccent,
                            ),
                            child: Center(
                              child: Text(
                                employeeRotatingWorkTypeRequestCount.toString(),
                                style: TextStyle(
                                  color: whiteColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Icon(Icons.arrow_forward_ios,
                            color: grey600, size: 16),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ShiftRequestPage(
                      selectedEmployerId: employeeId,
                      selectedEmployeeFullName: fullName),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: 15.0),
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Shift Request',
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            // fontSize: 15,
                            color: blackColor,
                          ),
                          enabled: false,
                          border: InputBorder.none,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width * 0.07,
                            height: MediaQuery.of(context).size.height * 0.03,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.redAccent,
                            ),
                            child: Center(
                              child: Text(
                                employeeShiftRequestCount.toString(),
                                style: TextStyle(
                                  color: whiteColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Icon(Icons.arrow_forward_ios,
                            color: grey600, size: 16),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RotatingShiftPage(
                      selectedEmployerId: employeeId,
                      selectedEmployeeFullName: fullName),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: 15.0),
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Rotating Shift',
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            // fontSize: 15,
                            color: blackColor,
                          ),
                          enabled: false,
                          border: InputBorder.none,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width * 0.07,
                            height: MediaQuery.of(context).size.height * 0.03,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.redAccent,
                            ),
                            child: Center(
                              child: Text(
                                employeeRotatingShiftRequestCount.toString(),
                                style: TextStyle(
                                  color: whiteColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Icon(Icons.arrow_forward_ios,
                            color: grey600, size: 16),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            child: Container(
              decoration: BoxDecoration(
                color: whiteColor,
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            child: Container(
              height: MediaQuery.of(context).size.height * 0.15,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: whiteColor,
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
          const SizedBox(height: 15),
          GestureDetector(
            child: Container(
              height: MediaQuery.of(context).size.height * 0.15,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: whiteColor,
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _launchDial(String phoneNumber) async {
    if (await canLaunch('tel:$phoneNumber')) {
      await launch('tel:$phoneNumber');
    } else {
      throw 'Could not launch $phoneNumber';
    }
  }

  Widget buildTabContentAttendance() {
    return Container();
  }
}