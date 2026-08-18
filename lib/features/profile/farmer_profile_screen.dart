import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class FarmerProfileScreen extends StatefulWidget {
  const FarmerProfileScreen({super.key});

  @override
  State<FarmerProfileScreen> createState() =>
      _FarmerProfileScreenState();
}

class _FarmerProfileScreenState
    extends State<FarmerProfileScreen> {
  static const Color _primaryColor = Color(0xFF179E43);
  static const Color _backgroundColor = Color(0xFFF6F7F5);

  static const String _collectionName = 'farmer_profiles';

  final TextEditingController _nameController =
      TextEditingController();
  final TextEditingController _municipalityController =
      TextEditingController();
  final TextEditingController _contactController =
      TextEditingController();
  final TextEditingController _farmNameController =
      TextEditingController();
  final TextEditingController _farmSizeController =
      TextEditingController();
  final TextEditingController _squashVarietyController =
      TextEditingController();

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  bool _hasProfile = false;
  bool _isUpdatingPhoto = false;

  String _localProfileImagePath = '';

  DocumentReference<Map<String, dynamic>> get _profileReference {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No authenticated user.');
    }
    return FirebaseFirestore.instance
        .collection(_collectionName)
        .doc(user.uid);
  }

  @override
  void initState() {
    super.initState();
    _loadLocalProfileImage();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final DocumentSnapshot<Map<String, dynamic>>
          document = await _profileReference.get();

      if (!mounted) {
        return;
      }

      if (document.exists) {
        final Map<String, dynamic> data =
            document.data() ?? {};

        _nameController.text =
            data['farmerName']?.toString() ?? '';

        _municipalityController.text =
            data['municipality']?.toString() ?? '';

        _contactController.text =
            data['contactNumber']?.toString() ?? '';

        _farmNameController.text =
            data['farmName']?.toString() ?? '';

        _farmSizeController.text =
            data['farmSize']?.toString() ?? '';

        _squashVarietyController.text =
            data['squashVariety']?.toString() ?? '';

        _hasProfile = true;
      } else {
        final user = FirebaseAuth.instance.currentUser;
        _nameController.text = user?.displayName ?? '';
        _isEditing = true;
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to load farmer profile: $error',
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

  Future<Directory> _profileImageDirectory() async {
    final Directory documentsDirectory =
        await getApplicationDocumentsDirectory();

    final Directory profileDirectory = Directory(
      '${documentsDirectory.path}${Platform.pathSeparator}profile_images',
    );

    if (!await profileDirectory.exists()) {
      await profileDirectory.create(recursive: true);
    }

    return profileDirectory;
  }

  Future<List<File>> _profileImageCandidates() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return <File>[];
    }

    final Directory directory = await _profileImageDirectory();

    return <File>[
      File(
        '${directory.path}${Platform.pathSeparator}'
        'profile_${user.uid}.jpg',
      ),
      File(
        '${directory.path}${Platform.pathSeparator}'
        'profile_${user.uid}.png',
      ),
      File(
        '${directory.path}${Platform.pathSeparator}'
        'profile_${user.uid}.webp',
      ),
    ];
  }

  Future<void> _loadLocalProfileImage() async {
    try {
      final List<File> candidates =
          await _profileImageCandidates();

      for (final File file in candidates) {
        if (await file.exists()) {
          if (!mounted) return;

          setState(() {
            _localProfileImagePath = file.path;
          });

          return;
        }
      }
    } catch (_) {
      // Keep the default person icon if the local photo cannot be loaded.
    }
  }

  String _extensionForImage(String path) {
    final String lowerPath = path.toLowerCase();

    if (lowerPath.endsWith('.png')) {
      return 'png';
    }

    if (lowerPath.endsWith('.webp')) {
      return 'webp';
    }

    return 'jpg';
  }

  Future<void> _showProfilePhotoOptions() async {
    if (_isUpdatingPhoto) {
      return;
    }

    final bool hasPhoto = _localProfileImagePath.isNotEmpty;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Profile Picture',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE8F5E9),
                    child: Icon(
                      Icons.camera_alt_outlined,
                      color: _primaryColor,
                    ),
                  ),
                  title: const Text(
                    'Take Photo',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Use your camera to take a new profile photo.',
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickProfilePicture(ImageSource.camera);
                  },
                ),
                const SizedBox(height: 4),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE8F5E9),
                    child: Icon(
                      Icons.photo_library_outlined,
                      color: _primaryColor,
                    ),
                  ),
                  title: const Text(
                    'Choose from Album',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Select an existing photo from your gallery.',
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickProfilePicture(ImageSource.gallery);
                  },
                ),
                if (hasPhoto) ...[
                  const Divider(height: 24),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFFFEBEE),
                      child: Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                    ),
                    title: const Text(
                      'Remove Profile Photo',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      'Return to the default profile icon.',
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _confirmRemoveProfilePicture();
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickProfilePicture(
    ImageSource source,
  ) async {
    if (_isUpdatingPhoto) {
      return;
    }

    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'You must be logged in to change your profile picture.',
        Colors.red,
      );
      return;
    }

    try {
      final XFile? selectedImage = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
        preferredCameraDevice: CameraDevice.front,
      );

      if (selectedImage == null || !mounted) {
        return;
      }

      setState(() {
        _isUpdatingPhoto = true;
      });

      final Directory directory =
          await _profileImageDirectory();

      final List<File> oldFiles =
          await _profileImageCandidates();

      for (final File oldFile in oldFiles) {
        if (await oldFile.exists()) {
          await oldFile.delete();
        }
      }

      final String extension =
          _extensionForImage(selectedImage.path);

      final String destinationPath =
          '${directory.path}${Platform.pathSeparator}'
          'profile_${user.uid}.$extension';

      final File savedImage =
          await File(selectedImage.path).copy(destinationPath);

      if (!mounted) {
        return;
      }

      setState(() {
        _localProfileImagePath = savedImage.path;
        _isUpdatingPhoto = false;
      });

      _showMessage(
        'Profile picture updated successfully.',
        _primaryColor,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isUpdatingPhoto = false;
      });

      _showMessage(
        'Unable to update profile picture: $error',
        Colors.red,
      );
    }
  }

  Future<void> _confirmRemoveProfilePicture() async {
    if (_localProfileImagePath.isEmpty) {
      return;
    }

    final bool? shouldRemove = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Remove Profile Photo'),
          content: const Text(
            'Are you sure you want to remove your profile photo?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (shouldRemove == true) {
      await _removeProfilePicture();
    }
  }

  Future<void> _removeProfilePicture() async {
    if (_isUpdatingPhoto) {
      return;
    }

    try {
      setState(() {
        _isUpdatingPhoto = true;
      });

      final List<File> files =
          await _profileImageCandidates();

      for (final File file in files) {
        if (await file.exists()) {
          await file.delete();
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _localProfileImagePath = '';
        _isUpdatingPhoto = false;
      });

      _showMessage(
        'Profile photo removed.',
        _primaryColor,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isUpdatingPhoto = false;
      });

      _showMessage(
        'Unable to remove profile photo: $error',
        Colors.red,
      );
    }
  }

  Future<void> _saveProfile() async {
    if (_isSaving) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _profileReference.set(
        <String, dynamic>{
          'farmerName': _nameController.text.trim(),
          'municipality':
              _municipalityController.text.trim(),
          'contactNumber':
              _contactController.text.trim(),
          'farmName': _farmNameController.text.trim(),
          'farmSize': _farmSizeController.text.trim(),
          'squashVariety':
              _squashVarietyController.text.trim(),
          'uid': FirebaseAuth.instance.currentUser!.uid,
          'email': FirebaseAuth.instance.currentUser?.email ?? '',
          'updatedAt': FieldValue.serverTimestamp(),
          if (!_hasProfile)
            'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
        _isEditing = false;
        _hasProfile = true;
      });

      _showMessage(
        'Farmer profile saved successfully.',
        _primaryColor,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      _showMessage(
        'Unable to save farmer profile: $error',
        Colors.red,
      );
    }
  }

  void _cancelEditing() {
    if (!_hasProfile) {
      return;
    }

    setState(() {
      _isEditing = false;
    });

    _loadProfile();
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

  String? _requiredValidator(
    String? value,
    String fieldName,
  ) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $fieldName.';
    }

    return null;
  }

  String? _contactValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a contact number.';
    }

    final String contact = value.trim();

    if (contact.length < 7) {
      return 'Please enter a valid contact number.';
    }

    return null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _municipalityController.dispose();
    _contactController.dispose();
    _farmNameController.dispose();
    _farmSizeController.dispose();
    _squashVarietyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Farmer Profile',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2923),
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          if (!_isLoading &&
              _hasProfile &&
              !_isEditing)
            IconButton(
              tooltip: 'Edit profile',
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              icon: const Icon(Icons.edit),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: _primaryColor,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 22),
                  _buildProfileForm(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    final String farmerName =
        _nameController.text.trim();

    final String municipality =
        _municipalityController.text.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _primaryColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.20),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: _localProfileImagePath.isNotEmpty
                    ? Image.file(
                        File(_localProfileImagePath),
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 54,
                          );
                        },
                      )
                    : const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 54,
                      ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Material(
                  color: Colors.white,
                  elevation: 3,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: _isUpdatingPhoto
                        ? null
                        : _showProfilePhotoOptions,
                    customBorder: const CircleBorder(),
                    child: SizedBox(
                      width: 38,
                      height: 38,
                      child: _isUpdatingPhoto
                          ? const Padding(
                              padding: EdgeInsets.all(9),
                              child: CircularProgressIndicator(
                                strokeWidth: 2.3,
                                color: _primaryColor,
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt,
                              color: _primaryColor,
                              size: 20,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            farmerName.isEmpty
                ? 'Farmer Profile'
                : farmerName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            municipality.isEmpty
                ? 'Add your farming information'
                : municipality,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileForm() {
    return Form(
      key: _formKey,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
        child: Column(
          children: [
            _profileField(
              controller: _nameController,
              label: 'Farmer Name',
              icon: Icons.person_outline,
              validator: (String? value) {
                return _requiredValidator(
                  value,
                  'the farmer name',
                );
              },
            ),
            const SizedBox(height: 15),
            _profileField(
              controller: _municipalityController,
              label: 'Municipality',
              icon: Icons.location_city_outlined,
              validator: (String? value) {
                return _requiredValidator(
                  value,
                  'the municipality',
                );
              },
            ),
            const SizedBox(height: 15),
            _profileField(
              controller: _contactController,
              label: 'Contact Number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: _contactValidator,
            ),
            const SizedBox(height: 15),
            _profileField(
              controller: _farmSizeController,
              label: 'Farm Size',
              hintText: 'Example: 1 hectare',
              icon: Icons.square_foot_outlined,
            ),
            if (_isEditing) ...[
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed:
                      _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child:
                              CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Icon(
                          Icons.save_outlined,
                          color: Colors.white,
                        ),
                  label: Text(
                    _isSaving
                        ? 'Saving Profile...'
                        : 'Save Profile',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (_hasProfile) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed:
                        _isSaving ? null : _cancelEditing,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primaryColor,
                      side: const BorderSide(
                        color: _primaryColor,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _profileField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: _isEditing,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(
          icon,
          color: _primaryColor,
        ),
        filled: true,
        fillColor: _isEditing
            ? Colors.white
            : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
      ),
    );
  }
}