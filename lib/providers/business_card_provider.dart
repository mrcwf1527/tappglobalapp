// lib/providers/business_card_provider.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/business_card.dart';

class BusinessCardProvider extends ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  List<BusinessCard> _cards = [];

  List<BusinessCard> get cards => _cards;

  Future<void> loadCards(String userId) async {
    final snapshot = await _firestore
        .collection('businessCards')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    _cards = snapshot.docs
        .map((doc) => BusinessCard.fromMap(doc.data(), id: doc.id))
        .toList();
    notifyListeners();
  }

  Future<void> addCard(BusinessCard card) async {
    final doc = await _firestore.collection('businessCards').add(card.toMap());
    final newCard = BusinessCard.fromMap(card.toMap(), id: doc.id);
    _cards.insert(0, newCard);
    notifyListeners();
  }
}