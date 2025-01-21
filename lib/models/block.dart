// lib/models/block.dart
// Core data model for content blocks in digital profiles. Defines BlockType (website/image/youtube), BlockLayout (classic/carousel), and TextAlignment enums. Contains Block class for managing block properties and BlockContent class for individual content items within blocks. Includes serialization/deserialization logic for Firestore integration.

import 'package:flutter/material.dart';

enum BlockType {
  website,
  image,
  youtube,
  contact,
  text,
  spacer,
  socialPlatform
}

enum BlockLayout {
  classic,
  carousel,
  businessCard,
  iconButton,
  qrCode 
}

enum TextAlignment {
  left,
  center,
  right
}

enum TextBlockStyle {
  heading1,
  heading2,
  heading3,
  paragraph,
  quote
}

class Block {
  final String id;
  final BlockType type;
  final String blockName;
  final String? title;
  final String? description;
  final List<BlockContent> contents;
  final int sequence;
  final bool? isVisible;
  final BlockLayout layout;
  final String? aspectRatio;
  final TextAlignment? textAlignment;
  bool? isCollapsed;

  Block({
    required this.id,
    required this.type,
    required this.blockName,
    this.title,
    this.description,
    required this.contents,
    required this.sequence,
    this.isVisible,
    this.layout = BlockLayout.classic,
    this.aspectRatio,
    this.textAlignment,
    this.isCollapsed = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type.name,
    'blockName': blockName,
    'title': title,
    'description': description,
    'contents': contents.map((c) => c.toMap()).toList(),
    'sequence': sequence,
    'isVisible': isVisible,
    'layout': layout.name,
    'aspectRatio': aspectRatio,
    'textAlignment': textAlignment?.name,
    'isCollapsed': isCollapsed,
  };

  factory Block.fromMap(Map<String, dynamic> map) {
    return Block(
      id: map['id'],
      type: BlockType.values.firstWhere((e) => e.name == map['type']),
      blockName: map['blockName'] ?? '',
      title: map['title'],
      description: map['description'],
      contents: (map['contents'] as List?)?.map((c) => BlockContent.fromMap(c)).toList() ?? [],
      sequence: map['sequence'] ?? 0,
      isVisible: map['isVisible'],
      layout: map['layout'] != null ? BlockLayout.values.firstWhere(
        (e) => e.name == map['layout'], 
        orElse: () => BlockLayout.classic
      ) : BlockLayout.classic,
      aspectRatio: map['aspectRatio'],
      textAlignment: map['textAlignment'] != null ? TextAlignment.values.firstWhere(
        (e) => e.name == map['textAlignment'],
        orElse: () => TextAlignment.left,
      ) : null,
      isCollapsed: map['isCollapsed'] ?? false,
    );
  }

  Block copyWith({
    String? id,
    BlockType? type,
    String? blockName,
    String? title,
    String? description,
    List<BlockContent>? contents,
    required int sequence,
    bool? isVisible,
    BlockLayout? layout,
    String? aspectRatio,
    TextAlignment? textAlignment,
    bool? isCollapsed,
  }) => Block(
    id: id ?? this.id,
    type: type ?? this.type,
    blockName: blockName ?? this.blockName,
    title: title ?? this.title,
    description: description ?? this.description,
    contents: contents ?? this.contents,
    sequence: sequence,
    isVisible: isVisible ?? this.isVisible,
    layout: layout ?? this.layout,
    aspectRatio: aspectRatio ?? this.aspectRatio,
    textAlignment: textAlignment ?? this.textAlignment,
    isCollapsed: isCollapsed ?? this.isCollapsed,
  );
}

class BlockContent {
  final String id;
  final String title;
  final String? subtitle;
  final String url;
  final String? imageUrl;
  final bool isVisible;
  final Map<String, dynamic>? metadata;
  final bool? isPrimaryPhone;
  final bool? isPrimaryEmail;
  final String? firstName;
  final String? lastName;
  final String? jobTitle;
  final String? companyName;
  final TextBlockStyle? textBlockStyle;
  final bool? isBold;
  final bool? isItalic;
  final bool? isUnderlined;
  List<TextSpan>? richTextSpans;
  bool? hasTransparentBackground;
  Map<String, dynamic>? richTextDelta;
  List<TextRange>? textRanges;

  BlockContent({
    required this.id,
    required this.title,
    this.subtitle,
    required this.url,
    this.imageUrl,
    this.isVisible = true,
    this.metadata,
    this.isPrimaryPhone,
    this.isPrimaryEmail,
    this.firstName,
    this.lastName,
    this.jobTitle,
    this.companyName,
    this.textBlockStyle,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderlined = false,
    this.richTextDelta,
    this.textRanges,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'url': url,
    'imageUrl': imageUrl,
    'isVisible': isVisible,
    'metadata': metadata,
    'isPrimaryPhone': isPrimaryPhone,
    'isPrimaryEmail': isPrimaryEmail,
    'firstName': firstName,
    'lastName': lastName,
    'jobTitle': jobTitle,
    'companyName': companyName,
    'textBlockStyle': textBlockStyle?.name,
    'isBold': isBold,
    'isItalic': isItalic,
    'isUnderlined': isUnderlined,
    'richTextDelta': richTextDelta,
    'textRanges': textRanges?.map((r) => r.toMap()).toList(),
  };

  factory BlockContent.fromMap(Map<String, dynamic> map) {
    return BlockContent(
      id: map['id'],
      title: map['title'] ?? '',
      subtitle: map['subtitle'],
      url: map['url'] ?? '',
      imageUrl: map['imageUrl'],
      isVisible: map['isVisible'] ?? true,
      metadata: map['metadata'],
      isPrimaryPhone: map['isPrimaryPhone'],
      isPrimaryEmail: map['isPrimaryEmail'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      jobTitle: map['jobTitle'],
      companyName: map['companyName'],
      textBlockStyle: map['textBlockStyle'] != null 
          ? TextBlockStyle.values.firstWhere(
              (e) => e.name == map['textBlockStyle'],
              orElse: () => TextBlockStyle.paragraph)
          : null,
      isBold: map['isBold'] ?? false,
      isItalic: map['isItalic'] ?? false,
      isUnderlined: map['isUnderlined'] ?? false,
      richTextDelta: map['richTextDelta'],
      textRanges: (map['textRanges'] as List?)?.map((r) => TextRange.fromMap(r)).toList(),
    );
  }

  BlockContent copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? url,
    String? imageUrl,
    bool? isVisible,
    Map<String, dynamic>? metadata,
    bool? isPrimaryPhone,
    bool? isPrimaryEmail,
    String? firstName,
    String? lastName,
    String? jobTitle,
    String? companyName,
    TextBlockStyle? textBlockStyle,
    bool? isBold,
    bool? isItalic,
    bool? isUnderlined,
    List<TextRange>? textRanges,
  }) => BlockContent(
    id: id ?? this.id,
    title: title ?? this.title,
    subtitle: subtitle ?? this.subtitle,
    url: url ?? this.url,
    imageUrl: imageUrl ?? this.imageUrl,
    isVisible: isVisible ?? this.isVisible,
    metadata: metadata ?? this.metadata,
    isPrimaryPhone: isPrimaryPhone ?? this.isPrimaryPhone,
    isPrimaryEmail: isPrimaryEmail ?? this.isPrimaryEmail,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    jobTitle: jobTitle ?? this.jobTitle,
    companyName: companyName ?? this.companyName,
    textBlockStyle: textBlockStyle ?? this.textBlockStyle,
    isBold: isBold ?? this.isBold,
    isItalic: isItalic ?? this.isItalic,
    isUnderlined: isUnderlined ?? this.isUnderlined,
    textRanges: textRanges ?? this.textRanges,
  );
}

class TextRange {
  final int start;
  final int end;
  final TextBlockStyle? style;
  final bool? isBold;
  final bool? isItalic;
  final bool? isUnderlined;

  TextRange({
    required this.start,
    required this.end,
    this.style,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderlined = false,
  });

  Map<String, dynamic> toMap() => {
    'start': start,
    'end': end,
    'style': style?.name,
    'isBold': isBold,
    'isItalic': isItalic,
    'isUnderlined': isUnderlined,
  };

  factory TextRange.fromMap(Map<String, dynamic> map) {
    return TextRange(
      start: map['start'],
      end: map['end'],
      style: map['style'] != null ? TextBlockStyle.values.firstWhere(
        (e) => e.name == map['style'],
        orElse: () => TextBlockStyle.paragraph
      ) : null,
      isBold: map['isBold'],
      isItalic: map['isItalic'],
      isUnderlined: map['isUnderlined'],
    );
  }
}