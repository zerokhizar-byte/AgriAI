import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../services/user_id_service.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
  });

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState
    extends State<ProfileScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  User? get _user =>
      FirebaseAuth.instance.currentUser;

  bool _loading = true;

  String _userId = '';
  String _location = '';
  String _bio = '';

  String get _name {
    final String? displayName =
        _user?.displayName?.trim();

    if (displayName != null &&
        displayName.isNotEmpty) {
      return displayName;
    }

    return 'Farmer';
  }

  String get _email =>
      _user?.email?.trim() ?? '';

  @override
  void initState() {
    super.initState();

    unawaited(
      _loadOrCreateProfile(),
    );
  }

  // ===========================================================================
  // PROFILE DATA
  // ===========================================================================

  Future<void> _loadOrCreateProfile() async {
    final User? user = _user;

    if (user == null) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });

      return;
    }

    try {
      final DocumentReference<
          Map<String, dynamic>> ref =
          _firestore
              .collection('users')
              .doc(user.uid);

      final DocumentSnapshot<
          Map<String, dynamic>> snapshot =
          await ref.get();

      if (snapshot.exists) {
        final Map<String, dynamic> data =
            snapshot.data() ??
                <String, dynamic>{};

        _userId =
            '${data['userId'] ?? ''}'.trim();

        _location =
            '${data['location'] ?? ''}'.trim();

        _bio =
            '${data['bio'] ?? ''}'.trim();
      }

      if (_userId.isEmpty) {
        _userId =
            await _generateUniqueUserId(
          _name,
        );

        await ref.set(
          <String, dynamic>{
            'uid': user.uid,
            'userId': _userId,
            'userIdLower':
                _userId.toLowerCase(),
            'displayName': _name,
            'email': user.email ?? '',
            'photoUrl': user.photoURL ?? '',
            'location': _location,
            'bio': _bio,
            'createdAt':
                FieldValue.serverTimestamp(),
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(
            merge: true,
          ),
        );
      }

      // Keep every existing profile ID reserved in the usernames
      // collection so it cannot be claimed by another farmer.
      await UserIdService.ensureCurrentUserReservation(
        _userId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });
    }
  }

  Future<String> _generateUniqueUserId(
    String name,
  ) async {
    String base = name
        .toLowerCase()
        .replaceAll(
          RegExp(r'[^a-z0-9]+'),
          '_',
        )
        .replaceAll(
          RegExp(r'^_+|_+$'),
          '',
        );

    if (base.isEmpty) {
      base = 'farmer';
    }

    if (base.length > 14) {
      base = base.substring(0, 14);
    }

    for (int i = 0; i < 50; i++) {
      final String candidate;

      if (i == 0) {
        candidate = base;
      } else {
        final int suffix =
            1000 +
            ((DateTime.now()
                        .microsecondsSinceEpoch +
                    i) %
                9000);

        candidate =
            '${base}_$suffix';
      }

      final QuerySnapshot<
          Map<String, dynamic>> found =
          await _firestore
              .collection('users')
              .where(
                'userIdLower',
                isEqualTo:
                    candidate.toLowerCase(),
              )
              .limit(1)
              .get();

      if (found.docs.isEmpty) {
        return candidate;
      }
    }

    return '${base}_${DateTime.now().millisecondsSinceEpoch % 100000}';
  }

  // ===========================================================================
  // EDIT PROFILE
  // ===========================================================================

  Future<void> _editProfile() async {
    final TextEditingController nameController =
        TextEditingController(text: _name);

    final TextEditingController idController =
        TextEditingController(text: _userId);

    final TextEditingController locationController =
        TextEditingController(text: _location);

    final TextEditingController bioController =
        TextEditingController(text: _bio);

    bool saving = false;

    try {
      await showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) {
          return StatefulBuilder(
            builder: (
              BuildContext dialogContext,
              void Function(void Function()) setDialogState,
            ) {
              return AlertDialog(
                title: const Text('Edit Profile'),
                content: SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      TextField(
                        controller: nameController,
                        textCapitalization:
                            TextCapitalization.words,
                        enabled: !saving,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                        ),
                      ),
                      TextField(
                        controller: idController,
                        maxLength: 20,
                        enabled: !saving,
                        autocorrect: false,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'AgriAI User ID',
                          prefixText: '@',
                          helperText:
                              '4–20 characters: a-z, 0-9 and _',
                        ),
                      ),
                      TextField(
                        controller: locationController,
                        enabled: !saving,
                        decoration: const InputDecoration(
                          labelText: 'Location',
                        ),
                      ),
                      TextField(
                        controller: bioController,
                        maxLines: 3,
                        maxLength: 160,
                        enabled: !saving,
                        decoration: const InputDecoration(
                          labelText: 'Bio',
                        ),
                      ),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: saving
                        ? null
                        : () {
                            Navigator.of(dialogContext).pop();
                          },
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: saving
                        ? null
                        : () async {
                            final String newName =
                                nameController.text.trim();

                            final String newId =
                                UserIdService.normalizeUserId(
                              idController.text,
                            );

                            final String newLocation =
                                locationController.text.trim();

                            final String newBio =
                                bioController.text.trim();

                            if (newName.isEmpty) {
                              ScaffoldMessenger.of(
                                dialogContext,
                              ).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please enter your name.',
                                  ),
                                ),
                              );
                              return;
                            }

                            final String? validationError =
                                UserIdService.validateUserId(
                              newId,
                            );

                            if (validationError != null) {
                              ScaffoldMessenger.of(
                                dialogContext,
                              ).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    validationError,
                                  ),
                                ),
                              );
                              return;
                            }

                            final User? user = _user;

                            if (user == null) {
                              return;
                            }

                            setDialogState(() {
                              saving = true;
                            });

                            try {
                              final String oldId =
                                  UserIdService.normalizeUserId(
                                _userId,
                              );

                              if (newId != oldId) {
                                await UserIdService.changeUserId(
                                  newId,
                                );
                              }

                              await user.updateDisplayName(
                                newName,
                              );

                              await _firestore
                                  .collection('users')
                                  .doc(user.uid)
                                  .set(
                                <String, dynamic>{
                                  'uid': user.uid,
                                  'userId': newId,
                                  'userIdLower': newId,
                                  'displayName': newName,
                                  'email': user.email ?? '',
                                  'photoUrl':
                                      user.photoURL ?? '',
                                  'location': newLocation,
                                  'bio': newBio,
                                  'updatedAt':
                                      FieldValue.serverTimestamp(),
                                },
                                SetOptions(merge: true),
                              );

                              if (!mounted ||
                                  !dialogContext.mounted) {
                                return;
                              }

                              Navigator.of(dialogContext).pop();

                              setState(() {
                                _userId = newId;
                                _location = newLocation;
                                _bio = newBio;
                              });
                            } catch (error) {
                              if (!dialogContext.mounted) {
                                return;
                              }

                              setDialogState(() {
                                saving = false;
                              });

                              final String message =
                                  error is FirebaseException &&
                                          error.code ==
                                              'user-id-taken'
                                      ? 'That User ID is already taken.'
                                      : 'Unable to update profile: $error';

                              ScaffoldMessenger.of(
                                dialogContext,
                              ).showSnackBar(
                                SnackBar(
                                  content: Text(message),
                                ),
                              );
                            }
                          },
                    child: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Save'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      nameController.dispose();
      idController.dispose();
      locationController.dispose();
      bioController.dispose();
    }
  }


  // ===========================================================================
  // UI
  // ===========================================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final User? user = _user;

    return Scaffold(
      backgroundColor:
          AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Profile',
        ),
        backgroundColor:
            AppColors.background,
        foregroundColor:
            AppColors.textPrimary,
        elevation: 0,
        actions: <Widget>[
          IconButton(
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      const SettingsScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.settings_outlined,
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh:
                  _loadOrCreateProfile,
              child: ListView(
                padding:
                    const EdgeInsets.fromLTRB(
                  18,
                  8,
                  18,
                  32,
                ),
                children: <Widget>[
                  Container(
                    padding:
                        const EdgeInsets.all(
                      22,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          AppColors.cardGreen,
                      borderRadius:
                          BorderRadius.circular(
                        24,
                      ),
                      border: Border.all(
                        color:
                            AppColors.border,
                      ),
                    ),
                    child: Column(
                      children: <Widget>[
                        CircleAvatar(
                          radius: 46,
                          backgroundColor:
                              AppColors.primary,
                          backgroundImage: user
                                      ?.photoURL
                                      ?.isNotEmpty ==
                                  true
                              ? NetworkImage(
                                  user!.photoURL!,
                                )
                              : null,
                          child: user
                                      ?.photoURL
                                      ?.isNotEmpty ==
                                  true
                              ? null
                              : const Icon(
                                  Icons
                                      .person_rounded,
                                  color:
                                      Colors.white,
                                  size: 44,
                                ),
                        ),
                        const SizedBox(
                          height: 13,
                        ),
                        Text(
                          _name,
                          style:
                              const TextStyle(
                            fontSize: 23,
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        Text(
                          '@$_userId',
                          style:
                              const TextStyle(
                            color:
                                AppColors.primary,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                        if (_bio.isNotEmpty) ...<
                            Widget>[
                          const SizedBox(
                            height: 8,
                          ),
                          Text(
                            _bio,
                            textAlign:
                                TextAlign.center,
                            style:
                                const TextStyle(
                              color: AppColors
                                  .textSecondary,
                            ),
                          ),
                        ],
                        if (_location
                            .isNotEmpty) ...<
                            Widget>[
                          const SizedBox(
                            height: 7,
                          ),
                          Text(
                            '📍 $_location',
                            style:
                                const TextStyle(
                              fontSize: 10,
                              color: AppColors
                                  .textSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(
                          height: 15,
                        ),
                        OutlinedButton.icon(
                          onPressed:
                              _editProfile,
                          icon: const Icon(
                            Icons
                                .edit_outlined,
                          ),
                          label: const Text(
                            'Edit Profile',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 18,
                  ),
                  _Section(
                    title: 'Account',
                    children: <Widget>[
                      _InfoRow(
                        icon: Icons
                            .email_outlined,
                        title: 'Email',
                        value: _email.isEmpty
                            ? 'Not added'
                            : _email,
                      ),
                      _InfoRow(
                        icon: Icons
                            .badge_outlined,
                        title:
                            'AgriAI User ID',
                        value:
                            '@$_userId',
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 14,
                  ),
                  _Section(
                    title: 'Your AgriAI',
                    children:
                        const <Widget>[
                      _InfoRow(
                        icon: Icons
                            .article_outlined,
                        title: 'Posts',
                        value: '0',
                      ),
                      _InfoRow(
                        icon: Icons
                            .play_circle_outline_rounded,
                        title: 'Reels',
                        value: '0',
                      ),
                      _InfoRow(
                        icon: Icons
                            .people_outline_rounded,
                        title:
                            'Connections',
                        value: '0',
                      ),
                      _InfoRow(
                        icon: Icons
                            .bookmark_border_rounded,
                        title: 'Saved',
                        value: '0',
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

// ============================================================================
// SECTION
// ============================================================================

class _Section
    extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({
    required this.title,
    required this.children,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        14,
        12,
        14,
        8,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }
}

// ============================================================================
// INFO ROW
// ============================================================================

class _InfoRow
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return ListTile(
      contentPadding:
          EdgeInsets.zero,
      leading: Icon(
        icon,
        color: AppColors.primary,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 10,
          color:
              AppColors.textSecondary,
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontWeight:
              FontWeight.w800,
        ),
      ),
    );
  }
}
