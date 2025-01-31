/*
 * 上应小风筝  便利校园，一步到位
 * Copyright (C) 2022 上海应用技术大学 上应小风筝团队
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
import 'package:flutter/material.dart';
import 'package:kite/util/flash.dart';

import '../dao/expense.dart';
import '../entity/expense.dart';
import '../init.dart';
import '../page/icon.dart';
import 'bill.dart';
import 'statistics.dart';

class ExpensePage extends StatefulWidget {
  const ExpensePage({Key? key}) : super(key: key);

  @override
  _ExpensePageState createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage> {
  /// 底部导航键的标志位
  int currentIndex = 0;
  bool _isRefreshing = false;
  ExpenseType _filter = ExpenseType.all;

  /// 筛选按钮
  _buildPopupMenuItems() {
    final itemMapping = expenseTypeMapping.map((type, display) {
      final item = PopupMenuItem(
        value: type,
        child: Row(children: [buildIcon(type, context), Text(display)]),
      );
      return MapEntry(type, item);
    });

    final List<PopupMenuItem<ExpenseType>> items = itemMapping.values.toList();
    return PopupMenuButton(
      tooltip: '筛选',
      onSelected: (ExpenseType v) => setState(() => _filter = v),
      itemBuilder: (_) => items,
    );
  }

  /// 拉取数据并保存
  Future<OaExpensePage> _fetchAndSave(ExpenseRemoteDao service, int page, {DateTime? start, DateTime? end}) async {
    start = start ?? DateTime(2010);
    end = end ?? DateTime.now();

    final OaExpensePage billPage = await service.getExpensePage(page, start: start, end: end);
    ExpenseInitializer.expenseRecord.addAll(billPage.records);

    return billPage;
  }

  /// 并发拉取数据
  Future<List<ExpenseRecord>> _fetchBillConcurrently(ExpenseRemoteDao service, int startPage, int count) async {
    final List<Future> futures = [];
    for (int i = 2; i <= count; i++) {
      futures.add(_fetchAndSave(service, i));
    }
    final List<ExpenseRecord> result = (await Future.wait(futures)).fold(<ExpenseRecord>[], (l, e) => l + e);
    return result;
  }

  void _onUpdateRecords(BuildContext context) async {
    if (_isRefreshing) {
      showBasicFlash(context, const Text('已经在刷新啦'));
      return;
    } else {
      _isRefreshing = true;
    }
    showBasicFlash(context, const Text('正在更新消费数据, 速度受限于学校服务器, 请稍等'));

    final DateTime? startDate = ExpenseInitializer.expenseRecord.getLastOne()?.ts;
    final service = ExpenseInitializer.expenseRemote;

    final OaExpensePage firstPage = await _fetchAndSave(service, 1, start: startDate);

    showBasicFlash(context, Text('已加载 1 页, 共 ${firstPage.total} 页'));
    setState(() {});

    _fetchBillConcurrently(service, 2, firstPage.total - 1);

    showBasicFlash(context, const Text('加载完成'));
    setState(() => _isRefreshing = false);
  }

  Widget _buildRefreshButton(BuildContext context) {
    return IconButton(
      tooltip: '刷新',
      icon: const Icon(Icons.refresh),
      onPressed: () => Future.delayed(Duration.zero, () => _onUpdateRecords(context)).catchError((e) {
        _isRefreshing = false;
        showBasicFlash(context, Text('错误信息: ${e.toString().split('\n')[0]}'), duration: const Duration(seconds: 3));
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("消费记录"),
        actions: [
          _buildRefreshButton(context),
          currentIndex == 0 ? _buildPopupMenuItems() : Container(),
        ],
      ),
      body: currentIndex == 0 ? BillPage(filter: _filter) : const StatisticsPage(),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            label: '账单',
            icon: Icon(Icons.assignment_rounded),
          ),
          BottomNavigationBarItem(
            label: '统计',
            icon: Icon(Icons.data_saver_off),
          )
        ],
        currentIndex: currentIndex,
        onTap: (int index) {
          setState(() => {currentIndex = index, _isRefreshing = false});
        },
      ),
    );
  }
}
