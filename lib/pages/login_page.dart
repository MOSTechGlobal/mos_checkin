import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/theme_bloc.dart';
import '../components/mTextField.dart';
import '../utils/api.dart';
import '../utils/prefs.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late String _email = '';
  late String _password = '';
  late String _company = '';

  /// Controls the "Check Company" -> "Password" step
  bool _isCompanyChecked = false;
  bool _isLoading = false;
  String errorMsg = '';

  /// Step 1: Check Company & Validate User with Email
  /// Calls two endpoints in sequence:
  /// - checkCompany
  /// - validateUserWithEmail
  Future<void> _checkCompany() async {
    setState(() {
      _isLoading = true;
      errorMsg = '';
    });

    try {
      // First: checkCompany
      await Prefs.clearCompanyName();

      final checkCompanyResponse = await Api.post(
        'checkCompany',
        {
          'companyName': _company,
          'email': _email,
        },
      );

      if (checkCompanyResponse == null) {
        setState(() {
          errorMsg = 'Null response from server for checkCompany.';
        });
        return;
      }

      if (checkCompanyResponse['success'] != true) {
        setState(() {
          errorMsg = checkCompanyResponse['message'] ?? 'Company/User not found';
        });
        return;
      }

      await Prefs.setCompanyName(_company);

      // Second: validateUserWithEmail
      final userValidationResponse = await Api.post(
        'validateUserWithEmail',
        {
          'email': _email,
          'type': 'client',
        },
      );

      if (userValidationResponse == null) {
        setState(() {
          errorMsg = 'Null response from server for validateUserWithEmail.';
        });
        return;
      }

      if (userValidationResponse['success'] != true) {
        setState(() {
          errorMsg = userValidationResponse['message'] ?? 'User validation failed';
        });
        return;
      }

      // If both calls returned success, allow user to enter Password
      setState(() {
        _isCompanyChecked = true;
      });
    } catch (e) {
      setState(() {
        errorMsg = 'Error occurred while validating: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Step 2: After company & user are verified, let the user log in with Firebase
  Future<void> _login() async {
    if (_email.isEmpty || _password.isEmpty) {
      setState(() {
        errorMsg = 'Please enter both Email and Password.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      errorMsg = '';
    });

    try {
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: _email, password: _password);

      // Get Firebase token and store it locally
      final String? bearer = await userCredential.user?.getIdToken();
      if (bearer == null) {
        throw FirebaseAuthException(
          code: 'invalid-token',
          message: 'Failed to get user token.',
        );
      }

      // Save to Shared Preferences
      await Prefs.setToken(bearer);
      await Prefs.setEmail(_email);
      await Prefs.setPassword(_password);

      // If you need to do additional steps, do them here...
      // e.g., Upsert FCM token, etc.

      log('Logged in successfully, token: $bearer');
      setState(() {
        _isLoading = false;
      });

      // Navigate to Home Page
      if (mounted) {
        await Navigator.of(context).pushReplacement(_routeToHomePage());
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        errorMsg = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        errorMsg = 'Wrong password provided for that user.';
      } else {
        errorMsg = e.message ?? 'An unexpected error occurred.';
      }
    } catch (e) {
      errorMsg = 'An unexpected error occurred: $e';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeMode>(
      builder: (context, state) {
        final colorScheme = Theme.of(context).colorScheme;
        return Scaffold(
          backgroundColor: colorScheme.primary,
          appBar: AppBar(
            backgroundColor: colorScheme.primary,
            elevation: 0,
            toolbarHeight: 0,
          ),
          body: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        // Top portion (logo, etc.)
                        Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.topCenter,
                          children: <Widget>[
                            Card(
                              margin: EdgeInsets.zero,
                              elevation: 0,
                              color: colorScheme.primary,
                              child: Container(
                                height: 300,
                              ),
                            ),
                            Positioned(
                              top: 80,
                              child: Column(
                                children: [
                                  ImageIcon(
                                    const AssetImage('assets/images/logo.png'),
                                    size: 80,
                                    color: colorScheme.inversePrimary,
                                  ),
                                  const SizedBox(height: 25),
                                  Text(
                                    'Moscare Worker',
                                    style: TextStyle(
                                      color: colorScheme.inversePrimary,
                                      fontSize: 21,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Bottom portion (forms)
                        Expanded(
                          child: Card(
                            color: colorScheme.primaryContainer,
                            margin: EdgeInsets.zero,
                            shape: const RoundedRectangleBorder(
                              side: BorderSide.none,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(80),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Login",
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 30),

                                  // PHASE 1: Company & Email
                                  if (!_isCompanyChecked) ...[
                                    MTextField(
                                      onChanged: (value) => _company = value,
                                      colorScheme: colorScheme,
                                      labelText: 'Company',
                                    ),
                                    const SizedBox(height: 30),
                                    MTextField(
                                      onChanged: (value) => _email = value,
                                      colorScheme: colorScheme,
                                      labelText: 'Email',
                                    ),
                                    const SizedBox(height: 40),

                                    _isLoading
                                        ? LinearProgressIndicator(
                                      color: colorScheme.primary,
                                    )
                                        : ElevatedButton(
                                      onPressed: _checkCompany,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                        colorScheme.primary,
                                        padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 32,
                                            vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(8),
                                        ),
                                        textStyle: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.25,
                                        ),
                                      ),
                                      child: Text(
                                        'Check Company',
                                        style: TextStyle(
                                          color:
                                          colorScheme.inversePrimary,
                                        ),
                                      ),
                                    ),
                                  ] else ...[
                                    // PHASE 2: Password (only after company & email are verified)
                                    MTextField(
                                      onChanged: (value) => _password = value,
                                      colorScheme: colorScheme,
                                      labelText: 'Password',
                                      isPassword: true,
                                    ),
                                    const SizedBox(height: 40),

                                    _isLoading
                                        ? LinearProgressIndicator(
                                      color: colorScheme.primary,
                                    )
                                        : ElevatedButton(
                                      onPressed: _login,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                        colorScheme.primary,
                                        padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 32,
                                            vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(8),
                                        ),
                                        textStyle: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.25,
                                        ),
                                      ),
                                      child: Text(
                                        'Login',
                                        style: TextStyle(
                                          color:
                                          colorScheme.inversePrimary,
                                        ),
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 16),
                                  // Error message area
                                  Text(
                                    errorMsg,
                                    style: TextStyle(
                                      color: colorScheme.error,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Route _routeToHomePage() {
    _isLoading = false;
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => const HomePage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        final tween = Tween(begin: begin, end: end);
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
        );

        return SlideTransition(
          position: tween.animate(curvedAnimation),
          child: child,
        );
      },
    );
  }
}
