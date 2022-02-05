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
import 'package:flutter_svg/svg.dart';
import 'package:kite/entity/edu/index.dart';
import 'package:kite/global/session_pool.dart';
import 'package:kite/global/storage_pool.dart';
import 'package:kite/page/score/banner.dart';
import 'package:kite/page/score/item.dart';
import 'package:kite/service/edu/index.dart';
import 'package:kite/util/logger.dart';

List<int> _generateYearList(int entranceYear) {
  final date = DateTime.now();
  final endYear = date.month >= 9 ? date.year : date.year - 1;

  List<int> yearItems = [];
  for (int year = entranceYear; year <= endYear; ++year) {
    yearItems.add(year);
  }
  return yearItems;
}

Semester indexToSemester(int index) {
  return [Semester.all, Semester.firstTerm, Semester.secondTerm][index];
}

class ScorePage extends StatefulWidget {
  const ScorePage({Key? key}) : super(key: key);

  @override
  _ScorePageState createState() => _ScorePageState();
}

class _ScorePageState extends State<ScorePage> {
  final date = DateTime.now();

  /// 四位年份
  late int selectedYear;

  /// 要查询的学期
  Semester selectedSemester = Semester.all;

  @override
  void initState() {
    selectedYear = date.month >= 9 ? date.year : date.year - 1;
    super.initState();
  }

  final Widget _notFoundPicture = SvgPicture.asset(
    'assets/score/not-found.svg',
    width: 260,
    height: 260,
  );

  Widget _buildHeader(List<Score> scoreList) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          margin: const EdgeInsets.only(left: 15),
          child: _buildSelectorRow(),
        ),
        GpaBanner(selectedSemester, scoreList),
      ],
    );
  }

  Widget _buildSelectorRow() {
    String buildYearString(int startYear) {
      return '$startYear - ${startYear + 1}';
    }

    /// 构建选择下拉框.
    /// alternatives 是一个字典, key 为实际值, value 为显示值.
    Widget buildSelector(Map<int, String> alternatives, int initialValue, void Function(int?) callback) {
      final items = alternatives.keys
          .map(
            (k) => DropdownMenuItem<int>(
              value: k,
              child: Text(alternatives[k]!),
            ),
          )
          .toList();

      return DropdownButton<int>(
        value: initialValue,
        icon: const Icon(Icons.keyboard_arrow_down_outlined),
        style: const TextStyle(
          color: Color(0xFF002766),
        ),
        underline: Container(
          height: 2,
          color: Colors.blue,
        ),
        onChanged: callback,
        items: items,
      );
    }

    Widget buildYearSelector() {
      // 得到入学年份
      final grade = StoragePool.authSetting.currentUsername!.substring(0, 2);
      // 生成经历过的学期并逆序（方便用户选择）
      final List<int> yearList = _generateYearList(int.parse(grade) + 2000).reversed.toList();
      final mapping = yearList.map((e) => MapEntry(e, buildYearString(e)));

      // 保证显示上初始选择年份、实际加载的年份、selectedYear 变量一致.
      return buildSelector(Map.fromEntries(mapping), selectedYear, (int? selected) {
        if (selected != null && selected != selectedYear) {
          setState(() {
            selectedYear = selected;
          });
        }
      });
    }

    Widget buildSemesterSelector() {
      const semesterDescription = {
        Semester.all: '全学年',
        Semester.firstTerm: '第一学期',
        Semester.secondTerm: '第二学期',
      };
      final semesters = Semester.values.map((e) => MapEntry(e.index, semesterDescription[e]!));
      // 保证显示上初始选择学期、实际加载的学期、selectedSemester 变量一致.
      return buildSelector(Map.fromEntries(semesters), selectedSemester.index, (int? selected) {
        if (selected != null && selected != (selectedSemester.index)) {
          setState(() {
            selectedSemester = indexToSemester(selected);
          });
        }
      });
    }

    return Row(children: [
      Container(
        child: buildYearSelector(),
      ),
      Container(
        margin: const EdgeInsets.only(left: 15),
        child: buildSemesterSelector(),
      ),
    ]);
  }

  List<Widget> _buildListView(List<Score> scoreList) {
    return scoreList.map((e) => ScoreItem(e)).toList();
  }

  Widget _buildNoResult() {
    return Column(children: [
      Container(
        child: _notFoundPicture,
      ),
      const Text('暂时还没有成绩', style: TextStyle(color: Colors.grey)),
      Container(
        margin: const EdgeInsets.only(left: 40, right: 40),
        child: const Text('过会儿再来吧！', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
      )
    ]);
  }

  Widget _buildBody() {
    final future = ScoreService(SessionPool.eduSession).getScoreList(SchoolYear(selectedYear), selectedSemester);

    return FutureBuilder<List<Score>>(
      future: future,
      builder: (context, snapshot) {
        Log.info('查询成绩:${snapshot.connectionState}');
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          final scoreList = snapshot.data!;

          Log.info(scoreList);
          return Column(children: [
            Expanded(child: _buildHeader(scoreList), flex: 1),
            Expanded(
                child: scoreList.isNotEmpty
                    ? ListView(
                        children: _buildListView(scoreList),
                      )
                    : _buildNoResult(),
                flex: 10),
          ]);
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('成绩查询'),
      ),
      body: _buildBody(),
    );
  }
}