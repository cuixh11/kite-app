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
import 'package:quick_actions/quick_actions.dart';

class QuickButton {
  static BuildContext? _context;
  static const QuickActions _quickActions = QuickActions();

  static void quickActionHandler(String type) {
    if (type == 'report') {
      Navigator.of(_context!).pushNamed('/report');
    } else if (type == 'timetable') {
      Navigator.of(_context!).pushNamed('/timetable');
    }
  }

  static void init(BuildContext context) {
    _quickActions.initialize(quickActionHandler);

    _quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(type: 'report', localizedTitle: '体温上报', icon: null),
      const ShortcutItem(type: 'timetable', localizedTitle: '课表', icon: null)
    ]);
  }
}
