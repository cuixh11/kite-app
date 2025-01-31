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
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ical/serializer.dart';
import 'package:kite/util/flash.dart';
import 'package:kite/util/logger.dart';
import 'package:kite/util/permission.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../entity/index.dart';
import '../../init.dart';
import 'cache.dart';
import 'component/daily.dart';
import 'component/weekly.dart';
import 'util.dart';

/// 课表模式
const displayModeDaily = 0;
const displayModeWeekly = 1;

class TimetablePage extends StatefulWidget {
  const TimetablePage({Key? key}) : super(key: key);

  @override
  _TimetablePageState createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  /// 最大周数
  /// TODO 还没用上
  // static const int maxWeekCount = 20;

  // 模式：周课表 日课表
  int displayMode = EduInitializer.timetableStorage.lastMode ?? displayModeDaily;
  bool isRefreshing = false;
  final currentKey = GlobalKey();

  final SchoolYear currSchoolYear = const SchoolYear(2021);
  final currSemester = Semester.secondTerm;
  List<Course> timetable = EduInitializer.timetableStorage.getTimetable();

  Future<List<Course>> _fetchTimetable() async {
    final timetable = await EduInitializer.timetable.getTimetable(currSchoolYear, currSemester);

    await EduInitializer.timetableStorage.clear();
    EduInitializer.timetableStorage.addAll(timetable);
    return timetable;
  }

  Future<void> _onRefresh() async {
    if (isRefreshing) {
      return;
    }
    isRefreshing = true;
    try {
      showBasicFlash(context, const Text('加载成功'));

      final newTimetable = await _fetchTimetable();
      TableCache.clear();

      setState(() => timetable = newTimetable);
    } catch (e) {
      showBasicFlash(context, Text('加载失败: ${e.toString().split('\n')[0]}'));
      rethrow;
    } finally {
      isRefreshing = false;
    }
    // 刷新界面
  }

  Future<void> _onExport() async {
    if (timetable.isEmpty) {
      showBasicFlash(context, const Text('你咋没课呢？？'));
      // return;
    }
    final isPermissionGranted = await ensurePermission(Permission.storage);
    if (!isPermissionGranted) {
      showBasicFlash(context, const Text('无写入文件权限'));
      return;
    }

    final ICalendar iCal = ICalendar(
      company: 'Kite Team, Yiban WorkStation of Shanghai Institute of Technology',
      product: 'kite',
      lang: 'ZH',
    );
    for (final course in timetable) {
      addEventForCourse(iCal, course);
    }

    final String iCalContent = iCal.serialize();
    final String path = (await getExternalCacheDirectories())![0].path + '/calendar.ics';
    final File file = File(path);

    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }
    file.writeAsStringSync(iCalContent);
    Log.info('保存日历文件到 $path');
    OpenFile.open(path, type: 'text/calendar');
  }

  PopupMenuButton _buildPopupMenu(BuildContext context) {
    final List<Function()> callback = [
      () => Navigator.of(context).pushNamed('/timetable/import'),
      _onRefresh,
      _onExport,
    ];

    return PopupMenuButton(
      onSelected: (index) => callback[index](),
      itemBuilder: (BuildContext ctx) {
        return const <PopupMenuEntry>[
          PopupMenuItem(value: 0, child: Text('导入')),
          PopupMenuItem(value: 1, child: Text('刷新')),
          PopupMenuItem(value: 2, child: Text('导出日历')),
        ];
      },
    );
  }

  void _onPressJumpToday() {
    if (displayMode == displayModeDaily) {
      (currentKey.currentWidget as DailyTimetable).jumpToday();
    } else {
      (currentKey.currentWidget as WeeklyTimetable).jumpToday();
    }
  }

  Widget _buildModeSwitchButton() {
    return IconButton(
      icon: const Icon(Icons.swap_horiz),
      onPressed: () {
        if (displayMode == displayModeDaily) {
          setState(() => displayMode = displayModeWeekly);
        } else {
          setState(() => displayMode = displayModeDaily);
        }
        EduInitializer.timetableStorage.lastMode = displayMode;
      },
    );
  }

  Widget _buildFloatingButton() {
    final textStyle = Theme.of(context).textTheme.headline2?.copyWith(color: Colors.white);
    return FloatingActionButton(child: Text('今', style: textStyle), onPressed: _onPressJumpToday);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('课程表'), actions: <Widget>[
        _buildModeSwitchButton(),
        _buildPopupMenu(context),
      ]),
      floatingActionButton: _buildFloatingButton(),
      body: displayMode == displayModeDaily
          ? DailyTimetable(timetable, key: currentKey)
          : WeeklyTimetable(timetable, key: currentKey),
    );
  }
}
