// lib/services/gemini_service.dart
// Service using Google's Gemini AI to extract structured business card information from images with specific formatting rules.
import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  
  late final FirebaseRemoteConfig _remoteConfig;
  
  GeminiService._internal() {
    _remoteConfig = FirebaseRemoteConfig.instance;
  }

  Future<void> initialize() async {
    await _remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: Duration.zero, // For development
    ));
    
    await _remoteConfig.setDefaults({
      'gemini_api_key': '',
    });
    
    try {
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      debugPrint('Error fetching remote config: $e');
    }
  }

  Future<List<Map<String, dynamic>>> extractBusinessCard(Uint8List imageBytes) async {
    final apiKey = _remoteConfig.getString('gemini_api_key');
    if (apiKey.isEmpty) throw Exception('Gemini API key not configured');
        
    final model = GenerativeModel(
      model: 'gemini-2.0-flash-exp',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.3,
        topK: 40,
        topP: 0.9,
        maxOutputTokens: 2048,
      ),
      systemInstruction: Content.system(_getSystemPrompt()),
    );

    final chat = model.startChat();
    final content = Content.multi([
      TextPart('Extract information from this business card:'),
      DataPart('image/jpeg', imageBytes),
    ]);

    final response = await chat.sendMessage(content);
    final jsonStr = response.text?.replaceAll('```json', '').replaceAll('```', '');
    
    if (jsonStr == null || jsonStr.isEmpty) {
      throw Exception('Failed to extract information from image');
    }

    try {
      final decoded = json.decode(jsonStr);
      return decoded is List 
          ? List<Map<String, dynamic>>.from(decoded)
          : [Map<String, dynamic>.from(decoded)];
    } catch (e) {
      throw Exception('Invalid response format: $e');
    }
  }

  Future<List<Map<String, dynamic>>> extractFromPDF(Uint8List pdfBytes) async {
    final apiKey = _remoteConfig.getString('gemini_api_key');
    if (apiKey.isEmpty) throw Exception('Gemini API key not configured');
    
    final model = GenerativeModel(
      model: 'gemini-2.0-flash-exp',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.3,
        topK: 40,
        topP: 0.9,
        maxOutputTokens: 2048,
      ),
      systemInstruction: Content.system(_getSystemPrompt()),
    );
    debugPrint('Model initialized');

    final chat = model.startChat();
    final content = Content.multi([
      TextPart('Extract information from this business card:'),
      DataPart('application/pdf', pdfBytes),
    ]);

    debugPrint('Sending request to Gemini...');
    final response = await chat.sendMessage(content);
    debugPrint('Raw response: ${response.text}');

    final jsonStr = response.text?.replaceAll('```json', '').replaceAll('```', '');
    if (jsonStr == null || jsonStr.isEmpty) {
      throw Exception('Failed to extract information from pdf file');
    }

    debugPrint('Parsing JSON...');
    try {
      final decoded = json.decode(jsonStr);
      return decoded is List 
        ? List<Map<String, dynamic>>.from(decoded)
        : [Map<String, dynamic>.from(decoded)];
    } catch (e) {
      throw Exception('Invalid response format: $e');
    }
  }

  String _getSystemPrompt() => '''You are an expert system for extracting information from business name cards. Analyze images and extract information in strict JSON format without additional messages.\n\nExtract and format:\n1. name: Capitalize the first letter of each word\n2. title: \n   - Keep short forms in ALL CAPS (CEO, CTO, CFO, COO, CMO, CIO, etc.)\n   - For full titles, capitalize first letter only (Director, Manager, Engineer, etc.)\n3. job_seniority: Select ONE:\n   - Intern\n   - Entry Level\n   - Mid Level \n   - Senior Management\n   - Executive\n   - C-Suite\n   - Others\n4. department_division: Select ONE:\n   - Sales\n   - Marketing\n   - Operations\n   - Finance\n   - Human Resources\n   - Information Technology\n   - Research & Development\n   - Customer Service\n   - Legal\n   - Administration\n   - Others\n5. country: Capitalize the first letter of each word\n6. phone: Array of numbers with country code. No spaces/symbols\n7. email: \n   - Keep the original case\n   - Preserve ALL punctuation (periods, hyphens, underscores)\n   - Array format\n   - Return empty array [] if none\n8. brand_name: Keep original case\n9. legal_name: Capitalize the first letter of each word, empty string if same as brand_name\n10. address: \n    - Capitalize the first letter of each word\n    - Combine multi-line addresses into a single line with commas\n    - Array format\n    - Return empty array [] if none\n11. website: \n    - Company website only\n    - Keep the original case\n    - Must start with "https://"\n    - If website not on card but corporate email available, extract domain from email (e.g. "hello@tappglobal.app" → "https://tappglobal.app")\n    - Return empty string "" if none\n12. social_media_personal: \n    - Extract ONLY if explicitly shown on card\n    - DO NOT guess or infer accounts\n    - Return empty object {} if none:\n    - Supported platforms:\nfacebook, instagram, linkedin, twitter, tiktok, telegram, line, wechat, qq, weibo, tumblr, youtube, twitch, threads, red, lemon8\n13. social_media_company: Same rules as personal\n\nNever return null. Use an empty string "", empty array [], or empty object {} instead.\nTranslate all to English except names.\n\nExample output format:\n{\n  "name": "John Smith",\n  "title": "CTO, Co-Founder & Director",\n  "job_seniority": "MID LEVEL",\n  "department_division": "INFORMATION TECHNOLOGY",\n  "country": "Malaysia",\n  "phone": ["+60186669859"],\n  "email": ["john.smith@company.com"],\n  "brand_name": "techCorp",\n  "legal_name": "Technology Corporation Sdn Bhd",\n  "address": ["123 Jalan Wong Ah Fook, 80000 Johor Bahru, Johor, Malaysia"],\n  "website": "https://techcorp.com",\n  "social_media_personal": {\n    "linkedin": "linkedin.com/in/johnsmith",\n    "wechat": "johnsmith888"\n  },\n  "social_media_company": {\n    "facebook": "facebook.com/techcorp",\n    "linkedin": "linkedin.com/company/techcorp"\n  }\n}''';
}