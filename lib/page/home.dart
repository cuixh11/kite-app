import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kite/global/bus.dart';
import 'package:kite/global/session_pool.dart';
import 'package:kite/global/storage_pool.dart';
import 'package:kite/service/sso.dart';
import 'package:kite/service/weather.dart';
import 'package:kite/util/flash.dart';
import 'package:kite/util/logger.dart';
import 'package:kite/util/network.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:universal_platform/universal_platform.dart';

import '../global/quick_button.dart';
import 'home/background.dart';
import 'home/drawer.dart';
import 'home/greeting.dart';
import 'home/group.dart';
import 'home/item.dart';

class HomePage extends StatelessWidget {
  HomePage({Key? key}) : super(key: key);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final RefreshController _refreshController = RefreshController(initialRefresh: false);

  void _updateWeather() {
    Future.delayed(const Duration(milliseconds: 800), () async {
      try {
        final weather = await WeatherService().getCurrentWeather(StoragePool.homeSetting.campus);
        eventBus.emit('onWeatherUpdate', weather);
      } catch (_) {}
    });
  }

  Future<String?> _doLogin(BuildContext context) async {
    final String username = StoragePool.authSetting.currentUsername!;
    final String password = StoragePool.authPool.get(username)!.password;

    await SessionPool.ssoSession.login(username, password);
  }

  /// 显示检查网络的flash
  void _showCheckNetwork(BuildContext context, {Widget? title}) {
    showBasicFlash(
      context,
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Icon(Icons.dangerous),
        title ?? const Text('请检查当前是否处于校园网环境'),
        TextButton(
          child: const Text('检查网络'),
          onPressed: () => Navigator.of(context).pushNamed('/connectivity'),
        )
      ]),
      duration: const Duration(seconds: 5),
    );
  }

  Future<void> _onHomeRefresh(BuildContext context) async {
    // 如果未登录 (老用户直接进入 Home 页不会处于登录状态, 但新用户经过 login 页时已登录)
    if (!SessionPool.ssoSession.isOnline) {
      try {
        await _doLogin(context);
        showBasicFlash(context, const Text('登录成功'));
      } on Exception catch (e) {
        // 如果是认证相关问题, 弹出相应的错误信息.
        if (e is UnknownAuthException || e is CredentialsInvalidException) {
          showBasicFlash(context, Text('登录异常: $e'));
        } else {
          // 如果是网络问题, 提示检查网络.
          _showCheckNetwork(context, title: Text('$e: 网络异常'));
        }
      }
    }

    if (SessionPool.ssoSession.isOnline) {
      eventBus.emit('onHomeRefresh');
    }
    _refreshController.refreshCompleted(resetFooterState: true);

    // 下拉也要更新一下天气 :D
    _updateWeather();
  }

  Widget _buildTitleLine(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: () {
          _scaffoldKey.currentState?.openDrawer();
        },
        child: Center(child: SvgPicture.asset('assets/home/kite.svg', width: 80, height: 80)),
      ),
    );
  }

  List<Widget> buildFunctionWidgets() {
    return [
      const GreetingWidget(),
      const SizedBox(height: 20.0),
      const HomeItemGroup([TimetableItem(), ReportItem()]),
      const SizedBox(height: 20.0),
      const HomeItemGroup([ElectricityItem(), ExpenseItem(), ScoreItem(), LibraryItem(), OfficeItem()]),
      const SizedBox(height: 20.0),
      const HomeItemGroup([
        HomeItem(route: '/game', icon: 'assets/home/icon_game.svg', title: '小游戏', subtitle: '放松一下'),
        HomeItem(route: '/wiki', icon: 'assets/home/icon_wiki.svg', title: 'Wiki', subtitle: '上应大生存指南'),
        HomeItem(route: '/market', icon: 'assets/home/icon_market.svg', title: '二手书广场', subtitle: '买与卖都是收获'),
      ]),
      const SizedBox(height: 40),
    ];
  }

  Widget _buildBody(BuildContext context) {
    final windowSize = MediaQuery.of(context).size;
    final items = buildFunctionWidgets();

    return Stack(
      children: [
        const HomeBackground(),
        SmartRefresher(
          enablePullDown: true,
          enablePullUp: false,
          controller: _refreshController,
          child: CustomScrollView(slivers: [
            SliverAppBar(
              // AppBar
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(title: _buildTitleLine(context)),
              expandedHeight: windowSize.height * 0.6,
              backgroundColor: Colors.transparent,
              centerTitle: false,
              elevation: 0,
              pinned: false,
            ),
            SliverList(
              // Functions
              delegate: SliverChildBuilderDelegate(
                (_, index) => Padding(padding: const EdgeInsets.only(left: 10, right: 10), child: items[index]),
                childCount: items.length,
              ),
            ),
          ]),
          onRefresh: () => _onHomeRefresh(context),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration.zero, () {
      showBasicFlash(
        context,
        const Text('正在检查网络连接'),
        duration: const Duration(seconds: 3),
      );
    });
    // 检查校园网情况
    checkConnectivity().then((ok) {
      if (!ok) {
        _showCheckNetwork(
          context,
          title: const Text('无法连接校园网，部分功能不可用'),
        );
      } else {
        showBasicFlash(
          context,
          const Text('当前已连接校园网环境'),
          duration: const Duration(seconds: 3),
        );
      }
    });

    if (UniversalPlatform.isAndroid || UniversalPlatform.isIOS) {
      QuickButton.init(context);
    }
    _updateWeather();

    return Scaffold(
      key: _scaffoldKey,
      body: _buildBody(context),
      drawer: const KiteDrawer(),
      floatingActionButton: UniversalPlatform.isDesktopOrWeb
          ? FloatingActionButton(
              child: const Icon(Icons.refresh),
              onPressed: () async {
                // 刷新页面
                Log.info('浮动按钮被点击');
                // 触发下拉刷新
                final pos = _refreshController.position!;
                await pos.animateTo(-100, duration: const Duration(milliseconds: 800), curve: Curves.linear);

                // pos.jumpTo(-20);
              },
            )
          : null,
    );
  }
}
