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
import 'package:dynamic_color_theme/dynamic_color_theme.dart';
import 'package:flash/flash.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kite/global/global.dart';
import 'package:kite/global/init.dart';
import 'package:kite/setting/init.dart';
import 'package:kite/setting/storage/index.dart';
import 'package:kite/util/flash.dart';
import 'package:kite/util/validation.dart';
import 'package:path_provider/path_provider.dart';

import 'home.dart';
import 'storage.dart';

class SettingPage extends StatelessWidget {
  final TextEditingController _passwordController = TextEditingController();

  SettingPage({Key? key}) : super(key: key);

  Widget _negativeActionBuilder(context, controller, _) {
    return TextButton(
      onPressed: () {
        controller.dismiss();
      },
      child: const Text('取消'),
    );
  }

  void _onChangeBgImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    final savePath = (await getApplicationDocumentsDirectory()).path + '/background';

    await image?.saveTo(savePath);
    SettingInitializer.home.background = savePath;
    Global.eventBus.emit(EventNameConstants.onBackgroundChange);
  }

  void _testPassword(BuildContext context) async {
    final user = SettingInitializer.auth.currentUsername;
    final password = SettingInitializer.auth.ssoPassword;
    try {
      await Global.ssoSession.login(user!, password!);
      showBasicFlash(context, const Text('用户名和密码正确'));
    } catch (e) {
      showBasicFlash(context, Text('登录异常: ${e.toString().split('\n')[0]}'), duration: const Duration(seconds: 3));
    }
  }

  void _onLogout(BuildContext context) {
    context.showFlashDialog(
        constraints: const BoxConstraints(maxWidth: 300),
        title: const Text('退出登录'),
        content: const Text('您将会退出当前账号，是否继续？'),
        negativeActionBuilder: _negativeActionBuilder,
        positiveActionBuilder: (context, controller, _) {
          return TextButton(
              onPressed: () async {
                // dismiss 函数会异步地执行动画, 但动画在应用重启时会被打断从而产生报错. 因此此处不需要 dismiss.
                // controller.dismiss();

                SettingInitializer.auth
                  ..currentUsername = null
                  ..ssoPassword = null;

                await Initializer.init();
                // 重启应用
                Phoenix.rebirth(context);
              },
              child: const Text('继续'));
        });
  }

  void _onClearStorage(BuildContext context) {
    context.showFlashDialog(
        constraints: const BoxConstraints(maxWidth: 300),
        title: const Text('清除数据'),
        content: const Text('此操作将清除您本地的登录信息（不包括网页缓存），并重启本应用。如果你想清除所有数据，请在手机设置的应用管理界面中找到 "上应小风筝" 并重置。'),
        negativeActionBuilder: _negativeActionBuilder,
        positiveActionBuilder: (context, controller, _) {
          return TextButton(
              onPressed: () async {
                await Initializer.clear(); // 清除存储
                Phoenix.rebirth(context); // 重启应用
              },
              child: const Text('继续'));
        });
  }

  @override
  Widget build(BuildContext context) {
    _passwordController.text = SettingInitializer.auth.ssoPassword ?? '';
    return SettingsScreen(title: '设置', children: [
      SettingsGroup(
        title: '个性化',
        children: <Widget>[
          ColorPickerSettingsTile(
            settingKey: ThemeKeys.themeColor,
            defaultValue: SettingInitializer.theme.color,
            title: '主题色',
            onChange: (newColor) => DynamicColorTheme.of(context).setColor(
              color: newColor,
              shouldSave: true, // saves it to shared preferences
            ),
          ),
          SwitchSettingsTile(
            settingKey: ThemeKeys.isDarkMode,
            defaultValue: SettingInitializer.theme.isDarkMode,
            title: '夜间模式',
            subtitle: '开启夜间模式以保护视力，部分颜色显示可能异常',
            leading: const Icon(Icons.dark_mode),
            onChange: (value) => DynamicColorTheme.of(context).setIsDark(isDark: value, shouldSave: false),
          ),
        ],
      ),
      SettingsGroup(
        title: '首页',
        children: <Widget>[
          RadioSettingsTile<int>(
            title: '首页背景模式',
            settingKey: HomeKeyKeys.backgroundMode,
            values: const <int, String>{
              1: '实时天气',
              2: '静态图片',
            },
            selected: SettingInitializer.home.backgroundMode,
            onChange: (value) {
              SettingInitializer.home.backgroundMode = value;
              Global.eventBus.emit(EventNameConstants.onBackgroundChange);
            },
          ),
          DropDownSettingsTile<int>(
            title: '校区',
            subtitle: '显示对应校区的天气',
            settingKey: HomeKeyKeys.campus,
            values: const <int, String>{
              1: '奉贤',
              2: '徐汇',
            },
            selected: SettingInitializer.home.campus,
            onChange: (value) {
              SettingInitializer.home.campus = value;
              Global.eventBus.emit(EventNameConstants.onCampusChange);
            },
          ),
          SimpleSettingsTile(title: '背景图片', subtitle: '自定义首页背景图片', onTap: _onChangeBgImage),
          SimpleSettingsTile(
            title: '功能顺序',
            subtitle: '自定义首页功能的分组与顺序',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const HomeSettingPage())),
          ),
        ],
      ),
      SettingsGroup(title: '网络', children: <Widget>[
        SwitchSettingsTile(
          settingKey: '/network/useProxy',
          defaultValue: SettingInitializer.network.useProxy,
          title: '使用 HTTP 代理',
          subtitle: '通过 HTTP 代理连接校园网',
          leading: const Icon(Icons.vpn_key),
          onChange: (value) async {
            if (value) {
              SettingInitializer.network.useProxy = value;
              await Initializer.init();
            }
          },
          childrenIfEnabled: [
            TextInputSettingsTile(
              title: '代理地址',
              settingKey: '/network/proxy',
              initialValue: SettingInitializer.network.proxy,
              validator: proxyValidator,
              onChange: (value) {
                SettingInitializer.network.proxy = value;
                if (SettingInitializer.network.useProxy) {
                  // TODO
                  // SessionPool.init();
                }
              },
            ),
            SimpleSettingsTile(
                title: '测试连接',
                subtitle: '检查校园网或网络代理的连接',
                onTap: () {
                  Navigator.pushNamed(context, '/connectivity');
                }),
          ],
        ),
      ]),
      SettingsGroup(
        title: '账户',
        children: <Widget>[
          TextInputSettingsTile(
            title: '学号',
            settingKey: AuthKeys.currentUsername,
            initialValue: SettingInitializer.auth.currentUsername ?? '',
            validator: studentIdValidator,
          ),
          ModalSettingsTile(
            title: '密码',
            subtitle: '修改小风筝使用的 OA 密码',
            showConfirmation: true,
            onConfirm: () {
              SettingInitializer.auth.ssoPassword = _passwordController.text;
              return true;
            },
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: TextField(controller: _passwordController, obscureText: true),
              ),
            ],
          ),
        ],
      ),
      SimpleSettingsTile(title: '登录测试', subtitle: '检查用户名密码是否正确', onTap: () => _testPassword(context)),
      SimpleSettingsTile(title: '退出登录', subtitle: '退出当前账号', onTap: () => _onLogout(context)),
      SimpleSettingsTile(title: '清除数据', subtitle: '清除应用程序保存的账号和设置，但不包括缓存', onTap: () => _onClearStorage(context)),
      kDebugMode
          ? SettingsGroup(title: '开发者选项', children: <Widget>[
              SimpleSettingsTile(
                title: '显示本机存储内容',
                subtitle: '含首页及各模块存储的数据',
                onTap: () =>
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const DebugStoragePage())),
              )
            ])
          : const SizedBox(height: 0),
    ]);
  }
}
