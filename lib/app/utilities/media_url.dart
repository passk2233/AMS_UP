import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Helpers for turning the server-relative media paths the backend stores
/// (e.g. notification `photo` / `file`) into absolute, loadable URLs.
///
/// The backend serves uploaded files at the host root (`/uploads/...`) while
/// `API_URL` points at the versioned API base (`.../api/v1`). Resolving a
/// stored path therefore means stripping the `/api/vN` suffix from `API_URL`
/// to recover the host, then appending the relative path.

/// Resolve a stored media [path] into an absolute URL, or `null` when [path]
/// is null/blank. Absolute `http(s)` inputs are returned unchanged so an
/// externally-hosted photo URL passes straight through.
String? resolveMediaUrl(String? path) {
  if (path == null) return null;
  final p = path.trim();
  if (p.isEmpty) return null;
  if (p.startsWith('http://') || p.startsWith('https://')) return p;

  final host = _hostBase(dotenv.env['API_URL'] ?? '');
  if (host.isEmpty) return p; // best effort — nothing to prefix with
  return host + (p.startsWith('/') ? p : '/$p');
}

/// The host root for [apiUrl], i.e. everything before the `/api/...` segment,
/// with any trailing slash removed. Returns '' for empty input.
String _hostBase(String apiUrl) {
  var base = apiUrl.trim();
  if (base.isEmpty) return '';
  if (base.endsWith('/')) base = base.substring(0, base.length - 1);
  final apiIdx = base.indexOf('/api/');
  if (apiIdx > 0) base = base.substring(0, apiIdx);
  return base;
}

const Set<String> _imageExtensions = {
  '.jpg',
  '.jpeg',
  '.png',
  '.gif',
  '.webp',
  '.bmp',
  '.heic',
};

/// Whether [pathOrUrl] looks like an image, judged by file extension. Used to
/// decide between an inline preview and a generic file row. Query strings are
/// ignored so signed/cache-busted URLs still match.
bool isImagePath(String? pathOrUrl) {
  if (pathOrUrl == null) return false;
  final clean = pathOrUrl.toLowerCase().split('?').first.split('#').first;
  return _imageExtensions.any(clean.endsWith);
}

/// The trailing file name of [pathOrUrl] (after the last `/`), or '' when
/// none. Handy for showing a human-readable attachment label.
String fileNameFromPath(String? pathOrUrl) {
  if (pathOrUrl == null) return '';
  final clean = pathOrUrl.split('?').first.split('#').first;
  final slash = clean.lastIndexOf('/');
  return slash >= 0 ? clean.substring(slash + 1) : clean;
}
