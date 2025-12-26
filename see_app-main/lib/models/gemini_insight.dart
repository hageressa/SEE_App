import 'package:flutter/material.dart';

/// Model class for Gemini AI-generated content insights
class GeminiInsight {
  final String id;
  final String title;
  final String summary;
  final String fullContent;
  final String source;
  final DateTime publishDate;
  final String? imageUrl;
  bool isFavorite;
  bool isSaved;

  GeminiInsight({
    required this.id,
    required this.title,
    required this.summary,
    required this.fullContent,
    required this.source,
    required this.publishDate,
    this.imageUrl,
    this.isFavorite = false,
    this.isSaved = false,
  });

  /// Create a copy of this insight with modified properties
  GeminiInsight copyWith({
    String? id,
    String? title,
    String? summary,
    String? fullContent,
    String? source,
    DateTime? publishDate,
    String? imageUrl,
    bool? isFavorite,
    bool? isSaved,
  }) {
    return GeminiInsight(
      id: id ?? this.id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      fullContent: fullContent ?? this.fullContent,
      source: source ?? this.source,
      publishDate: publishDate ?? this.publishDate,
      imageUrl: imageUrl ?? this.imageUrl,
      isFavorite: isFavorite ?? this.isFavorite,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}