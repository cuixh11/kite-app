/*
 *    上应小风筝(SIT-kite)  便利校园，一步到位
 *    Copyright (C) 2022 上海应用技术大学 上应小风筝团队
 *
 *    This program is free software: you can redistribute it and/or modify
 *    it under the terms of the GNU General Public License as published by
 *    the Free Software Foundation, either version 3 of the License, or
 *    (at your option) any later version.
 *
 *    This program is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *    GNU General Public License for more details.
 *
 *    You should have received a copy of the GNU General Public License
 *    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
import 'package:flutter/material.dart';
import 'package:kite/entity/bulletin.dart';
import 'package:kite/global/session_pool.dart';
import 'package:kite/service/bulletin.dart';

import './detail.dart';

class BulletinPage extends StatelessWidget {
  const BulletinPage({Key? key}) : super(key: key);

  Widget _buildBulletinList() {
    final service = BulletinService(SessionPool.ssoSession);
    final future = service.queryBulletinListInAllCategory(1);

    return FutureBuilder<List<BulletinRecord>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData) {
              final records = snapshot.data!;
              BulletinService.sortBulletinRecord(records);

              final items = records
                  .map((e) => ListTile(
                        title: Text(e.title),
                        subtitle: Text(e.department + ' | ' + e.dateTime.toString()),
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => DetailPage(e))),
                      ))
                  .toList();
              return SingleChildScrollView(
                  child: Column(
                children: items,
              ));
            } else if (snapshot.hasError) {
              return Center(child: Text('错误类型: ' + snapshot.error.runtimeType.toString()));
            }
          }
          return const Center(child: CircularProgressIndicator());
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OA 公告'),
      ),
      body: _buildBulletinList(),
    );
  }
}