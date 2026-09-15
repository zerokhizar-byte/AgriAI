import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../services/cloudinary_media_service.dart';
import '../../services/user_id_service.dart';
import '../auth/login_screen.dart';
import '../connections/connections_screen.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? get _user => FirebaseAuth.instance.currentUser;

  bool _loading = true;
  bool _uploadingPhoto = false;

  String _userId = '';
  String _location = '';
  String _bio = '';
  String _farmSize = '';
  List<String> _crops = <String>[];

  String get _name {
    final String value = _user?.displayName?.trim() ?? '';
    return value.isEmpty ? 'Farmer' : value;
  }

  String get _email => _user?.email?.trim() ?? '';
  String get _photoUrl => _user?.photoURL?.trim() ?? '';

  String get _initials {
    final List<String> parts =
        _name.split(RegExp(r'\s+')).where((String e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'F';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    unawaited(_loadProfile());
  }

  Future<void> _loadProfile() async {
    final User? user = _user;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final DocumentReference<Map<String, dynamic>> ref =
          _firestore.collection('users').doc(user.uid);
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await ref.get();
      final Map<String, dynamic> data =
          snapshot.data() ?? <String, dynamic>{};

      _userId = '${data['userId'] ?? ''}'.trim();
      _location = '${data['location'] ?? ''}'.trim();
      _bio = '${data['bio'] ?? ''}'.trim();
      _farmSize = '${data['farmSize'] ?? ''}'.trim();

      final dynamic crops = data['crops'];
      if (crops is List) {
        _crops = crops
            .map((dynamic e) => '$e'.trim())
            .where((String e) => e.isNotEmpty)
            .toList();
      }

      if (_userId.isEmpty) {
        _userId = await _generateUniqueUserId(_name);
        await ref.set(<String, dynamic>{
          'uid': user.uid,
          'userId': _userId,
          'userIdLower': _userId.toLowerCase(),
          'displayName': _name,
          'email': user.email ?? '',
          'photoUrl': user.photoURL ?? '',
          'location': _location,
          'bio': _bio,
          'crops': _crops,
          'farmSize': _farmSize,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await UserIdService.ensureCurrentUserReservation(_userId);
    } catch (error) {
      debugPrint('AgriAI profile load error: $error');
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<String> _generateUniqueUserId(String name) async {
    String base = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    if (base.isEmpty) base = 'farmer';
    if (base.length > 14) base = base.substring(0, 14);

    for (int i = 0; i < 100; i++) {
      final String suffix = i == 0 ? '' : '_$i';
      final String candidate = '$base$suffix';
      final QuerySnapshot<Map<String, dynamic>> result = await _firestore
          .collection('users')
          .where('userIdLower', isEqualTo: candidate)
          .limit(1)
          .get();
      if (result.docs.isEmpty) return candidate;
    }
    return 'farmer_${DateTime.now().millisecondsSinceEpoch % 100000}';
  }

  Future<void> _pickProfilePhoto() async {
    if (_uploadingPhoto || _user == null) return;

    final ImagePicker picker = ImagePicker();
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (BuildContext sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const ListTile(
              title: Text(
                'Profile photo',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      setState(() => _uploadingPhoto = true);
      final XFile? picked = await picker.pickImage(
        source: source,
        imageQuality: 88,
        maxWidth: 1400,
      );
      if (picked == null) return;

      final CloudinaryUploadResult result =
          await CloudinaryMediaService.uploadImage(File(picked.path));

      await _user!.updatePhotoURL(result.secureUrl);
      await _firestore.collection('users').doc(_user!.uid).set(
        <String, dynamic>{
          'photoUrl': result.secureUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      await _user!.reload();

      if (mounted) {
        setState(() {});
        _message('Profile photo updated.');
      }
    } catch (error) {
      if (mounted) _message('Unable to update photo: $error');
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _editProfile() async {
    final User? user = _user;
    if (user == null) return;

    final TextEditingController nameController =
        TextEditingController(text: _name);
    final TextEditingController idController =
        TextEditingController(text: _userId);
    final TextEditingController locationController =
        TextEditingController(text: _location);
    final TextEditingController bioController =
        TextEditingController(text: _bio);
    final TextEditingController farmController =
        TextEditingController(text: _farmSize);
    final TextEditingController cropsController =
        TextEditingController(text: _crops.join(', '));

    bool saving = false;

    try {
      await showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) => StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            Future<void> save() async {
              if (saving) return;

              final String newName = nameController.text.trim();
              final String newId = _normalizeUserId(idController.text.trim());
              final String newLocation = locationController.text.trim();
              final String newBio = bioController.text.trim();
              final String newFarm = farmController.text.trim();
              final List<String> newCrops = cropsController.text
                  .split(',')
                  .map((String e) => e.trim())
                  .where((String e) => e.isNotEmpty)
                  .toList();

              if (newName.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Name is required.')),
                );
                return;
              }
              if (!_isValidUserId(newId)) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'User ID must be 4–20 characters, start with a letter, '
                      'and use only lowercase letters, numbers and underscores.',
                    ),
                  ),
                );
                return;
              }

              setDialogState(() => saving = true);

              try {
                if (newId != _userId.toLowerCase()) {
                  final QuerySnapshot<Map<String, dynamic>> existing =
                      await _firestore
                          .collection('users')
                          .where('userIdLower', isEqualTo: newId)
                          .limit(1)
                          .get();
                  if (existing.docs.isNotEmpty &&
                      existing.docs.first.id != user.uid) {
                    if (dialogContext.mounted) {
                      setDialogState(() => saving = false);
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('That User ID is already taken.'),
                        ),
                      );
                    }
                    return;
                  }
                }

                await user.updateDisplayName(newName);
                await _firestore.collection('users').doc(user.uid).set(
                  <String, dynamic>{
                    'uid': user.uid,
                    'userId': newId,
                    'userIdLower': newId,
                    'displayName': newName,
                    'email': user.email ?? '',
                    'photoUrl': user.photoURL ?? '',
                    'location': newLocation,
                    'farmSize': newFarm,
                    'crops': newCrops,
                    'bio': newBio,
                    'updatedAt': FieldValue.serverTimestamp(),
                  },
                  SetOptions(merge: true),
                );

                await UserIdService.ensureCurrentUserReservation(newId);

                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);

                if (!mounted) return;
                setState(() {
                  _userId = newId;
                  _location = newLocation;
                  _farmSize = newFarm;
                  _crops = newCrops;
                  _bio = newBio;
                });
                _message('Profile updated successfully.');
              } catch (error) {
                if (dialogContext.mounted) {
                  setDialogState(() => saving = false);
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Unable to update profile: $error')),
                  );
                }
              }
            }

            return AlertDialog(
              title: const Text(
                'Edit Profile',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              content: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    _field(nameController, 'Name', Icons.person_rounded),
                    const SizedBox(height: 10),
                    _field(idController, 'AgriAI User ID', Icons.alternate_email_rounded),
                    const SizedBox(height: 10),
                    _field(locationController, 'Location', Icons.location_on_rounded),
                    const SizedBox(height: 10),
                    _field(farmController, 'Farm size', Icons.straighten_rounded),
                    const SizedBox(height: 10),
                    _field(cropsController, 'Crops (comma separated)', Icons.eco_rounded),
                    const SizedBox(height: 10),
                    TextField(
                      controller: bioController,
                      maxLines: 4,
                      maxLength: 250,
                      decoration: const InputDecoration(
                        labelText: 'Bio',
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: saving ? null : save,
                  style: FilledButton.styleFrom(
                    backgroundColor: _ProfileColors.primary,
                  ),
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        ),
      );
    } finally {
      nameController.dispose();
      idController.dispose();
      locationController.dispose();
      bioController.dispose();
      farmController.dispose();
      cropsController.dispose();
    }
  }

  String _normalizeUserId(String value) {
    return value.trim().toLowerCase();
  }

  bool _isValidUserId(String value) {
    return RegExp(r'^[a-z][a-z0-9_]{3,19}$').hasMatch(value);
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
    );
  }

  Stream<int> _countStream(String collection, String field) {
    final String? uid = _user?.uid;
    if (uid == null) return Stream<int>.value(0);
    return _firestore
        .collection(collection)
        .where(field, isEqualTo: uid)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.size);
  }

  Stream<int> _connectionCountStream() {
    final String? uid = _user?.uid;
    if (uid == null) return Stream<int>.value(0);
    return _firestore
        .collection('connections')
        .where('user1Uid', isEqualTo: uid)
        .snapshots()
        .asyncMap((QuerySnapshot<Map<String, dynamic>> first) async {
      final QuerySnapshot<Map<String, dynamic>> second = await _firestore
          .collection('connections')
          .where('user2Uid', isEqualTo: uid)
          .get();
      return first.size + second.size;
    });
  }

  Stream<int> _savedCountStream() {
    final String? uid = _user?.uid;
    if (uid == null) return Stream<int>.value(0);
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('savedPosts')
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.size);
  }

  Future<void> _showSavedMenu() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (BuildContext sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const ListTile(
              title: Text(
                'Saved Content',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              subtitle: Text('Choose what you want to view.'),
            ),
            ListTile(
              leading: const Icon(Icons.article_rounded),
              title: const Text('Saved Posts'),
              onTap: () {
                Navigator.pop(sheetContext);
                _openSavedPosts();
              },
            ),
            ListTile(
              leading: const Icon(Icons.play_circle_rounded),
              title: const Text('Saved Reels'),
              onTap: () {
                Navigator.pop(sheetContext);
                _openSavedReels();
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _openSavedPosts() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const _SavedContentScreen(initialTab: 0),
      ),
    );
  }

  void _openSavedReels() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const _SavedContentScreen(initialTab: 1),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text(
          'Log out?',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text('You will need to sign in again to use AgriAI.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD64545),
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[Color(0xFF176B3A), Color(0xFF239653)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(30),
        ),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  'My Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Settings',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsScreen(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.settings_rounded,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Container(
                width: 102,
                height: 102,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.18),
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: _photoUrl.isEmpty
                    ? Center(
                        child: Text(
                          _initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      )
                    : Image.network(
                        _photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Center(
                          child: Text(
                            _initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: InkWell(
                  onTap: _pickProfilePhoto,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _ProfileColors.primary,
                        width: 2,
                      ),
                    ),
                    child: _uploadingPhoto
                        ? const Padding(
                            padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.camera_alt_rounded,
                            size: 17,
                            color: _ProfileColors.primary,
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '@${_userId.isEmpty ? 'farmer' : _userId}',
            style: const TextStyle(
              color: Color(0xFFDDF4E3),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (_location.isNotEmpty) ...<Widget>[
            const SizedBox(height: 7),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(
                  Icons.location_on_rounded,
                  size: 14,
                  color: Color(0xFFDDF4E3),
                ),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    _location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFDDF4E3),
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 15),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _editProfile,
                  icon: const Icon(Icons.edit_rounded, size: 17),
                  label: const Text('Edit Profile'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0x99FFFFFF)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              IconButton(
                tooltip: 'Share profile',
                onPressed: () => SharePlus.instance.share(
                  ShareParams(
                    text:
                        'Connect with $_name on AgriAI: @${_userId.isEmpty ? 'farmer' : _userId}',
                  ),
                ),
                style: IconButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0x99FFFFFF)),
                ),
                icon: const Icon(Icons.share_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openConnections() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ConnectionsScreen(),
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _StatCard(
              icon: Icons.article_rounded,
              label: 'Posts',
              stream: _countStream('communityPosts', 'uid'),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: _StatCard(
              icon: Icons.play_circle_rounded,
              label: 'Reels',
              stream: _countStream('farmerVideos', 'authorId'),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: _StatCard(
              icon: Icons.people_alt_rounded,
              label: 'Connections',
              stream: _connectionCountStream(),
              onTap: _openConnections,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbout() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _CardHeading(
            icon: Icons.agriculture_rounded,
            title: 'Farmer details',
          ),
          const SizedBox(height: 12),
          if (_bio.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _bio,
                style: const TextStyle(
                  color: Color(0xFF53655B),
                  height: 1.45,
                  fontSize: 13,
                ),
              ),
            ),
          _DetailRow(
            icon: Icons.location_on_rounded,
            title: 'Location',
            value: _location.isEmpty ? 'Not added' : _location,
          ),
          _DetailRow(
            icon: Icons.straighten_rounded,
            title: 'Farm size',
            value: _farmSize.isEmpty ? 'Not added' : _farmSize,
          ),
          _DetailRow(
            icon: Icons.eco_rounded,
            title: 'Crops',
            value: _crops.isEmpty ? 'Not added' : _crops.join(', '),
          ),
          _DetailRow(
            icon: Icons.email_rounded,
            title: 'Email',
            value: _email.isEmpty ? 'Not added' : _email,
            last: true,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final String? uid = _user?.uid;
    if (uid == null) return const SizedBox.shrink();

    return DefaultTabController(
      length: 2,
      child: _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const _CardHeading(
              icon: Icons.grid_view_rounded,
              title: 'Your content',
            ),
            const SizedBox(height: 10),
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F7F3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const TabBar(
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                labelColor: _ProfileColors.primary,
                unselectedLabelColor: Color(0xFF789083),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
                tabs: <Widget>[
                  Tab(
                    icon: Icon(Icons.article_rounded, size: 17),
                    text: 'Posts',
                  ),
                  Tab(
                    icon: Icon(Icons.play_circle_rounded, size: 17),
                    text: 'Reels',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 360,
              child: TabBarView(
                children: <Widget>[
                  _ProfilePostsTab(uid: uid),
                  _ProfileReelsTab(uid: uid),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      children: <Widget>[
        _ActionTile(
          icon: Icons.bookmark_rounded,
          title: 'Saved Content',
          subtitle: 'Posts and Reels you saved',
          trailing: StreamBuilder<int>(
            stream: _savedCountStream(),
            builder: (_, AsyncSnapshot<int> snapshot) => Text(
              '${snapshot.data ?? 0}',
              style: const TextStyle(
                color: _ProfileColors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          onTap: _showSavedMenu,
        ),
        const SizedBox(height: 9),
        _ActionTile(
          icon: Icons.settings_rounded,
          title: 'Settings',
          subtitle: 'Language, notifications and app preferences',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SettingsScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 9),
        _ActionTile(
          icon: Icons.logout_rounded,
          title: 'Log Out',
          subtitle: 'Sign out of your AgriAI account',
          color: const Color(0xFFD64545),
          backgroundColor: const Color(0xFFFFF2F2),
          onTap: _confirmLogout,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ProfileColors.background,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: _ProfileColors.primary,
              ),
            )
          : RefreshIndicator(
              color: _ProfileColors.primary,
              onRefresh: _loadProfile,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: <Widget>[
                  SliverToBoxAdapter(child: _buildHeader()),
                  SliverToBoxAdapter(child: _buildStats()),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        <Widget>[
                          _buildAbout(),
                          const SizedBox(height: 14),
                          _buildContent(),
                          const SizedBox(height: 14),
                          _buildActions(),
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}


class _SavedContentScreen extends StatefulWidget {
  final int initialTab;

  const _SavedContentScreen({this.initialTab = 0});

  @override
  State<_SavedContentScreen> createState() => _SavedContentScreenState();
}

class _SavedContentScreenState extends State<_SavedContentScreen> {
  late int _tab;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab.clamp(0, 1);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _savedPostsStream() {
    final String? uid = _uid;
    if (uid == null) {
      return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('savedPosts')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _savedReelsStream() {
    final String? uid = _uid;
    if (uid == null) {
      return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('savedReels')
        .snapshots();
  }

  Future<void> _removeSavedPost(String id) async {
    final String? uid = _uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('savedPosts')
        .doc(id)
        .delete();
  }

  Future<void> _removeSavedReel(String id) async {
    final String? uid = _uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('savedReels')
        .doc(id)
        .delete();
  }

  void _openPost(Map<String, dynamic> data) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ProfilePostViewer(data: data),
      ),
    );
  }

  void _openReel(Map<String, dynamic> data) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ProfileReelViewer(
          videos: <Map<String, dynamic>>[data],
          initialIndex: 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ProfileColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF21352A),
        elevation: 0,
        title: const Text(
          'Saved Content',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Container(
              height: 46,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF3ED),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(child: _savedTabButton(0, Icons.article_rounded, 'Posts')),
                  Expanded(child: _savedTabButton(1, Icons.play_circle_rounded, 'Reels')),
                ],
              ),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _tab == 0
                  ? _SavedPostsList(
                      key: const ValueKey<String>('saved-posts'),
                      stream: _savedPostsStream(),
                      onOpen: _openPost,
                      onRemove: _removeSavedPost,
                    )
                  : _SavedReelsList(
                      key: const ValueKey<String>('saved-reels'),
                      stream: _savedReelsStream(),
                      onOpen: _openReel,
                      onRemove: _removeSavedReel,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _savedTabButton(int index, IconData icon, String label) {
    final bool selected = _tab == index;
    return GestureDetector(
      onTap: () => setState(() => _tab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected
              ? <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              icon,
              size: 17,
              color: selected
                  ? _ProfileColors.primary
                  : const Color(0xFF789083),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? _ProfileColors.primary
                    : const Color(0xFF789083),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedPostsList extends StatelessWidget {
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final void Function(Map<String, dynamic>) onOpen;
  final Future<void> Function(String) onRemove;

  const _SavedPostsList({
    super.key,
    required this.stream,
    required this.onOpen,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (
        BuildContext context,
        AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot,
      ) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              color: _ProfileColors.primary,
              strokeWidth: 2,
            ),
          );
        }

        if (snapshot.hasError) {
          return const _ContentMessage(
            icon: Icons.cloud_off_rounded,
            title: 'Saved posts could not be loaded',
            subtitle: 'Check your connection and try again.',
          );
        }

        final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs =
            <QueryDocumentSnapshot<Map<String, dynamic>>>[
          ...?snapshot.data?.docs,
        ];

        docs.sort((a, b) {
          final dynamic av = a.data()['savedAt'];
          final dynamic bv = b.data()['savedAt'];
          final int am = av is Timestamp ? av.millisecondsSinceEpoch : 0;
          final int bm = bv is Timestamp ? bv.millisecondsSinceEpoch : 0;
          return bm.compareTo(am);
        });

        if (docs.isEmpty) {
          return const _ContentMessage(
            icon: Icons.bookmark_border_rounded,
            title: 'No saved posts',
            subtitle: 'Save useful farming posts and find them here.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 110),
          itemCount: docs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (BuildContext context, int index) {
            final QueryDocumentSnapshot<Map<String, dynamic>> doc = docs[index];
            final Map<String, dynamic> data = <String, dynamic>{
              ...doc.data(),
            };

            return _SavedPostCard(
              data: data,
              onTap: () => onOpen(data),
              onRemove: () => onRemove(doc.id),
            );
          },
        );
      },
    );
  }
}

class _SavedPostCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _SavedPostCard({
    required this.data,
    required this.onTap,
    required this.onRemove,
  });

  String get _postId => '${data['postId'] ?? ''}'.trim();

  Map<String, dynamic> _mergePost(
    Map<String, dynamic> original,
  ) {
    return <String, dynamic>{
      ...data,
      ...original,
      'postId': _postId,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_postId.isEmpty) {
      return _buildCard(context, data);
    }

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('communityPosts')
          .doc(_postId)
          .get(),
      builder: (
        BuildContext context,
        AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot,
      ) {
        if (snapshot.hasData && snapshot.data!.exists) {
          final Map<String, dynamic> original =
              snapshot.data!.data() ?? <String, dynamic>{};
          final Map<String, dynamic> merged = _mergePost(original);
          return _buildCard(context, merged);
        }

        return _buildCard(context, data);
      },
    );
  }

  Widget _buildCard(
    BuildContext context,
    Map<String, dynamic> content,
  ) {
    final String text =
        '${content['text'] ?? content['content'] ?? ''}'.trim();
    final String mediaUrl =
        '${content['mediaUrl'] ?? content['imageUrl'] ?? ''}'.trim();
    final String author =
        '${content['displayName'] ?? content['authorName'] ?? 'Farmer'}'
            .trim();
    final String userId =
        '${content['userId'] ?? content['authorUserId'] ?? ''}'.trim();

    int number(String key) {
      final dynamic value = content[key];
      if (value is num) return value.toInt();
      return int.tryParse('$value') ?? 0;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE3ECE6)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 11, 8, 8),
              child: Row(
                children: <Widget>[
                  _Avatar(
                    url:
                        '${content['photoUrl'] ?? content['authorPhotoUrl'] ?? ''}',
                    name: author,
                    size: 38,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (userId.isNotEmpty)
                          Text(
                            '@$userId',
                            style: const TextStyle(
                              color: _ProfileColors.primary,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove from saved',
                    onPressed: onRemove,
                    icon: const Icon(
                      Icons.bookmark_rounded,
                      color: _ProfileColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            if (text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: Text(
                  text,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Color(0xFF405148),
                  ),
                ),
              ),
            if (mediaUrl.isNotEmpty)
              AspectRatio(
                aspectRatio: 1.55,
                child: Image.network(
                  mediaUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const _MediaFallback(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 11),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.favorite_border_rounded,
                    size: 17,
                    color: Color(0xFF6C7C73),
                  ),
                  const SizedBox(width: 4),
                  Text('${number('likesCount')}'),
                  const SizedBox(width: 14),
                  const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 16,
                    color: Color(0xFF6C7C73),
                  ),
                  const SizedBox(width: 4),
                  Text('${number('commentsCount')}'),
                  const Spacer(),
                  const Icon(
                    Icons.open_in_new_rounded,
                    size: 15,
                    color: _ProfileColors.primary,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Open',
                    style: TextStyle(
                      color: _ProfileColors.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedReelsList extends StatelessWidget {
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final void Function(Map<String, dynamic>) onOpen;
  final Future<void> Function(String) onRemove;

  const _SavedReelsList({
    super.key,
    required this.stream,
    required this.onOpen,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (
        BuildContext context,
        AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot,
      ) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              color: _ProfileColors.primary,
              strokeWidth: 2,
            ),
          );
        }

        if (snapshot.hasError) {
          return const _ContentMessage(
            icon: Icons.cloud_off_rounded,
            title: 'Saved Reels could not be loaded',
            subtitle: 'Check your connection and try again.',
          );
        }

        final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs =
            <QueryDocumentSnapshot<Map<String, dynamic>>>[
          ...?snapshot.data?.docs,
        ];

        docs.sort((a, b) {
          final dynamic av = a.data()['savedAt'];
          final dynamic bv = b.data()['savedAt'];
          final int am = av is Timestamp ? av.millisecondsSinceEpoch : 0;
          final int bm = bv is Timestamp ? bv.millisecondsSinceEpoch : 0;
          return bm.compareTo(am);
        });

        if (docs.isEmpty) {
          return const _ContentMessage(
            icon: Icons.bookmark_border_rounded,
            title: 'No saved Reels',
            subtitle: 'Save useful farming Reels and find them here.',
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 110),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.72,
          ),
          itemCount: docs.length,
          itemBuilder: (BuildContext context, int index) {
            final QueryDocumentSnapshot<Map<String, dynamic>> doc = docs[index];
            final Map<String, dynamic> data = <String, dynamic>{
              ...doc.data(),
            };

            return _SavedReelCard(
              data: data,
              onTap: () => onOpen(data),
              onRemove: () => onRemove(doc.id),
            );
          },
        );
      },
    );
  }
}

class _SavedReelCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _SavedReelCard({
    required this.data,
    required this.onTap,
    required this.onRemove,
  });

  String get _url =>
      '${data['cloudinaryUrl'] ?? data['mediaUrl'] ?? ''}'.trim();

  String get _title =>
      '${data['title'] ?? data['caption'] ?? 'Farming Reel'}'.trim();

  int _number(String key) {
    final dynamic value = data[key];
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF183126),
          borderRadius: BorderRadius.circular(18),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            if (_url.isNotEmpty)
              _ReelPreview(url: _url)
            else
              const _MediaFallback(
                icon: Icons.play_circle_outline_rounded,
                dark: true,
              ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Color(0x22000000),
                    Colors.transparent,
                    Color(0xDD000000),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.black.withValues(alpha: 0.35),
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onRemove,
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.bookmark_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
            const Center(
              child: CircleAvatar(
                radius: 22,
                backgroundColor: Color(0xB3FFFFFF),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: _ProfileColors.primary,
                  size: 29,
                ),
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _title.isEmpty ? 'Farming Reel' : _title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${_number('likesCount')}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.visibility_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${_number('viewsCount')}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfilePostsTab extends StatelessWidget {
  final String uid;

  const _ProfilePostsTab({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('communityPosts')
          .where('uid', isEqualTo: uid)
          .snapshots(),
      builder: (
        BuildContext context,
        AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot,
      ) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _ProfileColors.primary,
            ),
          );
        }

        if (snapshot.hasError) {
          return const _ContentMessage(
            icon: Icons.cloud_off_rounded,
            title: 'Posts could not be loaded',
            subtitle: 'Check your connection and try again.',
          );
        }

        final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs =
            <QueryDocumentSnapshot<Map<String, dynamic>>>[
          ...?snapshot.data?.docs,
        ];
        docs.sort(_sortByCreatedAt);

        if (docs.isEmpty) {
          return const _ContentMessage(
            icon: Icons.article_outlined,
            title: 'No posts yet',
            subtitle: 'Your farming posts will appear here.',
          );
        }

        return ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: docs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 9),
          itemBuilder: (BuildContext context, int index) {
            final Map<String, dynamic> data = docs[index].data();
            return _ProfilePostCard(data: data);
          },
        );
      },
    );
  }
}

class _ProfileReelsTab extends StatelessWidget {
  final String uid;

  const _ProfileReelsTab({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('farmerVideos')
          .where('authorId', isEqualTo: uid)
          .snapshots(),
      builder: (
        BuildContext context,
        AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot,
      ) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _ProfileColors.primary,
            ),
          );
        }

        if (snapshot.hasError) {
          return const _ContentMessage(
            icon: Icons.cloud_off_rounded,
            title: 'Reels could not be loaded',
            subtitle: 'Check your connection and try again.',
          );
        }

        final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs =
            <QueryDocumentSnapshot<Map<String, dynamic>>>[
          ...?snapshot.data?.docs,
        ];
        docs.sort(_sortByCreatedAt);

        if (docs.isEmpty) {
          return const _ContentMessage(
            icon: Icons.play_circle_outline_rounded,
            title: 'No reels yet',
            subtitle: 'Your farming Reels will appear here.',
          );
        }

        return GridView.builder(
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 9,
            mainAxisSpacing: 9,
            childAspectRatio: 0.78,
          ),
          itemCount: docs.length,
          itemBuilder: (BuildContext context, int index) {
            return _ProfileReelCard(
              data: docs[index].data(),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => _ProfileReelViewer(
                    videos: docs.map((e) => e.data()).toList(),
                    initialIndex: index,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

int _sortByCreatedAt(
  QueryDocumentSnapshot<Map<String, dynamic>> a,
  QueryDocumentSnapshot<Map<String, dynamic>> b,
) {
  final dynamic aValue = a.data()['createdAt'];
  final dynamic bValue = b.data()['createdAt'];
  final int aMillis =
      aValue is Timestamp ? aValue.millisecondsSinceEpoch : 0;
  final int bMillis =
      bValue is Timestamp ? bValue.millisecondsSinceEpoch : 0;
  return bMillis.compareTo(aMillis);
}

class _ProfilePostCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _ProfilePostCard({required this.data});

  String _text() => '${data['text'] ?? data['content'] ?? ''}'.trim();

  String _mediaUrl() =>
      '${data['mediaUrl'] ?? data['imageUrl'] ?? ''}'.trim();

  int _number(String key) {
    final dynamic value = data[key];
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final String text = _text();
    final String mediaUrl = _mediaUrl();
    final String author = '${data['authorName'] ?? data['displayName'] ?? 'Farmer'}';
    final String userId = '${data['authorUserId'] ?? data['userId'] ?? ''}'.trim();

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _ProfilePostViewer(data: data),
        ),
      ),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5EEE8)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 11, 12, 8),
              child: Row(
                children: <Widget>[
                  _Avatar(
                    url: '${data['authorPhotoUrl'] ?? data['photoUrl'] ?? ''}',
                    name: author,
                    size: 34,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (userId.isNotEmpty)
                          Text(
                            '@$userId',
                            style: const TextStyle(
                              fontSize: 9,
                              color: _ProfileColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.more_horiz_rounded,
                    color: Color(0xFF8AA095),
                  ),
                ],
              ),
            ),
            if (text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: Text(
                  text,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: Color(0xFF405148),
                  ),
                ),
              ),
            if (mediaUrl.isNotEmpty)
              AspectRatio(
                aspectRatio: 1.55,
                child: Image.network(
                  mediaUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const _MediaFallback(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.favorite_border_rounded,
                    size: 17,
                    color: Color(0xFF6C7C73),
                  ),
                  const SizedBox(width: 4),
                  Text('${_number('likesCount')}'),
                  const SizedBox(width: 14),
                  const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 16,
                    color: Color(0xFF6C7C73),
                  ),
                  const SizedBox(width: 4),
                  Text('${_number('commentsCount')}'),
                  const Spacer(),
                  const Text(
                    'View',
                    style: TextStyle(
                      color: _ProfileColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileReelCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _ProfileReelCard({
    required this.data,
    required this.onTap,
  });

  String get _url => '${data['cloudinaryUrl'] ?? ''}'.trim();
  String get _title =>
      '${data['title'] ?? data['caption'] ?? 'Farming Reel'}'.trim();

  int _number(String key) {
    final dynamic value = data[key];
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF183126),
          borderRadius: BorderRadius.circular(18),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            if (_url.isNotEmpty)
              _ReelPreview(url: _url)
            else
              const _MediaFallback(
                icon: Icons.play_circle_outline_rounded,
                dark: true,
              ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Colors.transparent,
                    Color(0xCC08130D),
                  ],
                ),
              ),
            ),
            const Center(
              child: CircleAvatar(
                radius: 23,
                backgroundColor: Color(0xB3FFFFFF),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: _ProfileColors.primary,
                  size: 30,
                ),
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _title.isEmpty ? 'Farming Reel' : _title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${_number('likesCount')}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.visibility_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${_number('viewsCount')}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReelPreview extends StatefulWidget {
  final String url;

  const _ReelPreview({required this.url});

  @override
  State<_ReelPreview> createState() => _ReelPreviewState();
}

class _ReelPreviewState extends State<_ReelPreview> {
  late final VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    unawaited(_init());
  }

  Future<void> _init() async {
    try {
      await _controller.initialize();
      await _controller.setLooping(true);
      await _controller.setVolume(0);
      await _controller.play();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white,
        ),
      );
    }
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _controller.value.size.width,
        height: _controller.value.size.height,
        child: VideoPlayer(_controller),
      ),
    );
  }
}

class _ProfilePostViewer extends StatelessWidget {
  final Map<String, dynamic> data;

  const _ProfilePostViewer({required this.data});

  String get _text => '${data['text'] ?? data['content'] ?? ''}'.trim();
  String get _mediaUrl =>
      '${data['mediaUrl'] ?? data['imageUrl'] ?? ''}'.trim();
  String get _author =>
      '${data['authorName'] ?? data['displayName'] ?? 'Farmer'}';
  String get _userId =>
      '${data['authorUserId'] ?? data['userId'] ?? ''}'.trim();

  int _number(String key) {
    final dynamic value = data[key];
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ProfileColors.background,
      appBar: AppBar(
        title: const Text(
          'Post',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: <Widget>[
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    _Avatar(
                      url: '${data['authorPhotoUrl'] ?? data['photoUrl'] ?? ''}',
                      name: _author,
                      size: 44,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            _author,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (_userId.isNotEmpty)
                            Text(
                              '@$_userId',
                              style: const TextStyle(
                                color: _ProfileColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => SharePlus.instance.share(
                        ShareParams(
                          text: _text.isEmpty
                              ? 'AgriAI farming post by $_author'
                              : _text,
                        ),
                      ),
                      icon: const Icon(Icons.share_rounded),
                    ),
                  ],
                ),
                if (_text.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 16),
                  Text(
                    _text,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ],
                if (_mediaUrl.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      _mediaUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const _MediaFallback(),
                    ),
                  ),
                ],
                const SizedBox(height: 15),
                Row(
                  children: <Widget>[
                    const Icon(Icons.favorite_border_rounded, size: 19),
                    const SizedBox(width: 5),
                    Text('${_number('likesCount')} likes'),
                    const SizedBox(width: 18),
                    const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                    const SizedBox(width: 5),
                    Text('${_number('commentsCount')} comments'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileReelViewer extends StatefulWidget {
  final List<Map<String, dynamic>> videos;
  final int initialIndex;

  const _ProfileReelViewer({
    required this.videos,
    required this.initialIndex,
  });

  @override
  State<_ProfileReelViewer> createState() => _ProfileReelViewerState();
}

class _ProfileReelViewerState extends State<_ProfileReelViewer> {
  late final PageController _pageController;
  final Map<int, VideoPlayerController> _controllers =
      <int, VideoPlayerController>{};
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.videos.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
    unawaited(_prepare(_currentIndex));
  }

  Future<void> _prepare(int index) async {
    if (index < 0 || index >= widget.videos.length) return;
    if (_controllers.containsKey(index)) return;

    final String url = '${widget.videos[index]['cloudinaryUrl'] ?? ''}'.trim();
    if (url.isEmpty) return;

    final VideoPlayerController controller =
        VideoPlayerController.networkUrl(Uri.parse(url));
    _controllers[index] = controller;

    try {
      await controller.initialize();
      await controller.setLooping(true);
      if (index == _currentIndex) {
        await controller.play();
      }
      if (mounted) setState(() {});
    } catch (_) {
      await controller.dispose();
      _controllers.remove(index);
    }

    for (final int oldIndex in _controllers.keys.toList()) {
      if ((oldIndex - _currentIndex).abs() > 1) {
        await _controllers.remove(oldIndex)?.dispose();
      }
    }
  }

  Future<void> _changeIndex(int index) async {
    final VideoPlayerController? old = _controllers[_currentIndex];
    await old?.pause();

    setState(() => _currentIndex = index);
    await _prepare(index);

    final VideoPlayerController? controller = _controllers[index];
    if (controller != null && controller.value.isInitialized) {
      await controller.play();
    }
    if (index + 1 < widget.videos.length) {
      unawaited(_prepare(index + 1));
    }
    if (index - 1 >= 0) {
      unawaited(_prepare(index - 1));
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final VideoPlayerController controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videos.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No Reels available.')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: widget.videos.length,
        onPageChanged: _changeIndex,
        itemBuilder: (BuildContext context, int index) {
          return _ViewerPage(
            data: widget.videos[index],
            controller: _controllers[index],
            onTogglePlay: () {
              final VideoPlayerController? controller = _controllers[index];
              if (controller == null) return;
              if (controller.value.isPlaying) {
                controller.pause();
              } else {
                controller.play();
              }
              setState(() {});
            },
          );
        },
      ),
    );
  }
}

class _ViewerPage extends StatelessWidget {
  final Map<String, dynamic> data;
  final VideoPlayerController? controller;
  final VoidCallback onTogglePlay;

  const _ViewerPage({
    required this.data,
    required this.controller,
    required this.onTogglePlay,
  });

  @override
  Widget build(BuildContext context) {
    final String title =
        '${data['title'] ?? data['caption'] ?? 'Farming Reel'}'.trim();
    final String author =
        '${data['author'] ?? data['displayName'] ?? 'Farmer'}'.trim();
    final String userId =
        '${data['userId'] ?? data['authorUserId'] ?? ''}'.trim();
    final int likes = _valueAsInt(data['likesCount']);
    final int views = _valueAsInt(data['viewsCount']);

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        GestureDetector(
          onTap: onTogglePlay,
          child: controller != null && controller!.value.isInitialized
              ? FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: controller!.value.size.width,
                    height: controller!.value.size.height,
                    child: VideoPlayer(controller!),
                  ),
                )
              : const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
        ),
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color(0x66000000),
                  Colors.transparent,
                  Color(0xDD000000),
                ],
                stops: <double>[0, 0.48, 1],
              ),
            ),
          ),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ),
        Positioned(
          left: 18,
          right: 88,
          bottom: 30,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  _Avatar(
                    url: '${data['photoUrl'] ?? data['authorPhotoUrl'] ?? ''}',
                    name: author,
                    size: 42,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '@${userId.isEmpty ? author : userId}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title.isEmpty ? 'Farming Reel' : title,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.35,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.favorite_rounded,
                    color: Colors.white,
                    size: 17,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$likes',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Icon(
                    Icons.visibility_rounded,
                    color: Colors.white,
                    size: 17,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$views',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          right: 15,
          bottom: 30,
          child: Column(
            children: <Widget>[
              _ViewerButton(
                icon: controller?.value.isPlaying == true
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                label: '',
                onTap: onTogglePlay,
              ),
              const SizedBox(height: 12),
              _ViewerButton(
                icon: Icons.share_rounded,
                label: 'Share',
                onTap: () => SharePlus.instance.share(
                  ShareParams(
                    text: '$title\nShared from AgriAI',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ViewerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ViewerButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Material(
          color: Colors.white.withValues(alpha: 0.16),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
          ),
        ),
        if (label.isNotEmpty) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String url;
  final String name;
  final double size;

  const _Avatar({
    required this.url,
    required this.name,
    required this.size,
  });

  String get _initial {
    final String value = name.trim();
    return value.isEmpty ? 'F' : value.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFE4F2E8),
        border: Border.all(color: const Color(0xFFD5E8DA)),
      ),
      clipBehavior: Clip.antiAlias,
      child: url.trim().isEmpty
          ? Center(
              child: Text(
                _initial,
                style: TextStyle(
                  color: _ProfileColors.primary,
                  fontSize: size * 0.35,
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Center(
                child: Text(
                  _initial,
                  style: TextStyle(
                    color: _ProfileColors.primary,
                    fontSize: size * 0.35,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
    );
  }
}

class _MediaFallback extends StatelessWidget {
  final IconData icon;
  final bool dark;

  const _MediaFallback({
    this.icon = Icons.image_not_supported_rounded,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: dark ? const Color(0xFF14271E) : const Color(0xFFEAF3ED),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: 42,
        color: dark ? Colors.white70 : _ProfileColors.primary,
      ),
    );
  }
}

class _ContentMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ContentMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 36, color: _ProfileColors.primary),
            const SizedBox(height: 9),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF788980),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE3ECE6)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CardHeading extends StatelessWidget {
  final IconData icon;
  final String title;

  const _CardHeading({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFE9F5ED),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            icon,
            color: _ProfileColors.primary,
            size: 18,
          ),
        ),
        const SizedBox(width: 9),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Stream<int> stream;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.stream,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE3ECE6)),
      ),
      child: StreamBuilder<int>(
        stream: stream,
        builder: (
          BuildContext context,
          AsyncSnapshot<int> snapshot,
        ) {
          return Column(
            children: <Widget>[
              Icon(icon, color: _ProfileColors.primary, size: 20),
              const SizedBox(height: 4),
              Text(
                '${snapshot.data ?? 0}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF73847B),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          );
        },
      ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool last;

  const _DetailRow({
    required this.icon,
    required this.title,
    required this.value,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: _ProfileColors.primary),
          const SizedBox(width: 9),
          SizedBox(
            width: 72,
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF7B8A82),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF34463C),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.color = _ProfileColors.primary,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: color.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF7B8B82),
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),
              ?trailing,
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                color: color.withValues(alpha: 0.65),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileColors {
  static const Color primary = Color(0xFF1B7F45);
  static const Color background = Color(0xFFF5F8F6);
}

int _valueAsInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}
