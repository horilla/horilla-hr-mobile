import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:shimmer/shimmer.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../res/consts/app_colors.dart';

class EmployeeListPage extends StatefulWidget {
  const EmployeeListPage({super.key});

  @override
  _EmployeeListPageState createState() => _EmployeeListPageState();
}

class StateInfo {
  final Color color;
  final String displayString;

  StateInfo(this.color, this.displayString);
}

class _EmployeeListPageState extends State<EmployeeListPage> {
  List<Map<String, dynamic>> requests = [];
  String searchText = '';
  List<dynamic> filteredRecords = [];
  final ScrollController _scrollController = ScrollController();
  final List<Widget> bottomBarPages = [];
  final _pageController = PageController(initialPage: 0);
  final _controller = NotchBottomBarController(index: -1);
  int currentPage = 1;
  int requestsCount = 0;
  int maxCount = 5;
  late Map<String, dynamic> arguments;
  late String baseUrl = '';
  late String getToken = '';
  bool isLoading = true;
  bool _isShimmer = true;
  bool hasMore = true;
  bool hasNoMore = false;
  String nextPage = '';

  @override
  void initState() {
    super.initState();
    _simulateLoading();
    _scrollController.addListener(_scrollListener);
    prefetchData();
    getEmployeeDetails();
    getBaseUrl();
    fetchToken();
  }

  void _scrollListener() {
    if (_scrollController.offset >=
        _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange) {
      currentPage++;
      getEmployeeDetails();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
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

  Future<void> fetchToken() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    setState(() {
      getToken = token ?? '';
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

  Future<void> _simulateLoading() async {
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isShimmer = false;
    });
  }

  Future<void> getEmployeeDetails() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse(
        '$typedServerUrl/api/employee/list/employees?page=$currentPage&search=$searchText');
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
        nextPage = jsonDecode(response.body)['next'] ?? '';
      });
    } else {
      hasNoMore = true;
    }
  }

  List<dynamic> filterRecords(String searchText) {
    List<dynamic> allRecords = requests;
    List<dynamic> filteredRecords = allRecords.where((record) {
      final firstName = record['employee_first_name'] ?? '';
      final lastName = record['employee_last_name'] ?? '';
      final fullName = (firstName + ' ' + lastName).toLowerCase();
      final jobPosition = record['job_position_name'] ?? '';
      return fullName.contains(searchText.toLowerCase()) ||
          jobPosition.toLowerCase().contains(searchText.toLowerCase());
    }).toList();

    return filteredRecords;
  }

  Color _getColorForPosition(String position) {
    int hashCode = position.hashCode;
    return Color((hashCode & 0xFFFFFF).toInt()).withOpacity(1.0);
  }

  Widget buildListItem(Map<String, dynamic> record, baseUrl, token) {
    String position = record['job_position_name'] ?? 'Unknown';
    Color positionColor = _getColorForPosition(position);
    return Column(
      children: [
        ListTile(
          onTap: () {
            final args = ModalRoute.of(context)?.settings.arguments;
            Navigator.pushNamed(context, '/employees_form', arguments: {
              'employee_id': record['id'],
              'employee_name': record['employee_first_name'] +
                  ' ' +
                  record['employee_last_name'],
              'permission_check': args,
            });
          },
          leading: CircleAvatar(
            radius: 20.0,
            backgroundColor: Colors.transparent,
            child: Stack(
              children: [
                if (record['employee_profile'] != null &&
                    record['employee_profile'].isNotEmpty)
                  Positioned.fill(
                    child: ClipOval(
                      child: Image.network(
                        baseUrl + record['employee_profile'],
                        headers: {
                          "Authorization": "Bearer $token",
                        },
                        fit: BoxFit.cover,
                        errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                          return const Icon(Icons.person);
                        },
                      ),
                    ),
                  ),
                if (record['employee_profile'] == null ||
                    record['employee_profile'].isEmpty)
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
          title: Text(
            record['employee_first_name'] +
                ' ' +
                (record['employee_last_name'] ?? ''),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15.0,
            ),
          ),
          subtitle: Text(
            record['email'],
            style: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 12.0,
              color: Colors.grey,
            ),
          ),
          trailing: SizedBox(
            width: 150,
            child: Row(
              children: [
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      width: 100,
                      height: 25,
                      padding: const EdgeInsets.fromLTRB(10.0, 1.0, 10.0, 1.0),
                      decoration: BoxDecoration(
                        color: positionColor.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Center(
                        child: Text(
                          position,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.0,
                            color: positionColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(Icons.keyboard_arrow_right),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          // Adjust padding as needed
          child: Divider(height: 1.0, color: Colors.grey[300]),
        ),
      ],
    );
  }

  Future<void> loadMoreData() async {
    currentPage++;
    await getEmployeeDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text('Employees', style: TextStyle(color: Colors.black)),
        actions: const [],
      ),
      body: Stack(
        children: [
          Center(
            child: isLoading
                ? Column(
              children: [
                const SizedBox(height: 5),
                Padding(
                  padding: MediaQuery.of(context).size.width > 600
                      ? const EdgeInsets.all(20.0)
                      : const EdgeInsets.all(15.0),
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
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: TextField(
                                enabled: false,
                                decoration: InputDecoration(
                                  hintText: 'Loading...',
                                  hintStyle: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 14),
                                  border: OutlineInputBorder(
                                    borderRadius:
                                    BorderRadius.circular(8.0),
                                    borderSide: BorderSide.none,
                                  ),
                                  prefixIcon: Transform.scale(
                                    scale: 0.8,
                                    child: Icon(Icons.search,
                                        color: Colors.grey.shade400),
                                  ),
                                  contentPadding:
                                  const EdgeInsets.symmetric(
                                      vertical: 12.0,
                                      horizontal: 4.0),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                ),
                                style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade400),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ListView.builder(
                      itemCount: 6,
                      itemBuilder: (context, index) {
                        return Shimmer.fromColors(
                          baseColor: grey300,
                          highlightColor: grey100,
                          child: Card(
                            margin:
                            const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              title: Container(
                                height: 20,
                                color: Colors.grey[300],
                              ),
                              subtitle: Container(
                                height: 16,
                                color: Colors.grey[200],
                                margin: const EdgeInsets.only(top: 8.0),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            )
                : Column(
              children: [
                const SizedBox(height: 5),
                Padding(
                  padding: MediaQuery.of(context).size.width > 600
                      ? const EdgeInsets.all(20.0)
                      : const EdgeInsets.all(15.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Card(
                          margin: const EdgeInsets.all(8),
                          elevation: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              border:
                              Border.all(color: Colors.grey.shade50),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: TextField(
                              onChanged: (employeeSearchValue) {
                                setState(() {
                                  searchText = employeeSearchValue;
                                  getEmployeeDetails();
                                });
                              },
                              decoration: InputDecoration(
                                hintText: 'Search',
                                border: OutlineInputBorder(
                                  borderRadius:
                                  BorderRadius.circular(8.0),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: Transform.scale(
                                  scale: 0.8,
                                  child: Icon(Icons.search,
                                      color: Colors.blueGrey.shade300),
                                ),
                                contentPadding:
                                const EdgeInsets.symmetric(
                                    vertical: 12.0, horizontal: 4.0),
                                hintStyle: TextStyle(
                                    color: Colors.blueGrey.shade300,
                                    fontSize: 14),
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
                if (requestsCount == 0)
                  const Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search,
                            color: Colors.black,
                            size: 92,
                          ),
                          SizedBox(height: 20),
                          Text(
                            "There are no employee records to display",
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
                            ? requests.length + (hasMore ? 1 : 0)
                            : filteredRecords.length,
                        itemBuilder: (context, index) {
                          if (index == requests.length &&
                              searchText.isEmpty &&
                              hasMore) {
                            return Column(
                              children: [
                                if (nextPage != '')
                                  Center(
                                    child: ListTile(
                                      title: LoadingAnimationWidget
                                          .bouncingBall(
                                        size: 25,
                                        color: Colors.grey,
                                      ),
                                      onTap: () {
                                        setState(() {
                                          loadMoreData();
                                        });
                                      },
                                    ),
                                  ),
                              ],
                            );
                          }

                          final record = searchText.isEmpty
                              ? requests[index]
                              : filteredRecords[index];
                          return buildListItem(record, baseUrl, getToken);
                        },
                      ),
                    ),
                  ),
              ],
            ),
          )
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
