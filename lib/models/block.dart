// lib/models/block.dart

enum BlockType {
  website,
  image,
  youtube
}

enum BlockLayout {
  classic,
  carousel
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
  final String? aspectRatio;  // Only used when layout is carousel

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

  BlockContent({
    required this.id,
    required this.title,
    this.subtitle,
    required this.url,
    this.imageUrl,
    this.isVisible = true,
    this.metadata,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'url': url,
    'imageUrl': imageUrl,
    'isVisible': isVisible,
    'metadata': metadata,
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
  }) => BlockContent(
    id: id ?? this.id,
    title: title ?? this.title,
    subtitle: subtitle ?? this.subtitle,
    url: url ?? this.url,
    imageUrl: imageUrl ?? this.imageUrl,
    isVisible: isVisible ?? this.isVisible,
    metadata: metadata ?? this.metadata,
  );
}