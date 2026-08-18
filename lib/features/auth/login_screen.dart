import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../agriculturist/agriculturist_dashboard_screen.dart';
import '../main/main_screen.dart';

class LoginScreen extends StatefulWidget {
  final String role;

  const LoginScreen({
    super.key,
    required this.role,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color _primaryColor = Color(0xFF179E43);
  static const Color _backgroundColor = Color(0xFFF5F7FB);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  String get _normalizedRole =>
      widget.role.trim().toLowerCase();

  String get _roleLabel =>
      _normalizedRole == 'agriculturist'
          ? 'Agriculturist'
          : 'Farmer';

  IconData get _roleIcon =>
      _normalizedRole == 'agriculturist'
          ? Icons.medical_services_outlined
          : Icons.agriculture_outlined;

  Future<void> _login() async {
    if (_isLoading) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );

      final String? savedRole =
          await AuthService.getCurrentUserRole();

      if (!mounted) {
        return;
      }

      if (savedRole == null) {
        await AuthService.signOut();

        _showMessage(
          'The account role could not be found.',
          Colors.red,
        );
        return;
      }

      if (savedRole != _normalizedRole) {
        await AuthService.signOut();

        if (!mounted) {
          return;
        }

        _showMessage(
          'This account is registered as a '
          '${_capitalize(savedRole)} account.',
          Colors.red,
        );
        return;
      }

      final Widget destination =
          savedRole == 'agriculturist'
              ? const AgriculturistDashboardScreen()
              : const MainScreen();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => destination,
        ),
        (route) => false,
      );
    } on AuthServiceException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        error.message,
        Colors.red,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to login: $error',
        Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final TextEditingController resetEmailController =
        TextEditingController(
      text: _emailController.text.trim(),
    );

    bool isSending = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: !isSending,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (
            BuildContext context,
            StateSetter setDialogState,
          ) {
            Future<void> sendResetLink() async {
              if (isSending) {
                return;
              }

              final String email =
                  resetEmailController.text.trim();

              if (email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please enter your email address.',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              setDialogState(() {
                isSending = true;
              });

              try {
                await AuthService.sendPasswordResetEmail(
                  email,
                );

                if (!dialogContext.mounted) {
                  return;
                }

                Navigator.pop(dialogContext);

                if (!mounted) {
                  return;
                }

                _showMessage(
                  'A password reset link was sent to $email.',
                  _primaryColor,
                );
              } on AuthServiceException catch (error) {
                if (!dialogContext.mounted) {
                  return;
                }

                ScaffoldMessenger.of(dialogContext)
                    .showSnackBar(
                  SnackBar(
                    content: Text(error.message),
                    backgroundColor: Colors.red,
                  ),
                );
              } finally {
                if (dialogContext.mounted) {
                  setDialogState(() {
                    isSending = false;
                  });
                }
              }
            }

            return AlertDialog(
              title: const Text(
                'Reset Password',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: TextField(
                controller: resetEmailController,
                keyboardType:
                    TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon:
                      const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSending
                      ? null
                      : () =>
                          Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed:
                      isSending ? null : sendResetLink,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.3,
                          ),
                        )
                      : const Text('Send Link'),
                ),
              ],
            );
          },
        );
      },
    );

    resetEmailController.dispose();
  }

  void _showMessage(
    String message,
    Color backgroundColor,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  String _capitalize(String value) {
    if (value.isEmpty) {
      return value;
    }

    return value[0].toUpperCase() +
        value.substring(1).toLowerCase();
  }

  String? _emailValidator(String? value) {
    final String email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Please enter your email address.';
    }

    if (!email.contains('@') || !email.contains('.')) {
      return 'Please enter a valid email address.';
    }

    return null;
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password.';
    }

    if (value.length < 6) {
      return 'The password must contain at least 6 characters.';
    }

    return null;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          '$_roleLabel Login',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 480,
              ),
              child: Column(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _primaryColor,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _roleIcon,
                      color: _primaryColor,
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Welcome, $_roleLabel!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B1B1B),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Enter your account details to continue.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF5E6962),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade200,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailController,
                            keyboardType:
                                TextInputType.emailAddress,
                            textInputAction:
                                TextInputAction.next,
                            validator: _emailValidator,
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: const Icon(
                                Icons.email_outlined,
                                color: _primaryColor,
                              ),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller:
                                _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction:
                                TextInputAction.done,
                            validator: _passwordValidator,
                            onFieldSubmitted: (_) => _login(),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                color: _primaryColor,
                              ),
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword
                                    ? 'Show password'
                                    : 'Hide password',
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword =
                                        !_obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons
                                          .visibility_off_outlined,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : _showForgotPasswordDialog,
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: _primaryColor,
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed:
                                  _isLoading ? null : _login,
                              style:
                                  ElevatedButton.styleFrom(
                                backgroundColor:
                                    _primaryColor,
                                foregroundColor:
                                    Colors.white,
                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                    12,
                                  ),
                                ),
                              ),
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child:
                                          CircularProgressIndicator(
                                        color:
                                            Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.login,
                                    ),
                              label: Text(
                                _isLoading
                                    ? 'Logging In...'
                                    : 'Login as $_roleLabel',
                                style: const TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),
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
}
