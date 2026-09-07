import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class SoilAnalysisScreen extends StatefulWidget {
  final VoidCallback? onAnalysisComplete;

  const SoilAnalysisScreen({
    super.key,
    this.onAnalysisComplete,
  });

  @override
  State<SoilAnalysisScreen> createState() =>
      _SoilAnalysisScreenState();
}

class _SoilAnalysisScreenState
    extends State<SoilAnalysisScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nitrogenController =
      TextEditingController();
  final _phosphorusController =
      TextEditingController();
  final _potassiumController =
      TextEditingController();
  final _phController =
      TextEditingController();
  final _moistureController =
      TextEditingController();
  final _temperatureController =
      TextEditingController();

  bool _isAnalyzing = false;

  @override
  void dispose() {
    _nitrogenController.dispose();
    _phosphorusController.dispose();
    _potassiumController.dispose();
    _phController.dispose();
    _moistureController.dispose();
    _temperatureController.dispose();
    super.dispose();
  }

  String? _validateNumber(
    String? value,
    String label,
  ) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }

    final number =
        double.tryParse(value.trim());

    if (number == null) {
      return 'Enter a valid number';
    }

    if (number < 0) {
      return '$label cannot be negative';
    }

    return null;
  }

  Future<void> _analyzeSoil() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isAnalyzing = true;
    });

    await Future<void>.delayed(
      const Duration(milliseconds: 900),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isAnalyzing = false;
    });

    widget.onAnalysisComplete?.call();

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SoilResultScreen(
          nitrogen:
              _nitrogenController.text.trim(),
          phosphorus:
              _phosphorusController.text.trim(),
          potassium:
              _potassiumController.text.trim(),
          ph: _phController.text.trim(),
          moisture:
              _moistureController.text.trim(),
          temperature:
              _temperatureController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Soil Analysis'),
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
              const _SoilIntroCard(),
              const SizedBox(height: 20),
              const Text(
                'Soil Nutrients',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              _SoilInputCard(
                children: [
                  _SoilField(
                    controller:
                        _nitrogenController,
                    label: 'Nitrogen',
                    hint: 'Enter nitrogen value',
                    unit: 'mg/kg',
                    icon: Icons.eco_outlined,
                    validator: (value) =>
                        _validateNumber(
                      value,
                      'Nitrogen',
                    ),
                  ),
                  const SizedBox(height: 13),
                  _SoilField(
                    controller:
                        _phosphorusController,
                    label: 'Phosphorus',
                    hint:
                        'Enter phosphorus value',
                    unit: 'mg/kg',
                    icon:
                        Icons.grass_outlined,
                    validator: (value) =>
                        _validateNumber(
                      value,
                      'Phosphorus',
                    ),
                  ),
                  const SizedBox(height: 13),
                  _SoilField(
                    controller:
                        _potassiumController,
                    label: 'Potassium',
                    hint:
                        'Enter potassium value',
                    unit: 'mg/kg',
                    icon:
                        Icons.spa_outlined,
                    validator: (value) =>
                        _validateNumber(
                      value,
                      'Potassium',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Soil Conditions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              _SoilInputCard(
                children: [
                  _SoilField(
                    controller: _phController,
                    label: 'pH Level',
                    hint: 'Enter soil pH',
                    unit: 'pH',
                    icon:
                        Icons.science_outlined,
                    validator: (value) {
                      final error =
                          _validateNumber(
                        value,
                        'pH level',
                      );

                      if (error != null) {
                        return error;
                      }

                      final ph = double.parse(
                        value!.trim(),
                      );

                      if (ph > 14) {
                        return 'pH cannot be greater than 14';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 13),
                  _SoilField(
                    controller:
                        _moistureController,
                    label: 'Soil Moisture',
                    hint:
                        'Enter moisture level',
                    unit: '%',
                    icon:
                        Icons.water_drop_outlined,
                    validator: (value) =>
                        _validateNumber(
                      value,
                      'Soil moisture',
                    ),
                  ),
                  const SizedBox(height: 13),
                  _SoilField(
                    controller:
                        _temperatureController,
                    label: 'Soil Temperature',
                    hint:
                        'Enter soil temperature',
                    unit: '°C',
                    icon:
                        Icons.thermostat_outlined,
                    validator: (value) =>
                        _validateNumber(
                      value,
                      'Soil temperature',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isAnalyzing
                      ? null
                      : _analyzeSoil,
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors.primary,
                    disabledBackgroundColor:
                        AppColors.primary
                            .withValues(
                      alpha: 0.55,
                    ),
                    foregroundColor:
                        Colors.white,
                    elevation: 0,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration:
                        const Duration(
                      milliseconds: 180,
                    ),
                    child: _isAnalyzing
                        ? const SizedBox(
                            key: ValueKey(
                              'loading',
                            ),
                            width: 23,
                            height: 23,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color:
                                  Colors.white,
                            ),
                          )
                        : const Row(
                            key: ValueKey(
                              'analyze',
                            ),
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .center,
                            children: [
                              Icon(
                                Icons
                                    .auto_awesome,
                                size: 20,
                              ),
                              SizedBox(
                                width: 8,
                              ),
                              Text(
                                'Analyze Soil',
                                style:
                                    TextStyle(
                                  fontSize:
                                      14.5,
                                  fontWeight:
                                      FontWeight
                                          .w800,
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

class _SoilIntroCard extends StatelessWidget {
  const _SoilIntroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardGreen,
        borderRadius:
            BorderRadius.circular(22),
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
              Icons.water_drop_outlined,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Soil Analysis',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Enter your soil parameters to understand soil condition and support better crop decisions.',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.4,
                    fontWeight:
                        FontWeight.w500,
                    color:
                        AppColors.textSecondary,
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

class _SoilInputCard extends StatelessWidget {
  final List<Widget> children;

  const _SoilInputCard({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _SoilField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String unit;
  final IconData icon;
  final String? Function(String?)? validator;

  const _SoilField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.unit,
    required this.icon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType:
          const TextInputType.numberWithOptions(
        decimal: true,
      ),
      validator: validator,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: unit,
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
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
        errorBorder:
            OutlineInputBorder(
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

class SoilResultScreen extends StatelessWidget {
  final String nitrogen;
  final String phosphorus;
  final String potassium;
  final String ph;
  final String moisture;
  final String temperature;

  const SoilResultScreen({
    super.key,
    required this.nitrogen,
    required this.phosphorus,
    required this.potassium,
    required this.ph,
    required this.moisture,
    required this.temperature,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Soil Result'),
        backgroundColor:
            AppColors.background,
        foregroundColor:
            AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            8,
            20,
            30,
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius:
                      BorderRadius.circular(
                    22,
                  ),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons
                          .check_circle_outline_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Analysis Complete',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Your soil parameters have been processed.',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.5,
                        color:
                            Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _ResultItem(
                title: 'Nitrogen',
                value: '$nitrogen mg/kg',
                icon:
                    Icons.eco_outlined,
              ),
              _ResultItem(
                title: 'Phosphorus',
                value: '$phosphorus mg/kg',
                icon:
                    Icons.grass_outlined,
              ),
              _ResultItem(
                title: 'Potassium',
                value: '$potassium mg/kg',
                icon:
                    Icons.spa_outlined,
              ),
              _ResultItem(
                title: 'pH Level',
                value: ph,
                icon:
                    Icons.science_outlined,
              ),
              _ResultItem(
                title: 'Soil Moisture',
                value: '$moisture %',
                icon:
                    Icons.water_drop_outlined,
              ),
              _ResultItem(
                title: 'Temperature',
                value: '$temperature °C',
                icon:
                    Icons.thermostat_outlined,
              ),
              const SizedBox(height: 16),
              const Text(
                'Connect your trained ML model to generate actual soil recommendations and crop suitability results.',
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.4,
                  color:
                      AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultItem extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _ResultItem({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:
          const EdgeInsets.only(bottom: 10),
      padding:
          const EdgeInsets.all(14),
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
                fontWeight:
                    FontWeight.w600,
                color:
                    AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight:
                  FontWeight.w800,
              color:
                  AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}