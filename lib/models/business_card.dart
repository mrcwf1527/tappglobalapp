// lib/models/business_card.dart
// Data model class defining the structure and properties of a business card with fields like name, title, contact info, and company details.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class BusinessCard {
  final String id;
  final String userId;
  final String name;
  final String title;
  final String jobSeniority;
  final String departmentDivision;
  final String country;
  final List<String> phone;
  final List<String> email;
  final String brandName;
  final String legalName;
  final String address;
  final String website;
  final Map<String, String> socialMediaPersonal;
  final Map<String, String> socialMediaCompany;
  final String fileUrl;
  final DateTime createdAt;
  final List<String> tags;  // Added tags field
  final String notes;       // Added notes field

  BusinessCard({
    required this.id,
    required this.userId,
    required this.name,
    required this.title,
    required this.jobSeniority,
    required this.departmentDivision,
    required this.country,
    required this.phone,
    required this.email,
    required this.brandName,
    required this.legalName,
    required this.address,
    required this.website,
    required this.socialMediaPersonal,
    required this.socialMediaCompany,
    required this.fileUrl,
    required this.createdAt,
    this.tags = const [], // Initialize tags with an empty list by default
    this.notes = '',      // Initialize notes with an empty string by default
  });

  factory BusinessCard.fromMap(Map<String, dynamic> map, {String? id}) {
    List<String> convertToStringList(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        try {
          return value.map((e) => e.toString()).toList();
        } catch (e) {
          return value.toString().split(',');
        }
      }
      return [value.toString()];
    }

    Map<String, String> convertToStringMap(dynamic value) {
      if (value == null || value is! Map) return {};
      return Map<String, String>.fromEntries(
        value.entries.map((e) => MapEntry(e.key.toString(), e.value?.toString() ?? ''))
      );
    }

    try {
      return BusinessCard(
        id: id ?? '',
        userId: map['userId']?.toString() ?? '',
        name: map['name']?.toString() ?? '',
        title: map['title']?.toString() ?? '',
        jobSeniority: map['job_seniority']?.toString() ?? '',
        departmentDivision: map['department_division']?.toString() ?? '',
        country: map['country']?.toString() ?? '',
        phone: convertToStringList(map['phone']),
        email: convertToStringList(map['email']),
        brandName: map['brand_name']?.toString() ?? '',
        legalName: map['legal_name']?.toString() ?? '',
        address: map['address']?.toString() ?? '',
        website: map['website']?.toString() ?? '',
        socialMediaPersonal: convertToStringMap(map['social_media_personal']),
        socialMediaCompany: convertToStringMap(map['social_media_company']),
        fileUrl: map['fileUrl']?.toString() ?? '',
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        tags: List<String>.from(map['tags'] ?? []), // Load tags from the map
        notes: map['notes']?.toString() ?? '',     // Load notes from the map
      );
    } catch (e) {
      debugPrint('Error in fromMap: ${e.toString()}');
      debugPrint('Raw data: ${map.toString()}');
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'title': title,
      'job_seniority': jobSeniority,
      'department_division': departmentDivision,
      'country': country,
      'phone': phone.map((e) => e.toString()).toList(),
      'email': email.map((e) => e.toString()).toList(),
      'brand_name': brandName,
      'legal_name': legalName,
      'address': address,
      'website': website,
      'social_media_personal': Map<String, String>.from(socialMediaPersonal),
      'social_media_company': Map<String, String>.from(socialMediaCompany),
      'fileUrl': fileUrl,
      'createdAt': createdAt,
      'tags': tags,        // Save tags to the map
      'notes': notes,      // Save notes to the map
    };
  }
}