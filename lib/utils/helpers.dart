class Helpers {
  /// Convert ISO timestamp → "২ ঘণ্টা আগে" style Bengali relative time
  static String timeAgo(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inSeconds < 60)  return 'এইমাত্র';
      if (diff.inMinutes < 60)  return '${diff.inMinutes} মিনিট আগে';
      if (diff.inHours < 24)    return '${diff.inHours} ঘণ্টা আগে';
      if (diff.inDays < 7)      return '${diff.inDays} দিন আগে';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  /// Extract author name from post map
  static String authorName(Map post) {
    final user = post['user'] as Map?;
    return (user?['name'] as String?)?.trim().isNotEmpty == true
        ? user!['name']
        : (post['author'] as String?) ?? 'Anonymous';
  }
}