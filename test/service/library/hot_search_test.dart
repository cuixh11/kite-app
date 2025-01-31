import 'package:flutter_test/flutter_test.dart';
import 'package:kite/feature/library/init.dart';
import 'package:kite/feature/library/service/index.dart';
import 'package:logger/logger.dart';

void main() {
  var logger = Logger();
  test('should', () async {
    var session = LibraryInitializer.session;
    var s = await HotSearchService(session).getHotSearch();
    logger.i(s.toString());
  });
}
