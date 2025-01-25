// lib/models/business_card.dart
// Data model class defining the structure and properties of a business card with fields like name, title, contact info, and company details.
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final String imageUrl;
  final DateTime createdAt;

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
    required this.imageUrl,
    required this.createdAt,
  });

  factory BusinessCard.fromMap(Map<String, dynamic> map, {String? id}) {
    return BusinessCard(
      id: id ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      title: map['title'] ?? '',
      jobSeniority: map['job_seniority'] ?? '',
      departmentDivision: map['department_division'] ?? '',
      country: map['country'] ?? '',
      phone: List<String>.from(map['phone'] ?? []),
      email: List<String>.from(map['email'] ?? []),
      brandName: map['brand_name'] ?? '',
      legalName: map['legal_name'] ?? '',
      address: map['address'] ?? '',
      website: map['website'] ?? '',
      socialMediaPersonal: Map<String, String>.from(map['social_media_personal'] ?? {}),
      socialMediaCompany: Map<String, String>.from(map['social_media_company'] ?? {}),
      imageUrl: map['imageUrl'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'title': title,
      'job_seniority': jobSeniority,
      'department_division': departmentDivision,
      'country': country,
      'phone': phone,
      'email': email,
      'brand_name': brandName,
      'legal_name': legalName,
      'address': address,
      'website': website,
      'social_media_personal': socialMediaPersonal,
      'social_media_company': socialMediaCompany,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
    };
  }
}