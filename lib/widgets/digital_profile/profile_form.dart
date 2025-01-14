// lib/widgets/digital_profile/profile_form.dart
// Profile Components: Profile information form
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/digital_profile_provider.dart';

class ProfileForm extends StatefulWidget {
  const ProfileForm({super.key});

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  late TextEditingController _displayNameController;
  late TextEditingController _locationController;
  late TextEditingController _jobTitleController;
  late TextEditingController _companyNameController;
  late TextEditingController _bioController;
  Timer? _saveTimer;

  @override
  void initState() {
    super.initState();
    final provider = context.read<DigitalProfileProvider>();
    _displayNameController =
        TextEditingController(text: provider.profileData.displayName);
    _locationController = TextEditingController(text: provider.profileData.location);
    _jobTitleController = TextEditingController(text: provider.profileData.jobTitle);
    _companyNameController =
        TextEditingController(text: provider.profileData.companyName);
    _bioController = TextEditingController(text: provider.profileData.bio);

    _setupListeners(provider);
  }

  void _setupListeners(DigitalProfileProvider provider) {
    _displayNameController.addListener(() {
      if (_saveTimer?.isActive ?? false) _saveTimer?.cancel();
      _saveTimer = Timer(const Duration(milliseconds: 500), () {
        provider.updateProfile(displayName: _displayNameController.text);
        provider.saveProfile();
      });
    });

    _locationController.addListener(() {
      if (_saveTimer?.isActive ?? false) _saveTimer?.cancel();
      _saveTimer = Timer(const Duration(milliseconds: 500), () {
        provider.updateProfile(location: _locationController.text);
        provider.saveProfile();
      });
    });

    _jobTitleController.addListener(() {
      if (_saveTimer?.isActive ?? false) _saveTimer?.cancel();
      _saveTimer = Timer(const Duration(milliseconds: 500), () {
        provider.updateProfile(jobTitle: _jobTitleController.text);
        provider.saveProfile();
      });
    });

    _companyNameController.addListener(() {
      if (_saveTimer?.isActive ?? false) _saveTimer?.cancel();
      _saveTimer = Timer(const Duration(milliseconds: 500), () {
        provider.updateProfile(companyName: _companyNameController.text);
        provider.saveProfile();
      });
    });

    _bioController.addListener(() {
      if (_saveTimer?.isActive ?? false) _saveTimer?.cancel();
      _saveTimer = Timer(const Duration(milliseconds: 500), () {
        provider.updateProfile(bio: _bioController.text);
        provider.saveProfile();
      });
    });
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _locationController.dispose();
    _jobTitleController.dispose();
    _companyNameController.dispose();
    _bioController.dispose();
    _saveTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFormField('Display Name', _displayNameController, 50),
        const SizedBox(height: 16),
        _buildFormField('Location', _locationController, 50),
        const SizedBox(height: 16),
        _buildFormField('Job Title', _jobTitleController, 100),
        const SizedBox(height: 16),
        _buildFormField('Company Name', _companyNameController, 100),
        const SizedBox(height: 16),
        _buildBioField(),
      ],
    );
  }

  Widget _buildFormField(
      String label, TextEditingController controller, int maxLength) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      inputFormatters: [LengthLimitingTextInputFormatter(maxLength)],
    );
  }

  Widget _buildBioField() {
    return TextFormField(
      controller: _bioController,
      decoration: InputDecoration(
        labelText: 'Bio',
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      maxLines: null,
      minLines: 1,
      maxLength: 50,
      buildCounter: (context,
          {required currentLength, required isFocused, maxLength}) {
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Text('$currentLength/50 words', textAlign: TextAlign.end),
        );
      },
    );
  }
}