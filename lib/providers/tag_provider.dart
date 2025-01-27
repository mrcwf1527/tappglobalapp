// lib/providers/tag_provider.dart
// State management class that handles CRUD operations for tags in Firestore, maintaining a local list of tags synced with the database.
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tag.dart';

class TagProvider extends ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  List<Tag> _tags = [];
  
  List<Tag> get tags => _tags;

  Future<void> loadTags(String userId) async {
    final snapshot = await _firestore
        .collection('businessCards')
        .doc(userId)
        .collection('tags')
        .get();

    _tags = snapshot.docs
        .map((doc) => Tag.fromMap(doc.data(), doc.id))
        .toList();
    notifyListeners();
  }

  Future<Tag> createTag(String userId, String name, String color) async {
    final docRef = await _firestore
        .collection('businessCards')
        .doc(userId)
        .collection('tags')
        .add({
      'name': name,
      'color': color,
      'userId': userId,
    });

    final tag = Tag(
      id: docRef.id,
      name: name,
      color: color,
      userId: userId,
    );
    
    _tags.add(tag);
    notifyListeners();
    return tag;
  }

  Future<void> updateTag(String userId, String tagId, String name, String color) async {
    await _firestore
        .collection('businessCards')
        .doc(userId)
        .collection('tags')
        .doc(tagId)
        .update({
      'name': name,
      'color': color,
    });

    final index = _tags.indexWhere((tag) => tag.id == tagId);
    if (index != -1) {
      _tags[index] = Tag(
        id: tagId,
        name: name,
        color: color,
        userId: userId,
      );
      notifyListeners();
    }
  }

  Future<void> deleteTag(String userId, String tagId) async {
    // Delete the tag
    await _firestore
        .collection('businessCards')
        .doc(userId)
        .collection('tags')
        .doc(tagId)
        .delete();

    // Get all business cards with this tag
    final cardsRef = _firestore.collection('businessCards').doc(userId).collection('cards');
    final cards = await cardsRef.where('tags', arrayContains: tagId).get();

    // Remove the tag from each card
    final batch = _firestore.batch();
    for (var doc in cards.docs) {
      final updatedTags = List<String>.from(doc.data()['tags'] ?? [])
        ..remove(tagId);
      batch.update(doc.reference, {'tags': updatedTags});
    }
    await batch.commit();

    // Update local state
    _tags.removeWhere((tag) => tag.id == tagId);
    notifyListeners();
  }
}