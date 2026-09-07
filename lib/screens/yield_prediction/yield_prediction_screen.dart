import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';

class YieldPredictionScreen extends StatefulWidget {
  final VoidCallback? onPredictionComplete;

  const YieldPredictionScreen({
    super.key,
    this.onPredictionComplete,
  });

  @override
  State<YieldPredictionScreen> createState() =>
      _YieldPredictionScreenState();
}

class _YieldPredictionScreenState
    extends State<YieldPredictionScreen> {
  final _formKey = GlobalKey<FormState>();

  String _selectedCrop = 'Wheat';
  final _areaController = TextEditingController();
  final _rainfallController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _humidityController = TextEditingController();
  final _fertilizerController = TextEditingController();

  bool _isPredicting = false;

  static const List<String> _crops = [
    'Wheat',
    'Rice',
    'Maize',
    'Cotton',
    'Sugarcane',
    'Soybean',
    'Potato',
    'Tomato',
  ];

  @override
  void dispose() {
    _areaController.dispose();
    _rainfallController.dispose();
    _temperatureController.dispose();
    _humidityController.dispose();
    _fertilizerController.dispose();
    super.dispose();
  }

  Future<void> _predictYield() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isPredicting = true;
    });

    await Future<void>.delayed(
      const Duration(milliseconds: 900),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isPredicting = false;
    });

    widget.onPredictionComplete?.call();

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => YieldResultScreen(
          crop: _selectedCrop,
          area: _areaController.text.trim(),
          rainfall: _rainfallController.text.trim(),
          temperature:
              _temperatureController.text.trim(),
          humidity: _humidityController.text.trim(),
          fertilizer:
              _fertilizerController.text.trim(),
        ),
      ),
    );
  }

  String? _requiredValidator(
    String? value,
    String label,
  ) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }

    final number = double.tryParse(value.trim());

    if (number == null) {
      return 'Enter a valid number';
    }

    if (number < 0) {
      return '$label cannot be negative';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Yield Prediction'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              20,
              8,
              20,
              30,
            ),
            children: [
              const _YieldIntroCard(),
              const SizedBox(height: 20),
              const Text(
                'Crop Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              _InputCard(
                child: Column(
                  children: [
                    _CropDropdown(
                      value: _selectedCrop,
                      crops: _crops,
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _selectedCrop = value;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    _YieldTextField(
                      controller: _areaController,
                      label: 'Farm Area',
                      hint: 'Enter farm area',
                      suffix: 'hectare',
                      icon: Icons.landscape_outlined,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) =>
                          _requiredValidator(
                        value,
                        'Farm area',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Environmental Conditions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              _InputCard(
                child: Column(
                  children: [
                    _YieldTextField(
                      controller: _rainfallController,
                      label: 'Rainfall',
                      hint: 'Enter rainfall',
                      suffix: 'mm',
                      icon: Icons.water_drop_outlined,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) =>
                          _requiredValidator(
                        value,
                        'Rainfall',
                      ),
                    ),
                    const SizedBox(height: 14),
                    _YieldTextField(
                      controller:
                          _temperatureController,
                      label: 'Temperature',
                      hint: 'Enter average temperature',
                      suffix: '°C',
                      icon: Icons.thermostat_outlined,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) =>
                          _requiredValidator(
                        value,
                        'Temperature',
                      ),
                    ),
                    const SizedBox(height: 14),
                    _YieldTextField(
                      controller: _humidityController,
                      label: 'Humidity',
                      hint: 'Enter humidity',
                      suffix: '%',
                      icon: Icons.opacity_outlined,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) =>
                          _requiredValidator(
                        value,
                        'Humidity',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Farming Inputs',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              _InputCard(
                child: _YieldTextField(
                  controller: _fertilizerController,
                  label: 'Fertilizer Usage',
                  hint: 'Enter fertilizer quantity',
                  suffix: 'kg',
                  icon: Icons.eco_outlined,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) =>
                      _requiredValidator(
                    value,
                    'Fertilizer usage',
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed:
                      _isPredicting ? null : _predictYield,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors.primary,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(
                      alpha: 0.55,
                    ),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(
                      milliseconds: 180,
                    ),
                    child: _isPredicting
                        ? const SizedBox(
                            key: ValueKey('loading'),
                            width: 23,
                            height: 23,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            key: ValueKey('button'),
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Predict Crop Yield',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight:
                                      FontWeight.w800,
                                ),
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
  }
}

class _YieldIntroCard extends StatelessWidget {
  const _YieldIntroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardGreen,
        borderRadius: BorderRadius.circular(
          AppDimensions.radius22,
        ),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius:
                  BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.analytics_outlined,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Yield Prediction',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Enter your crop and field conditions to estimate expected yield.',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
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

class _InputCard extends StatelessWidget {
  final Widget child;

  const _InputCard({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(
          AppDimensions.radius18,
        ),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: child,
    );
  }
}

class _CropDropdown extends StatelessWidget {
  final String value;
  final List<String> crops;
  final ValueChanged<String?> onChanged;

  const _CropDropdown({
    required this.value,
    required this.crops,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      onChanged: onChanged,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.textMuted,
      ),
      decoration: InputDecoration(
        labelText: 'Crop',
        prefixIcon: const Icon(
          Icons.agriculture_outlined,
          color: AppColors.primary,
        ),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
      ),
      items: crops.map((crop) {
        return DropdownMenuItem<String>(
          value: crop,
          child: Text(
            crop,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _YieldTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String suffix;
  final IconData icon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _YieldTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.suffix,
    required this.icon,
    required this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        prefixIcon: Icon(
          icon,
          color: AppColors.primary,
        ),
        filled: true,
        fillColor: AppColors.background,
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Colors.redAccent,
          ),
        ),
        focusedErrorBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class YieldResultScreen extends StatelessWidget {
  final String crop;
  final String area;
  final String rainfall;
  final String temperature;
  final String humidity;
  final String fertilizer;

  const YieldResultScreen({
    super.key,
    required this.crop,
    required this.area,
    required this.rainfall,
    required this.temperature,
    required this.humidity,
    required this.fertilizer,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Yield Result'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            8,
            20,
            30,
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius:
                      BorderRadius.circular(22),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Prediction Ready',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Your crop information has been processed.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _ResultCard(
                title: 'Crop',
                value: crop,
                icon: Icons.agriculture_outlined,
              ),
              const SizedBox(height: 10),
              _ResultCard(
                title: 'Farm Area',
                value: '$area hectare',
                icon: Icons.landscape_outlined,
              ),
              const SizedBox(height: 10),
              _ResultCard(
                title: 'Rainfall',
                value: '$rainfall mm',
                icon: Icons.water_drop_outlined,
              ),
              const SizedBox(height: 10),
              _ResultCard(
                title: 'Temperature',
                value: '$temperature °C',
                icon: Icons.thermostat_outlined,
              ),
              const SizedBox(height: 10),
              _ResultCard(
                title: 'Humidity',
                value: '$humidity %',
                icon: Icons.opacity_outlined,
              ),
              const SizedBox(height: 10),
              _ResultCard(
                title: 'Fertilizer',
                value: '$fertilizer kg',
                icon: Icons.eco_outlined,
              ),
              const SizedBox(height: 20),
              const Text(
                'Connect your trained ML model to replace this result screen with the actual predicted yield.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.4,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _ResultCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: AppColors.cardGreen,
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}