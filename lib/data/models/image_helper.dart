/// Resolves a BeMusic API image path to a full URL.
///
/// The API returns most image fields as relative paths (e.g. `storage/track_image_media/xxx.png`).
/// User avatars may already be absolute URLs (e.g. `https://elsfm.com/storage/avatars/xxx.png`).
/// This helper normalises both cases to a full https://www.elsfm.com/… URL.
String resolveImageUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  return 'https://www.elsfm.com/$path';
}
