// lib/providers/business_card_provider.dart
// State management class handling business card data operations with Firebase Firestore, including loading and adding cards.
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/business_card.dart';
import '../services/s3_service.dart';

class BusinessCardProvider extends ChangeNotifier {
  StreamSubscription<QuerySnapshot>? _cardsSubscription;
  final _firestore = FirebaseFirestore.instance;
  final _s3Service = S3Service();

  List<BusinessCard> _allCards = [];
  List<BusinessCard> _filteredCards = [];
  String _searchQuery = '';
  String? _selectedCountry;
  String? _selectedDepartment;
  String? _selectedSeniority;
  String _sortBy = 'dateNewest';

  List<BusinessCard> get cards => _filteredCards;

  Future<void> loadCards(String userId) async {
    try {
      // Cancel existing subscription if any
      await _cardsSubscription?.cancel();
      
      // Set up real-time listener
      _cardsSubscription = _firestore
          .collection('businessCards')
          .doc(userId)
          .collection('cards')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen((snapshot) {
        _allCards = snapshot.docs.map((doc) {
          final data = doc.data();
          final convertedData = {
            ...data,
            'phone': (data['phone'] as List?)?.map((e) => e.toString()).toList() ?? <String>[],
            'email': (data['email'] as List?)?.map((e) => e.toString()).toList() ?? <String>[],
            'social_media_personal': Map<String, String>.from(data['social_media_personal'] ?? {}),
            'social_media_company': Map<String, String>.from(data['social_media_company'] ?? {})
          };
          return BusinessCard.fromMap(convertedData, id: doc.id);
        }).toList();
        
        _applyFilters();
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Error loading cards: $e');
      rethrow;
    }
  }

  Future<void> addCard(BusinessCard card, String userId) async {
    try {
      final doc = await _firestore
          .collection('businessCards')
          .doc(userId)
          .collection('cards')
          .add(card.toMap());
          
      final newCard = BusinessCard.fromMap(card.toMap(), id: doc.id);
      _allCards.insert(0, newCard);
      _applyFilters();
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding card: $e');
      rethrow;
    }
  }

  void updateSearch(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void updateFilters({
    String? country,
    String? department,
    String? seniority,
    String? sortBy,
  }) {
    _selectedCountry = country;
    _selectedDepartment = department;
    _selectedSeniority = seniority;
    if (sortBy != null) _sortBy = sortBy;
    _applyFilters();
  }

  void _applyFilters() {
    _filteredCards = _allCards.where((card) {
      if (_searchQuery.isNotEmpty) {
        final searchLower = _searchQuery.toLowerCase();
        if (!card.name.toLowerCase().contains(searchLower) &&
            !card.title.toLowerCase().contains(searchLower) &&
            !card.brandName.toLowerCase().contains(searchLower)) {
          return false;
        }
      }
      
      if (_selectedCountry != null && card.country != _selectedCountry) return false;
      if (_selectedDepartment != null && card.departmentDivision != _selectedDepartment) return false;
      if (_selectedSeniority != null && card.jobSeniority != _selectedSeniority) return false;
      
      return true;
    }).toList();

    // Apply sorting
    switch (_sortBy) {
      case 'dateNewest':
        _filteredCards.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'dateOldest':
        _filteredCards.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'nameAZ':
        _filteredCards.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'nameZA':
        _filteredCards.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 'seniorityHigh':
        _filteredCards.sort((a, b) => _getSeniorityWeight(b.jobSeniority).compareTo(_getSeniorityWeight(a.jobSeniority)));
        break;
      case 'seniorityLow':
        _filteredCards.sort((a, b) => _getSeniorityWeight(a.jobSeniority).compareTo(_getSeniorityWeight(b.jobSeniority)));
        break;
    }
    
    notifyListeners();
  }

  int _getSeniorityWeight(String seniority) {
    const weights = {
      'C-Suite': 6,
      'Executive': 5,
      'Senior Management': 4,
      'Mid Level': 3,
      'Entry Level': 2,
      'Intern': 1,
      'Others': 0,
    };
    return weights[seniority] ?? 0;
  }

  Future<void> deleteCard(String cardId, String imageUrl, String userId) async {
    try {
      final cardDoc = await _firestore
          .collection('businessCards')
          .doc(userId)
          .collection('cards')
          .doc(cardId)
          .get();

      if (cardDoc.exists) {
        final fileUrl = cardDoc.data()?['fileUrl'] as String?;
        
        if (fileUrl != null && fileUrl.isNotEmpty) {
          await _s3Service.deleteFile(fileUrl);  // Pass the complete URL
        }
      }

      await _firestore
          .collection('businessCards')
          .doc(userId)
          .collection('cards')
          .doc(cardId)
          .delete();
      
      _allCards.removeWhere((card) => card.id == cardId);
      _applyFilters();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting card: $e');
      rethrow;
    }
  }
  
  void clearFilters() {
    _searchQuery = '';
    _selectedCountry = null;
    _selectedDepartment = null;
    _selectedSeniority = null;
    _sortBy = 'dateNewest';
    _applyFilters();
  }
  
  Future<void> updateCardTags(String userId, String cardId, List<String> tags) async {
    try {
      await _firestore
          .collection('businessCards')
          .doc(userId)
          .collection('cards')
          .doc(cardId)
          .update({'tags': tags});
      
      // Update local state immediately
      final cardIndex = _allCards.indexWhere((card) => card.id == cardId);
      if (cardIndex != -1) {
        final updatedCard = BusinessCard.fromMap({
          ..._allCards[cardIndex].toMap(),
          'tags': tags,
        }, id: cardId);
        
        _allCards[cardIndex] = updatedCard;
        _applyFilters(); // Re-apply filters to update filtered cards
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating card tags: $e');
      rethrow;
    }
  }

  Future<void> updateCardNotes(String userId, String cardId, String notes) async {
    try {
      await _firestore
          .collection('businessCards')
          .doc(userId)
          .collection('cards')
          .doc(cardId)
          .update({
            'notes': notes,
            'createdAt': FieldValue.serverTimestamp(), // Ensure timestamp is Firestore compatible
          });
      
      // Update local state
      final cardIndex = _allCards.indexWhere((card) => card.id == cardId);
      if (cardIndex != -1) {
        final updatedCard = BusinessCard.fromMap({
          ..._allCards[cardIndex].toMap(),
          'notes': notes,
          'createdAt': Timestamp.now(), // Use Firestore Timestamp
        }, id: cardId);
        
        _allCards[cardIndex] = updatedCard;
        _applyFilters();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating card notes: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _cardsSubscription?.cancel();
    super.dispose();
  }
}