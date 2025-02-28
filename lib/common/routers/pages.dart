import 'package:book_tickets/pages/index/view.dart';
import 'package:get/get.dart';
import 'package:kplayer/kplayer.dart';

import 'names.dart';

class RoutePages {
  // 列表
  static List<GetPage> list = [
    GetPage(name: RouteNames.index, page: () => const IndexPage()),
  ];

  static const INITIAL = RouteNames.index;
}
