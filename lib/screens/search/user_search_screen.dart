import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Timer? _debounce;
  bool _loading = false;
  List<_UserResult> _results = <_UserResult>[];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();

    _debounce = Timer(
      const Duration(milliseconds: 350),
      _search,
    );
  }

  Future<void> _search() async {
    final String query = _controller.text
        .trim()
        .toLowerCase()
        .replaceFirst('@', '');

    if (query.isEmpty) {
      if (!mounted) {
        return;
      }

      setState(() {
        _results = <_UserResult>[];
        _loading = false;
      });

      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _firestore
              .collection('users')
              .where(
                'userIdLower',
                isGreaterThanOrEqualTo: query,
              )
              .where(
                'userIdLower',
                isLessThan: '$query\uf8ff',
              )
              .limit(20)
              .get();

      final List<_UserResult> results = snapshot.docs
          .map((doc) => _UserResult.fromDocument(doc))
          .toList();

      if (!mounted) {
        return;
      }

      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Search is unavailable right now.',
          ),
        ),
      );
    }
  }

  void _clearSearch() {
    _debounce?.cancel();

    _controller.clear();

    setState(() {
      _results = <_UserResult>[];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Find Farmers'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
          18,
          8,
          18,
          20,
        ),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _controller,
              autofocus: true,
              onChanged: _onChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search name or @UserID',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                ),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: _clearSearch,
                        icon: const Icon(
                          Icons.clear_rounded,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const LinearProgressIndicator(
                minHeight: 2,
              )
            else if (_results.isEmpty &&
                _controller.text.trim().isNotEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'No farmers found.',
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: _results.length,
                  separatorBuilder: (
                    BuildContext context,
                    int index,
                  ) {
                    return const SizedBox(height: 10);
                  },
                  itemBuilder: (
                    BuildContext context,
                    int index,
                  ) {
                    return _UserTile(
                      user: _results[index],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final _UserResult user;

  const _UserTile({
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 25,
            backgroundColor: AppColors.cardGreen,
            backgroundImage: user.photoUrl.isEmpty
                ? null
                : NetworkImage(user.photoUrl),
            child: user.photoUrl.isEmpty
                ? const Icon(
                    Icons.person_rounded,
                    color: AppColors.primary,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  user.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '@${user.userId}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (user.location.isNotEmpty)
                  Text(
                    user.location,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Connect with @${user.userId} will be enabled next.',
                  ),
                ),
              );
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }
}

class _UserResult {
  final String name;
  final String userId;
  final String photoUrl;
  final String location;

  const _UserResult({
    required this.name,
    required this.userId,
    required this.photoUrl,
    required this.location,
  });

  factory _UserResult.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> data =
        doc.data() ?? <String, dynamic>{};

    return _UserResult(
      name: '${data['displayName'] ?? data['name'] ?? 'Farmer'}',
      userId: '${data['userId'] ?? ''}',
      photoUrl: '${data['photoUrl'] ?? ''}',
      location: '${data['location'] ?? ''}',
    );
  }
}