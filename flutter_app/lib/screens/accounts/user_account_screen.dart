import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/constants/api_constants.dart';
import '../../core/services/auth_manager.dart';

class UserAccountScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final Map<String, dynamic> profile;

  const UserAccountScreen({
    super.key,
    required this.user,
    required this.profile,
  });

  @override
  State<UserAccountScreen> createState() => _UserAccountScreenState();
}

class _UserAccountScreenState extends State<UserAccountScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _nicknameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _dobController;

  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late final TextEditingController _waistController;

  late final TextEditingController _allergiesController;
  late final TextEditingController _conditionsController;
  late final TextEditingController _medicationsController;

  late final TextEditingController _sleepController;

  String? _sex;
  String? _bloodGroup;
  String? _activityLevel;
  String? _healthGoal;
  String? _diet;
  String? _smoking;
  String? _alcohol;
  int? _age;

  bool _saving = false;

  final List<String> _sexOptions = [
    'Male',
    'Female',
    'Other',
    'Prefer not to say',
  ];

  final List<String> _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
    'Unknown',
  ];

  final List<String> _activityLevels = [
    'Sedentary',
    'Light',
    'Moderate',
    'Active',
    'Very Active',
  ];

  final List<String> _healthGoals = [
    'Lose Weight',
    'Maintain Weight',
    'Gain Weight',
    'Improve Fitness',
    'Improve Sleep',
    'General Wellness',
  ];

  final List<String> _dietOptions = [
    'No Preference',
    'Vegetarian',
    'Vegan',
    'Non-Vegetarian',
    'Pescatarian',
  ];

  final List<String> _yesNoOptions = [
    'No',
    'Occasionally',
    'Yes',
  ];

  @override
  void initState() {
    super.initState();

    final user = widget.user;
    final profile = widget.profile;

    _nameController = TextEditingController(
      text: user['name']?.toString() ?? '',
    );

    _nicknameController = TextEditingController(
      text: profile['nickname']?.toString() ?? '',
    );

    _phoneController = TextEditingController(
      text: user['phone']?.toString() ?? '',
    );

    _dobController = TextEditingController(
      text: profile['dateOfBirth']?.toString() ?? '',
    );

    _heightController = TextEditingController(
      text: profile['height']?.toString() ?? '',
    );

    _weightController = TextEditingController(
      text: profile['weight']?.toString() ?? '',
    );

    _waistController = TextEditingController(
      text: profile['waistCircumference']?.toString() ?? '',
    );

    _allergiesController = TextEditingController(
      text: profile['allergies']?.toString() ?? '',
    );

    _conditionsController = TextEditingController(
      text: profile['medicalConditions']?.toString() ?? '',
    );

    _medicationsController = TextEditingController(
      text: profile['medications']?.toString() ?? '',
    );

    _sleepController = TextEditingController(
      text: profile['sleepTargetHours']?.toString() ?? '',
    );

    _sex = profile['sex']?.toString() ??
        profile['gender']?.toString();

    _bloodGroup = profile['bloodGroup']?.toString();

    _activityLevel = profile['activityLevel']?.toString();

    _healthGoal = profile['healthGoal']?.toString();

    _diet = profile['dietaryPreference']?.toString();

    _smoking = profile['smokingStatus']?.toString();

    _alcohol = profile['alcoholConsumption']?.toString();

    _calculateAge();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _waistController.dispose();
    _allergiesController.dispose();
    _conditionsController.dispose();
    _medicationsController.dispose();
    _sleepController.dispose();

    super.dispose();
  }

  void _calculateAge() {
    final dob = DateTime.tryParse(_dobController.text);

    if (dob == null) {
      setState(() {
        _age = null;
      });
      return;
    }

    final today = DateTime.now();

    int age = today.year - dob.year;

    if (today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day)) {
      age--;
    }

    setState(() {
      _age = age;
    });
  }

  Future<void> _selectDateOfBirth() async {
    DateTime initialDate = DateTime.now();

    final existing = DateTime.tryParse(_dobController.text);

    if (existing != null) {
      initialDate = existing;
    }

    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Select your date of birth',
    );

    if (selected == null) return;

    final date =
        '${selected.year.toString().padLeft(4, '0')}-'
        '${selected.month.toString().padLeft(2, '0')}-'
        '${selected.day.toString().padLeft(2, '0')}';

    setState(() {
      _dobController.text = date;
    });

    _calculateAge();
  }

  double? _calculateBMI() {
    final height = double.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);

    if (height == null ||
        weight == null ||
        height <= 0 ||
        weight <= 0) {
      return null;
    }

    final heightMeters = height / 100;

    return weight / (heightMeters * heightMeters);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final token = await AuthManager().getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Authentication session expired.');
      }

      final bmi = _calculateBMI();

      final payload = {
        'nickname': _nicknameController.text.trim(),
        'dateOfBirth': _dobController.text.trim(),
        'age': _age,
        'sex': _sex,
        'gender': _sex,

        'height': double.tryParse(
          _heightController.text.trim(),
        ),

        'weight': double.tryParse(
          _weightController.text.trim(),
        ),

        'waistCircumference': double.tryParse(
          _waistController.text.trim(),
        ),

        'bloodGroup': _bloodGroup,

        'activityLevel': _activityLevel,

        'healthGoal': _healthGoal,

        'dietaryPreference': _diet,

        'allergies': _allergiesController.text.trim(),

        'medicalConditions':
            _conditionsController.text.trim(),

        'medications':
            _medicationsController.text.trim(),

        'sleepTargetHours': double.tryParse(
          _sleepController.text.trim(),
        ),

        'smokingStatus': _smoking,

        'alcoholConsumption': _alcohol,

        if (bmi != null)
          'bmi': double.parse(
            bmi.toStringAsFixed(2),
          ),
      };

      await Dio().put(
        '${ApiConstants.baseUrl}/profile/update',
        data: payload,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Profile updated successfully',
          ),
          backgroundColor: Colors.teal,
        ),
      );

      Navigator.pop(context, true);
    } on DioException catch (e) {
      if (!mounted) return;

      final message =
          e.response?.data?['message']?.toString() ??
              'Unable to update profile';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Profile update failed: $e',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  InputDecoration _inputDecoration(
    String label, {
    IconData? icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null
          ? null
          : Icon(
              icon,
              color: const Color(0xff9f6eff),
            ),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.black.withOpacity(0.06),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xff9f6eff),
          width: 1.5,
        ),
      ),
    );
  }

  Widget _section(
    String title,
    String subtitle,
    IconData icon,
    List<Widget> children,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xff9f6eff)
                      .withOpacity(0.10),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xff9f6eff),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    IconData? icon,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: items.contains(value) ? value : null,
      decoration: _inputDecoration(
        label,
        icon: icon,
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(item.toString()),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bmi = _calculateBMI();

    return Scaffold(
      backgroundColor: const Color(0xfff4f7f6),
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildProfileHeader(),

              const SizedBox(height: 18),

              _section(
                'Personal Information',
                'Basic information used for your health profile',
                Icons.person_outline_rounded,
                [
                  TextFormField(
                    controller: _nameController,
                    decoration: _inputDecoration(
                      'Full Name',
                      icon: Icons.person_outline,
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _nicknameController,
                    decoration: _inputDecoration(
                      'Nickname',
                      icon: Icons.badge_outlined,
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'Enter a nickname';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _phoneController,
                    keyboardType:
                        TextInputType.phone,
                    decoration: _inputDecoration(
                      'Phone Number',
                      icon: Icons.phone_outlined,
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _dobController,
                    readOnly: true,
                    onTap: _selectDateOfBirth,
                    decoration: _inputDecoration(
                      'Date of Birth',
                      icon: Icons.calendar_today_outlined,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _dropdown<String>(
                          label: 'Sex',
                          value: _sex,
                          items: _sexOptions,
                          icon: Icons.wc_outlined,
                          onChanged: (value) {
                            setState(() {
                              _sex = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding:
                              const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xff9f6eff,
                            ).withOpacity(0.07),
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Age',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.black45,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                _age == null
                                    ? '—'
                                    : '$_age years',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  _dropdown<String>(
                    label: 'Blood Group',
                    value: _bloodGroup,
                    items: _bloodGroups,
                    icon: Icons.bloodtype_outlined,
                    onChanged: (value) {
                      setState(() {
                        _bloodGroup = value;
                      });
                    },
                  ),
                ],
              ),

              _section(
                'Body Measurements',
                'Used for BMI and health calculations',
                Icons.monitor_weight_outlined,
                [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller:
                              _heightController,
                          keyboardType:
                              const TextInputType
                                  .numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (_) {
                            setState(() {});
                          },
                          decoration:
                              _inputDecoration(
                            'Height',
                            hint: 'cm',
                            icon: Icons.height,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller:
                              _weightController,
                          keyboardType:
                              const TextInputType
                                  .numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (_) {
                            setState(() {});
                          },
                          decoration:
                              _inputDecoration(
                            'Weight',
                            hint: 'kg',
                            icon:
                                Icons.monitor_weight,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _waistController,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _inputDecoration(
                      'Waist Circumference',
                      hint: 'cm (optional)',
                      icon: Icons.straighten_outlined,
                    ),
                  ),

                  const SizedBox(height: 14),

                  if (bmi != null)
                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: const Color(
                          0xff9f6eff,
                        ).withOpacity(0.08),
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons
                                .analytics_outlined,
                            color:
                                Color(0xff9f6eff),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Current BMI',
                              style: TextStyle(
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            bmi.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight:
                                  FontWeight.w900,
                              color:
                                  Color(0xff9f6eff),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              _section(
                'Lifestyle',
                'Help Pulse AI understand your daily habits',
                Icons.directions_run_outlined,
                [
                  _dropdown<String>(
                    label: 'Activity Level',
                    value: _activityLevel,
                    items: _activityLevels,
                    icon: Icons.directions_run,
                    onChanged: (value) {
                      setState(() {
                        _activityLevel = value;
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _sleepController,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _inputDecoration(
                      'Target Sleep',
                      hint: 'hours per night',
                      icon:
                          Icons.bedtime_outlined,
                    ),
                  ),

                  const SizedBox(height: 12),

                  _dropdown<String>(
                    label: 'Dietary Preference',
                    value: _diet,
                    items: _dietOptions,
                    icon:
                        Icons.restaurant_outlined,
                    onChanged: (value) {
                      setState(() {
                        _diet = value;
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  _dropdown<String>(
                    label: 'Smoking',
                    value: _smoking,
                    items: _yesNoOptions,
                    icon:
                        Icons.smoking_rooms_outlined,
                    onChanged: (value) {
                      setState(() {
                        _smoking = value;
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  _dropdown<String>(
                    label: 'Alcohol Consumption',
                    value: _alcohol,
                    items: _yesNoOptions,
                    icon:
                        Icons.local_bar_outlined,
                    onChanged: (value) {
                      setState(() {
                        _alcohol = value;
                      });
                    },
                  ),
                ],
              ),

              _section(
                'Health Information',
                'Optional information for more personalized insights',
                Icons.health_and_safety_outlined,
                [
                  TextFormField(
                    controller:
                        _allergiesController,
                    maxLines: 2,
                    decoration: _inputDecoration(
                      'Allergies',
                      hint:
                          'e.g. peanuts, medicines',
                      icon:
                          Icons.warning_amber_outlined,
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller:
                        _conditionsController,
                    maxLines: 3,
                    decoration: _inputDecoration(
                      'Medical Conditions',
                      hint:
                          'e.g. asthma, diabetes',
                      icon:
                          Icons.medical_information_outlined,
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller:
                        _medicationsController,
                    maxLines: 3,
                    decoration: _inputDecoration(
                      'Current Medications',
                      hint:
                          'List current medicines if applicable',
                      icon:
                          Icons.medication_outlined,
                    ),
                  ),
                ],
              ),

              _section(
                'Health Goals',
                'Choose the primary goal for your health journey',
                Icons.flag_outlined,
                [
                  _dropdown<String>(
                    label: 'Primary Health Goal',
                    value: _healthGoal,
                    items: _healthGoals,
                    icon: Icons.flag_outlined,
                    onChanged: (value) {
                      setState(() {
                        _healthGoal = value;
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 4),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed:
                      _saving ? null : _saveProfile,
                  icon: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.save_outlined,
                        ),
                  label: Text(
                    _saving
                        ? 'Saving...'
                        : 'Save Profile',
                  ),
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xff9f6eff),
                    foregroundColor:
                        Colors.white,
                    elevation: 0,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final photo =
        widget.user['photoUrl']?.toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xff6c5ce7),
            Color(0xff9f6eff),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor:
                Colors.white.withOpacity(0.20),
            backgroundImage:
                photo != null && photo.isNotEmpty
                    ? NetworkImage(photo)
                    : null,
            child: photo == null || photo.isEmpty
                ? const Icon(
                    Icons.person,
                    size: 38,
                    color: Colors.white,
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Health Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.user['email']
                          ?.toString() ??
                      '',
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Keep your information up to date',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}