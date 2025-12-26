import 'package:flutter/material.dart';

/// Article class model for article-related functionality
class Article {
  final String id;
  final String title;
  final String content;
  final String authorName;
  final String category;
  final DateTime publishDate;
  final String? imageUrl;
  bool isFavorite;

  Article({
    required this.id,
    required this.title,
    required this.content,
    required this.authorName,
    required this.category,
    required this.publishDate,
    this.imageUrl,
    this.isFavorite = false,
  });
}