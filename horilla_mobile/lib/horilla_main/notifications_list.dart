import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../res/consts/app_colors.dart';

class NotificationsList extends StatefulWidget {
  const NotificationsList({super.key});

  @override
  _NotificationsListState createState() => _NotificationsListState();
}

class _NotificationsListState extends State<NotificationsList> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;
  late Map<String, dynamic> arguments = {};
  final ScrollController _scrollController = ScrollController();
  int currentPage = 1;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    prefetchData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchNotifications();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset >=
        _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange) {
      currentPage++;
      fetchNotifications();
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
      setState(() {
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
          'employee_profile': responseData['employee_profile'],
          'job_position_name': responseData['job_position_name']
        };
      });
    }
  }

  Future<void> fetchNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    if (currentPage != 0) {
      var uri = Uri.parse(
          '$typedServerUrl/api/notifications/notifications/list/all?page=$currentPage');
      var response = await http.get(uri, headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });

      if (response.statusCode == 200) {
        setState(() {
          notifications.addAll(
            List<Map<String, dynamic>>.from(
              jsonDecode(response.body)['results']
                  .where((notification) => notification['deleted'] == false)
                  .toList(),
            ),
          );
          String serializeMap(Map<String, dynamic> map) {
            return jsonEncode(map);
          }

          Map<String, dynamic> deserializeMap(String jsonString) {
            return jsonDecode(jsonString);
          }

          List<String> mapStrings = notifications.map(serializeMap).toList();
          Set<String> uniqueMapStrings = mapStrings.toSet();
          notifications = uniqueMapStrings.map(deserializeMap).toList();

          isLoading = false;
        });
      }
    } else {
      currentPage = 1;
      var uri =
      Uri.parse('$typedServerUrl/api/notifications/notifications/list/all');
      var response = await http.get(uri, headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });

      if (response.statusCode == 200) {
        setState(() {
          notifications.addAll(
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

          List<String> mapStrings = notifications.map(serializeMap).toList();
          Set<String> uniqueMapStrings = mapStrings.toSet();
          notifications = uniqueMapStrings.map(deserializeMap).toList();

          isLoading = false;
        });
      }
    }
  }

  Future<void> clearAllNotification() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse(
        '$typedServerUrl/api/notifications/notifications/bulk-delete/');
    var response = await http.delete(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      setState(() {
        notifications.clear();
        fetchNotifications();
      });
    }
  }

  Future<void> deleteIndividualNotification(int notificationId) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse(
        '$typedServerUrl/api/notifications/notifications/$notificationId/');
    var response = await http.delete(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      notifications.removeWhere((item) => item['id'] == notificationId);
      fetchNotifications();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title:
        const Text('Notifications', style: TextStyle(color: Colors.black)),
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            // padding: const EdgeInsets.all(8.0),
            padding: const EdgeInsets.all(12.0),

            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  clearAllNotification();
                });
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
                'Clear all',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.0357),
        child: Center(
          child: isLoading
              ? Shimmer.fromColors(
            baseColor: grey300,
            highlightColor: grey100,
            child: ListView.builder(
              itemCount: 20,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width * 0.05,
                        height: MediaQuery.of(context).size.height * 0.02,
                        decoration: BoxDecoration(
                          color: grey300,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 16.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              height: 12.0,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 8.0),
                            Container(
                              width:
                              MediaQuery.of(context).size.width * 0.4,
                              height: 12.0,
                              color: Colors.grey[300],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
              : notifications.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.notifications,
                  color: Colors.black,
                  size: 92,
                ),
                const SizedBox(height: 20),
                Text(
                  "There are no notification records to display",
                  style: TextStyle(
                      fontSize:
                      MediaQuery.of(context).size.width * 0.0357,
                      color: Colors.black,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )
              : ListView.builder(
            controller: _scrollController,
            // shrinkWrap: true,
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final record = notifications[index];
              if (record['verb'] != null) {
                return buildListItem(context, record, index);
              } else {
                return Container();
              }
            },
          ),
        ),
      ),
    );
  }

  Widget buildListItem(
      BuildContext context, Map<String, dynamic> record, int index) {
    final timestamp = DateTime.parse(record['timestamp']);
    final timeAgo = timeago.format(timestamp);
    final user = arguments['employee_name'];

    return Padding(
      padding: const EdgeInsets.all(0.0),
      child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            color: Colors.white,
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.0357,
                  vertical: 2.0,
                ),
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (record['unread'] == true)
                      Container(
                        width: MediaQuery.of(context).size.width * 0.05,
                        height: MediaQuery.of(context).size.height * 0.02,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.circle,
                          color: Colors.red,
                          size: 17,
                        ),
                      ),
                    if (record['unread'] == false)
                      Container(
                        width: MediaQuery.of(context).size.width * 0.05,
                        height: MediaQuery.of(context).size.height * 0.02,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                title: Text(
                  record['verb'],
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.035,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                subtitle: Text(
                  '$timeAgo by User $user',
                  style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.035,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade400),
                ),
                trailing: IconButton(
                  icon: Icon(
                    Icons.close,
                    size: MediaQuery.of(context).size.width * 0.04,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      var notificationId = record['id'];
                      deleteIndividualNotification(notificationId);
                    });
                  },
                ),
              ),
              Divider(height: 1.0, color: Colors.grey[400]?.withOpacity(0.2))
            ],
          )),
    );
  }
}
