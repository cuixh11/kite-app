import 'package:kite/feature/bulletin/init.dart';

import 'mock_util.dart';

void main() async {
  await init();
  await login();

  final dao = BulletinInitializer.bulletin;
  test('test bulletin', () async {
    final list = dao.getAllCatalogues();
    Log.info(list);
    final bulletin = await dao.getBulletinDetail('pe2362', '7d227947-6dfc-11ec-9e2f-abfe89c3f6e3');
    Log.info(bulletin);
  });

  test('test get list', () async {
    final list = dao.getAllCatalogues();
    final firstPage = await dao.queryBulletinList(1, list[0].id);
    Log.info(firstPage);
  });
}
