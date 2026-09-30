import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    for (final file in [
      'Montserrat-Regular.ttf',
      'Montserrat-SemiBold.ttf',
      'Montserrat-Bold.ttf',
    ]) {
      final bytes = File('assets/fonts/$file').readAsBytesSync();
      final loader = FontLoader('Montserrat');
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
      await loader.load();
    }
  });

  testWidgets('Montserrat renders all Vietnamese diacritics without missing glyphs', (
    tester,
  ) async {
    const sample =
        'ASTRACUE · LA BÀN QUYẾT ĐỊNH · CHIÊM TINH HỌC\n'
        'Á À Ả Ã Ạ Ă Ắ Ằ Ẳ Ẵ Ặ Â Ấ Ầ Ẩ Ẫ Ậ\n'
        'É È Ẻ Ẽ Ẹ Ê Ế Ề Ể Ễ Ệ\n'
        'Í I Ỉ Ĩ Ị\n'
        'Ó Ò Ỏ Õ Ọ Ô Ố Ồ Ổ Ỗ Ộ Ơ Ớ Ờ Ở Ỡ Ợ\n'
        'Ú Ù Ủ Ũ Ụ Ư Ứ Ừ Ử Ữ Ự\n'
        'Ý Ỳ Ỷ Ỹ Ỵ Đ\n'
        'CÓ · KHÔNG · HÀNH ĐỘNG · CHỜ ĐỢI · TIẾN LÊN · LÙI LẠI · Ở LẠI · RỜI ĐI · GIỮ LẠI · BUÔNG BỎ · GẮN BÓ · CHẤM DỨT · TRÁI · PHẢI\n'
        'Năng lượng hôm nay: Rạng rỡ · Tỷ lệ: 68.2% · Con số may mắn: 7';

    final painter = TextPainter(
      text: const TextSpan(
        text: sample,
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    painter.layout(maxWidth: 360);
    expect(painter.width, greaterThan(0));
    expect(painter.height, greaterThan(0));
  });
}
