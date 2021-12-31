import 'package:kite/services/sso/sso.dart';
import 'package:beautiful_soup_dart/beautiful_soup.dart';

class MyPortal {
  Session session;

  MyPortal(this.session);

  getUserInfo() async {
    var response = await session.get('https://myportal.sit.edu.cn/');
    String html = response.data;
    return BeautifulSoup(html)
        .find('div', class_: 'composer')!
        .findAll('li')
        .map((e) => e.text.trim().replaceAll('\n', '').replaceAll(' ', ''))
        .toList();
  }
}