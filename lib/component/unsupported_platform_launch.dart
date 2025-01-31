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
import 'package:kite/util/url_launcher.dart';

const tipPC = '电脑端暂不支持直接查看';

class UnsupportedPlatformUrlLauncher extends StatelessWidget {
  final String url;
  final String tip;

  const UnsupportedPlatformUrlLauncher(
    this.url, {
    Key? key,
    this.tip = tipPC,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(tip),
          TextButton(
            child: const Text('点击在默认浏览器中打开'),
            onPressed: () {
              launchInBrowser(url);
            },
          )
        ],
      ),
    );
  }
}
