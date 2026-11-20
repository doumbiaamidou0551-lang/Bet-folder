String fmtOdds(double value) => value.toStringAsFixed(2).replaceAll('.', ',');

String _pts(int n) => n.abs() == 1 ? 'pt' : 'pts';

String signedPts(int value) {
  if (value > 0) return '+$value ${_pts(value)}';
  if (value < 0) return '−${value.abs()} ${_pts(value)}';
  return '0 pt';
}

String fmtDec(double value, {int digits = 1}) =>
    value.toStringAsFixed(digits).replaceAll('.', ',');

/// Montant en FCFA avec espaces insécables entre les milliers.
String fmtFcfa(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('\u00A0');
    buffer.write(digits[i]);
  }
  return '${value < 0 ? '−' : ''}$buffer\u00A0FCFA';
}

/// Pourcentage avec virgule ; `null` s'affiche « — ».
String fmtPct(double? value, {int digits = 0, bool signed = false}) {
  if (value == null) return '—';
  final text = value.abs().toStringAsFixed(digits).replaceAll('.', ',');
  if (value < 0) return '−$text\u00A0%';
  return '${signed && value > 0 ? '+' : ''}$text\u00A0%';
}
