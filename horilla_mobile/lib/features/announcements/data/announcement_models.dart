enum BlockType { heading, paragraph, bullet }

/// One piece of an announcement's body. The server flattens the HTML into
/// these; older servers send only headings and paragraphs.
class ContentBlock {
  const ContentBlock(this.type, this.text);

  final BlockType type;
  final String text;

  static ContentBlock? fromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final text = value['text'];
    if (text is! String || text.trim().isEmpty) return null;
    final type = switch (value['type']) {
      'heading' => BlockType.heading,
      'bullet' => BlockType.bullet,
      // Anything unknown still reads as prose rather than vanishing.
      _ => BlockType.paragraph,
    };
    return ContentBlock(type, text.trim());
  }
}

class AnnouncementAttachment {
  const AnnouncementAttachment({
    required this.name,
    required this.url,
    required this.isImage,
  });

  final String name;

  /// As the server sends it: usually a path under /media/, which is
  /// login-protected, so fetch it with the session rather than a bare GET.
  final String url;
  final bool isImage;

  static AnnouncementAttachment? fromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final url = value['url'];
    if (url is! String || url.isEmpty) return null;
    final name = value['name'];
    return AnnouncementAttachment(
      name: name is String && name.isNotEmpty ? name : url.split('/').last,
      url: url,
      isImage: value['is_image'] == true,
    );
  }

  /// [url] made absolute against the signed-in host.
  String resolve(String host) => url.startsWith('http') ? url : '$host$url';
}

class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    this.content = const [],
    this.createdAt,
    this.expireDate,
    this.hasViewed = true,
    this.attachments = const [],
    this.author,
  });

  final int id;
  final String title;
  final List<ContentBlock> content;
  final DateTime? createdAt;
  final DateTime? expireDate;
  final bool hasViewed;

  /// Only the detail endpoint sends these; empty from the list.
  final List<AnnouncementAttachment> attachments;
  final String? author;

  /// The first line of body text, for the feed card.
  String? get preview {
    for (final block in content) {
      if (block.type != BlockType.heading) return block.text;
    }
    return content.isEmpty ? null : content.first.text;
  }

  static Announcement? fromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final id = value['id'];
    final title = value['title'];
    if (id is! int || title is! String || title.isEmpty) return null;
    List<T> list<T>(Object? raw, T? Function(Object?) parse) =>
        raw is List ? raw.map(parse).whereType<T>().toList() : const [];
    DateTime? date(Object? raw) =>
        raw is String ? DateTime.tryParse(raw) : null;
    final author = value['author'];
    return Announcement(
      id: id,
      title: title,
      content: list(value['content'], ContentBlock.fromJson),
      createdAt: date(value['created_at']),
      expireDate: date(value['expire_date']),
      // Missing means an older server that doesn't track it: don't paint
      // everything unread.
      hasViewed: value['has_viewed'] != false,
      attachments: list(value['attachments'], AnnouncementAttachment.fromJson),
      author: author is String && author.isNotEmpty ? author : null,
    );
  }
}
