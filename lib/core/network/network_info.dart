import 'dart:io';

/// Connectivity probe. Uses an HTTP HEAD request, never a raw socket check —
/// `InternetConnectionChecker`-style socket probes are firewalled on Android
/// (Shoppy lesson, `Docs/legacy/SHOPPY_PROJECT_KNOWLEDGE.md` §11).
abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  static const _timeout = Duration(seconds: 5);

  @override
  Future<bool> get isConnected async {
    final results = await Future.wait([
      _probe('https://www.google.com'),
      _probe('https://1.1.1.1'),
    ]);
    return results.any((reachable) => reachable);
  }

  Future<bool> _probe(String url) async {
    final client = HttpClient()..connectionTimeout = _timeout;
    try {
      final request = await client.headUrl(Uri.parse(url)).timeout(_timeout);
      final response = await request.close().timeout(_timeout);
      await response.drain<void>();
      return true;
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }
}
