import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../res/consts/app_colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  StreamSubscription? subscription;
  var isDeviceConnected = false;
  bool isAlertSet = false;
  bool _passwordVisible = false;
  final TextEditingController serverController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  double horizontalMargin = 0.0;
  Timer? _notificationTimer;
  String? _serverError;
  String? _usernameError;
  String? _passwordError;
  bool _isLoading = false;


  @override
  void initState() {
    super.initState();
    getConnectivity();

    // Clear errors when user starts typing
    serverController.addListener(() {
      if (_serverError != null) {
        setState(() {
          _serverError = null;
        });
      }
    });
    usernameController.addListener(() {
      if (_usernameError != null) {
        setState(() {
          _usernameError = null;
        });
      }
    });
    passwordController.addListener(() {
      if (_passwordError != null) {
        setState(() {
          _passwordError = null;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      double screenWidth = MediaQuery.of(context).size.width;
      setState(() {
        horizontalMargin = screenWidth * 0.1;
      });
    });
  }

  void _startNotificationTimer() {
    _notificationTimer?.cancel();
    _notificationTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      if (isAuthenticated) {
        fetchNotifications();
        unreadNotificationsCount();
      } else {
        timer.cancel();
        _notificationTimer = null;
      }
    });
  }



  Future<void> _login() async {
    // Clear previous errors and set loading state
    setState(() {
      _serverError = null;
      _usernameError = null;
      _passwordError = null;
      _isLoading = true;
    });

    String serverAddress = serverController.text.trim();
    String username = usernameController.text.trim();
    String password = passwordController.text.trim();

    // Validate empty fields
    bool hasError = false;
    if (serverAddress.isEmpty) {
      setState(() {
        _serverError = 'Server address is required';
      });
      hasError = true;
    }
    if (username.isEmpty) {
      setState(() {
        _usernameError = 'Email is required';
      });
      hasError = true;
    }
    if (password.isEmpty) {
      setState(() {
        _passwordError = 'Password is required';
      });
      hasError = true;
    }

    if (hasError) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Ensure server address has a scheme (http:// or https://)
    if (!serverAddress.startsWith('http://') && !serverAddress.startsWith('https://')) {
      // For local development, default to http://
      serverAddress = 'http://$serverAddress';
    }

    // Remove trailing slash if present
    if (serverAddress.endsWith('/')) {
      serverAddress = serverAddress.substring(0, serverAddress.length - 1);
    }

    String url = '$serverAddress/api/auth/login/';

    print('Attempting login to: $url'); // Debug log

    try {
      // Send JSON body with proper headers to avoid CORS issues
      http.Response response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      ).timeout(Duration(seconds: 10));

      print('Login response status: ${response.statusCode}'); // Debug log
      print('Login response headers: ${response.headers}'); // Debug log
      if (response.statusCode != 200) {
        print('Login response body: ${response.body}'); // Debug log
      }

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);

        var token = responseBody['access'] ?? '';

        var employeeId = responseBody['employee']?['id'] ?? 0;
        var companyId = responseBody['company_id'] ?? 0;
        bool face_detection = responseBody['face_detection'] ?? false;
        bool geo_fencing = responseBody['geo_fencing'] ?? false;
        var face_detection_image = responseBody['face_detection_image']?.toString() ?? '';


        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", token);
        await prefs.setString("typed_url", serverAddress);
        await prefs.setString("face_detection_image", face_detection_image);
        await prefs.setBool("face_detection", face_detection);
        await prefs.setBool("geo_fencing", geo_fencing);
        await prefs.setInt("employee_id", employeeId);
        await prefs.setInt("company_id", companyId);

        isAuthenticated = true;
        _startNotificationTimer();
        prefetchData();

        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // Try to parse error message from response
        String errorMessage = 'Invalid email or password';
        try {
          final errorBody = jsonDecode(response.body);
          errorMessage = errorBody['detail'] ?? 
                        errorBody['message'] ?? 
                        errorBody['error'] ?? 
                        'Invalid email or password';
        } catch (e) {
          // If parsing fails, use default message
        }
        
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on TimeoutException {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connection timeout. Please check your server address and try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      print('Login error: $e'); // Debug log
      String errorMessage = 'Connection failed';
      if (e.toString().contains('CORS')) {
        errorMessage = 'CORS error: Please ensure the server allows requests from this app';
      } else if (e.toString().contains('Failed host lookup')) {
        errorMessage = 'Cannot reach server. Please check the server address.';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'Network error. Please check your connection and server address.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }


  void getConnectivity() {
    // subscription = InternetConnectionChecker().onStatusChange.listen((status) {
    //   setState(() {
    //     isDeviceConnected = status == InternetConnectionStatus.connected;
    //   });
    // });
  }

  @override
  Widget build(BuildContext context) {
    final String? serverAddress =
    ModalRoute.of(context)?.settings.arguments as String?;

    if (serverAddress != null && serverController.text.isEmpty) {
      serverController.text = serverAddress;
    }

    return WillPopScope(
      onWillPop: () async {
        SystemNavigator.pop();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height * 0.42,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  color: Colors.red,
                ),
                alignment: Alignment.bottomCenter,
                child: Center(
                  child: ClipOval(
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(10, 5, 10, 15),
                      child: Image.asset(
                        'Assets/horilla-logo.png',
                        height: MediaQuery.of(context).size.height * 0.11,
                        width: MediaQuery.of(context).size.height * 0.11,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SingleChildScrollView(
              physics: ClampingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).size.height * 0.3,
                  left: horizontalMargin,
                  right: horizontalMargin,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: grey300),
                        borderRadius: BorderRadius.circular(20.0),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: <Widget>[
                          const Text(
                            'Sign In',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                          _buildTextFormField(
                            'Server Address',
                            serverController,
                            false,
                            errorText: _serverError,
                            enabled: !_isLoading,
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                          _buildTextFormField(
                            'Email',
                            usernameController,
                            false,
                            errorText: _usernameError,
                            enabled: !_isLoading,
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                          _buildTextFormField(
                            'Password',
                            passwordController,
                            true,
                            passwordVisible: _passwordVisible,
                            togglePasswordVisibility: () {
                              setState(() {
                                _passwordVisible = !_passwordVisible;
                              });
                            },
                            errorText: _passwordError,
                            enabled: !_isLoading,
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height * 0.04),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                foregroundColor: whiteColor,
                                backgroundColor: redColor,
                                disabledBackgroundColor: redColor.withOpacity(0.6),
                                disabledForegroundColor: whiteColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10.0),
                                child: _isLoading
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(whiteColor),
                                        ),
                                      )
                                    : const Text(
                                        'Sign In',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField(
      String label,
      TextEditingController controller,
      bool isPassword, {
        bool? passwordVisible,
        VoidCallback? togglePasswordVisibility,
        String? errorText,
        bool enabled = true,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.005),
        TextFormField(
          controller: controller,
          enabled: enabled,
          obscureText: isPassword ? !(passwordVisible ?? false) : false,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderSide: BorderSide(
                width: 1,
                color: errorText != null ? Colors.red : grey300,
              ),
              borderRadius: BorderRadius.circular(8.0),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: const BorderSide(width: 1, color: Colors.red),
              borderRadius: BorderRadius.circular(8.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: const BorderSide(width: 2, color: Colors.red),
              borderRadius: BorderRadius.circular(8.0),
            ),
            contentPadding: EdgeInsets.symmetric(
              vertical: MediaQuery.of(context).size.height * 0.015,
              horizontal: controller.text.isNotEmpty ? 16.0 : 12.0,
            ),
            suffixIcon: isPassword
                ? IconButton(
              icon: Icon(
                passwordVisible! ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey,
              ),
              onPressed: togglePasswordVisibility,
            )
                : null,
          ),
        ),
        if (errorText != null) ...[
          SizedBox(height: MediaQuery.of(context).size.height * 0.005),
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Text(
              errorText,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    subscription?.cancel();
    serverController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    _notificationTimer?.cancel();
    super.dispose();
  }
}
