import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../agriculturist/agriculturist_dashboard_screen.dart';
import '../main/main_screen.dart';

class RegisterScreen extends StatefulWidget {
  final String role;

  const RegisterScreen({
    super.key,
    required this.role,
  });

  @override
  State<RegisterScreen> createState() =>
      _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const Color _primaryColor = Color(0xFF179E43);
  static const Color _backgroundColor = Color(0xFFF6F7F5);

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final TextEditingController _fullNameController =
      TextEditingController();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;

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

  Future<void> _register() async {
    if (_isLoading) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptedTerms) {
      _showMessage(
        'Please agree to the Terms and Privacy Policy.',
        Colors.red,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService.registerUser(
        email: _emailController.text,
        password: _passwordController.text,
        fullName: _fullNameController.text,
        role: _normalizedRole,
      );

      if (!mounted) {
        return;
      }

      final Widget destination =
          _normalizedRole == 'agriculturist'
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
        'Unable to create account: $error',
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

  String? _nameValidator(String? value) {
    final String name = value?.trim() ?? '';

    if (name.isEmpty) {
      return 'Please enter your full name.';
    }

    if (name.length < 3) {
      return 'The name must contain at least 3 characters.';
    }

    return null;
  }

  String? _emailValidator(String? value) {
    final String email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Please enter your email address.';
    }

    final RegExp emailPattern = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!emailPattern.hasMatch(email)) {
      return 'Please enter a valid email address.';
    }

    return null;
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password.';
    }

    if (value.length < 6) {
      return 'The password must contain at least 6 characters.';
    }

    return null;
  }

  String? _confirmPasswordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password.';
    }

    if (value != _passwordController.text) {
      return 'The passwords do not match.';
    }

    return null;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          '$_roleLabel Registration',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 500,
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
                    'Create $_roleLabel Account',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B1B1B),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Enter your information to register.',
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
                            controller:
                                _fullNameController,
                            textCapitalization:
                                TextCapitalization.words,
                            textInputAction:
                                TextInputAction.next,
                            validator: _nameValidator,
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: const Icon(
                                Icons.person_outline,
                                color: _primaryColor,
                              ),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
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
                                    BorderRadius.circular(
                                  12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller:
                                _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction:
                                TextInputAction.next,
                            validator: _passwordValidator,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              helperText:
                                  'Use at least 6 characters.',
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
                                      ? Icons
                                          .visibility_outlined
                                      : Icons
                                          .visibility_off_outlined,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller:
                                _confirmPasswordController,
                            obscureText:
                                _obscureConfirmPassword,
                            textInputAction:
                                TextInputAction.done,
                            validator:
                                _confirmPasswordValidator,
                            onFieldSubmitted: (_) =>
                                _register(),
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              prefixIcon: const Icon(
                                Icons.lock_reset_outlined,
                                color: _primaryColor,
                              ),
                              suffixIcon: IconButton(
                                tooltip:
                                    _obscureConfirmPassword
                                        ? 'Show password'
                                        : 'Hide password',
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons
                                          .visibility_outlined
                                      : Icons
                                          .visibility_off_outlined,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          CheckboxListTile(
                            value: _acceptedTerms,
                            onChanged: _isLoading
                                ? null
                                : (bool? value) {
                                    setState(() {
                                      _acceptedTerms =
                                          value ?? false;
                                    });
                                  },
                            activeColor: _primaryColor,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity:
                                ListTileControlAffinity
                                    .leading,
                            title: const Text(
                              'I agree to the Terms and Privacy Policy.',
                              style: TextStyle(
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: _isLoading
                                  ? null
                                  : _register,
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
                                      Icons.person_add,
                                    ),
                              label: Text(
                                _isLoading
                                    ? 'Creating Account...'
                                    : 'Register as $_roleLabel',
                                style: const TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () =>
                                    Navigator.pop(context),
                            child: const Text(
                              'Already have an account? Login',
                              style: TextStyle(
                                color: _primaryColor,
                                fontWeight:
                                    FontWeight.w600,
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
