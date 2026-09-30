import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final loader = FontLoader('CormorantGaramond');
    loader.addFont(
      Future.value(
        ByteData.sublistView(
          File('assets/fonts/CormorantGaramond-Regular.ttf').readAsBytesSync(),
        ),
      ),
    );
    loader.addFont(
      Future.value(
        ByteData.sublistView(
          File('assets/fonts/CormorantGaramond-Bold.ttf').readAsBytesSync(),
        ),
      ),
    );
    await loader.load();
  });

  test('CormorantGaramond lays out all Vietnamese strings cleanly', () {
    const samples = [
      'AstraCue',
      'Lắng nghe tín hiệu vũ trụ và trực giác của bạn',
      'HƯỚNG ĐI CỦA BẠN',
      'CÓ',
      'KHÔNG',
      'HÀNH ĐỘNG',
      'CHỜ ĐỢI',
      'TIẾN LÊN',
      'LÙI LẠI',
      'Ở LẠI',
      'RỜI ĐI',
      'GIỮ LẠI',
      'BUÔNG BỎ',
      'GẮN BÓ',
      'CHẤM DỨT',
      'TRÁI',
      'PHẢI',
      'aáàảãạăắằẳẵặâấầẩẫậeéèẻẽẹêếềểễệiíìỉĩịoóòỏõọôốồổỗộơớờởỡợuúùủũụưứừửữựyýỳỷỹỵ',
      'AÁÀẢÃẠĂẮẰẲẴẶÂẤẦẨẪẬEÉÈẺẼẸÊẾỀỂỄỆIÍÌỈĨỊOÓÒỎÕỌÔỐỒỔỖỘƠỚỜỞỠỢUÚÙỦŨỤƯỨỪỬỮỰYÝỲỶỸỴ',
    ];

    for (final text in samples) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            fontFamily: 'CormorantGaramond',
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      expect(painter.width, greaterThan(0), reason: 'Width should be > 0 for "$text"');
      expect(painter.height, greaterThan(0), reason: 'Height should be > 0 for "$text"');
      painter.dispose();
    }
  });
}
