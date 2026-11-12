import 'dart:convert';
import 'dart:io';

/// Generates static, hostable policies from the same localized copy as the app.
/// Publishing, controller identity and contact ownership stay with the owner.
void main(List<String> args) {
  final options = <String, String>{};
  for (final arg in args) {
    final split = arg.indexOf('=');
    if (split > 2) options[arg.substring(2, split)] = arg.substring(split + 1);
  }
  final publisher = options['publisher']?.trim() ?? '';
  final email = options['email']?.trim() ?? '';
  if (publisher.isEmpty ||
      !RegExp(r'^[^\s<>@]+@[^\s<>@]+\.[^\s<>@]+$').hasMatch(email)) {
    stderr.writeln(
      'Usage: dart tool/export_legal_pages.dart --publisher="Your legal name" --email=your-real-support-email --output=build/legal',
    );
    exitCode = 1;
    return;
  }
  final destination = Directory(options['output'] ?? 'build/legal')
    ..createSync(recursive: true);
  const locales = ['en', 'vi', 'ja', 'es', 'th', 'hi', 'zh', 'ko'];
  const escape = HtmlEscape();
  String html(String value) => escape.convert(value);
  final updated = DateTime.now().toUtc().toIso8601String().substring(0, 10);
  for (final locale in locales) {
    final copy = (jsonDecode(
      File('lib/l10n/app_$locale.arb').readAsStringSync(),
    ) as Map).cast<String, Object?>();
    final language = locale == 'zh' ? 'zh-Hans' : locale;
    for (final document in ['privacy', 'terms', 'support']) {
      final titleKey = switch (document) {
        'privacy' => 'legalPrivacy',
        'terms' => 'legalTerms',
        _ => 'legalSupport',
      };
      final body = switch (document) {
        'privacy' => copy['legalPrivacyBody'] as String,
        'terms' => copy['legalTermsBody'] as String,
        _ => '',
      };
      final contact = '<a href="mailto:${html(email)}">${html(email)}</a>';
      final content =
          '''<!doctype html>
<html lang="$language"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>AstraCue — ${html(copy[titleKey] as String)}</title>
<style>body{font:18px/1.7 system-ui,sans-serif;max-width:760px;padding:24px;margin:auto;color:#17243b;background:#fafbff}nav{display:flex;gap:16px;flex-wrap:wrap}a{color:#145caf}article{white-space:pre-line}footer{border-top:1px solid #ccc;margin-top:32px;padding-top:16px}</style>
<nav>${locales.map((l) => '<a href="$document-$l.html">$l</a>').join(' ')}</nav>
<h1>AstraCue — ${html(copy[titleKey] as String)}</h1>
<article>${html(body)}</article>
<footer><p>${html(publisher)} · $contact</p>
<p><time datetime="$updated">$updated</time></p>
<nav><a href="privacy-$locale.html">${html(copy['legalPrivacy'] as String)}</a><a href="terms-$locale.html">${html(copy['legalTerms'] as String)}</a><a href="support-$locale.html">${html(copy['legalSupport'] as String)}</a></nav></footer></html>
''';
      File('${destination.path}/$document-$locale.html')
          .writeAsStringSync(content);
      if (locale == 'en') {
        File('${destination.path}/$document.html').writeAsStringSync(content);
      }
    }
  }
  stdout.writeln(
    'Generated 27 static pages in ${destination.path}. Review, host over HTTPS and configure their URLs before release.',
  );
}
