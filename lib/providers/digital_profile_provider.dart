// lib/providers/digital_profile_provider.dart
// Under TAPP! Global Flutter Project
import 'package:flutter/material.dart';
import '../models/social_platform.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SocialPlatformData {
  final String id;
  final String value;
  final int sequence;

  SocialPlatformData({
    required this.id,
    required this.value,
    required this.sequence,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'value': value,
        'sequence': sequence,
      };
}

class DigitalProfileData {
  String id;
  String userId;
  String username;
  String? displayName;
  String? bio;
  String? location;
  String? jobTitle;
  String? companyName;
  String? profileImageUrl;
  String? companyImageUrl;
  String? bannerImageUrl;
  List<SocialPlatform> socialPlatforms;
  DateTime? createdAt;
  DateTime? updatedAt;

  DigitalProfileData({
    required this.id,
    required this.userId,
    required this.username,
    this.displayName,
    this.bio,
    this.location,
    this.jobTitle,
    this.companyName,
    this.profileImageUrl,
    this.companyImageUrl,
    this.bannerImageUrl,
    this.socialPlatforms = const [],
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'displayName': displayName,
      'bio': bio,
      'location': location,
      'jobTitle': jobTitle,
      'companyName': companyName,
      'profileImageUrl': profileImageUrl,
      'companyImageUrl': companyImageUrl,
      'bannerImageUrl': bannerImageUrl,
      'socialPlatforms': socialPlatforms.map((p) => p.toMap()).toList(),
      'createdAt':
          createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
  }

  factory DigitalProfileData.fromMap(String id, Map<String, dynamic> map) {
    return DigitalProfileData(
      id: id,
      userId: map['userId'],
      username: map['username'],
      displayName: map['displayName'],
      bio: map['bio'],
      location: map['location'],
      jobTitle: map['jobTitle'],
      companyName: map['companyName'],
      profileImageUrl: map['profileImageUrl'],
      companyImageUrl: map['companyImageUrl'],
      bannerImageUrl: map['bannerImageUrl'],
      socialPlatforms: (map['socialPlatforms'] as List?)
              ?.map((p) => SocialPlatform.fromMap(p))
              .toList() ??
          [],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

class DigitalProfileProvider extends ChangeNotifier {
  DigitalProfileData _profileData = DigitalProfileData(
    id: '',
    userId: '',
    username: '',
  );
  bool _isDirty = false;

  DigitalProfileData get profileData => _profileData;
  bool get isDirty => _isDirty;

  void updateProfile({
    String? username,
    String? displayName,
    String? location,
    String? jobTitle,
    String? companyName,
    String? bio,
    String? profileImageUrl,
    String? companyImageUrl,
    String? bannerImageUrl,
  }) async {
    _profileData = DigitalProfileData(
      id: _profileData.id,
      userId: _profileData.userId,
      username: username ?? _profileData.username,
      displayName: displayName ?? _profileData.displayName,
      bio: bio ?? _profileData.bio,
      location: location ?? _profileData.location,
      jobTitle: jobTitle ?? _profileData.jobTitle,
      companyName: companyName ?? _profileData.companyName,
      profileImageUrl: profileImageUrl ?? _profileData.profileImageUrl,
      companyImageUrl: companyImageUrl ?? _profileData.companyImageUrl,
      bannerImageUrl: bannerImageUrl ?? _profileData.bannerImageUrl,
      socialPlatforms: _profileData.socialPlatforms,
      createdAt: _profileData.createdAt,
      updatedAt: _profileData.updatedAt,
    );
    _isDirty = true;
    notifyListeners();

    try {
      await saveProfile();
    } catch (e) {
      debugPrint('Auto-save failed: $e');
    }
  }

  Future<String?> checkUsernameAvailability(String username) async {
    if (!RegExp(r'^[a-z0-9]{6,30}$').hasMatch(username)) {
      return 'Username must be 6-30 characters long and contain only lowercase letters and numbers';
    }

    final doc = await FirebaseFirestore.instance
        .collection('usernames')
        .doc(username)
        .get();

    return doc.exists ? 'Username already taken' : null;
  }

  Future<String?> reserveUsername(String username) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return null;

    final batch = FirebaseFirestore.instance.batch();

    final profileRef = FirebaseFirestore.instance.collection('digitalProfiles').doc();

    final profile = DigitalProfileData(
      id: profileRef.id,
      userId: userId,
      username: username,
      displayName: "",
      bio: "",
      location: "",
      jobTitle: "",
      companyName: "",
      profileImageUrl: "",
      companyImageUrl: "",
      bannerImageUrl: "",
      socialPlatforms: [],
    );

    final usernameRef = FirebaseFirestore.instance.collection('usernames').doc(username);
    batch.set(usernameRef, {
      'userId': userId,
      'profileId': profileRef.id,
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.set(profileRef, profile.toMap());

    try {
      await batch.commit();
      return profileRef.id;
    } catch (e) {
      return null;
    }
  }

  void updateSocialPlatforms(List<SocialPlatform> platforms) {
    final platformsWithSequence = platforms.asMap().entries.map((entry) {
      return SocialPlatformData(
        id: entry.value.id,
        value: entry.value.value ?? '',
        sequence: entry.key + 1,
      );
    }).toList();

    _profileData.socialPlatforms = platforms;
    _isDirty = true;

    FirebaseFirestore.instance
        .collection('digitalProfiles')
        .doc(_profileData.id)
        .update({
      'socialPlatforms': platformsWithSequence.map((p) => p.toMap()).toList()
    });

    notifyListeners();
  }

  Future<void> saveProfile() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      final profileRef = FirebaseFirestore.instance
          .collection('digitalProfiles')
          .doc(_profileData.id);

      _profileData = _profileData.copyWith(
        updatedAt: DateTime.now(),
      );

      await profileRef.set(_profileData.toMap(), SetOptions(merge: true));

      _isDirty = false;
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to save profile: $e');
    }
  }

  Future<void> loadProfile(String profileId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('digitalProfiles')
          .doc(profileId)
          .get();

      if (doc.exists) {
        _profileData = DigitalProfileData.fromMap(doc.id, doc.data()!);
        notifyListeners();
      }
    } catch (e) {
      throw Exception('Failed to load profile: $e');
    }
  }

  Stream<List<DigitalProfileData>> getProfilesStream() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return FirebaseFirestore.instance
        .collection('digitalProfiles')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DigitalProfileData.fromMap(doc.id, doc.data()))
            .toList());
  }
}

extension DigitalProfileDataExtension on DigitalProfileData {
  DigitalProfileData copyWith({
    String? id,
    String? userId,
    String? username,
    String? displayName,
    String? bio,
    String? location,
    String? jobTitle,
    String? companyName,
    String? profileImageUrl,
    String? companyImageUrl,
    String? bannerImageUrl,
    List<SocialPlatform>? socialPlatforms,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DigitalProfileData(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      jobTitle: jobTitle ?? this.jobTitle,
      companyName: companyName ?? this.companyName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      companyImageUrl: companyImageUrl ?? this.companyImageUrl,
      bannerImageUrl: bannerImageUrl ?? this.bannerImageUrl,
      socialPlatforms: socialPlatforms ?? this.socialPlatforms,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}