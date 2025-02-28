import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'index.dart';

class IndexPage extends GetView<IndexController> {
  const IndexPage({super.key});

  // 主视图
  Widget _buildView() {
    return Center(
      child: Center(
        child: Column(
          children: [
            Obx(() {
              return Text(controller.num.toString());
            }),
            BackButton(
              onPressed: () {
                controller.inc();
                // Get.snackbar("title", "登陆过期");
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<IndexController>(
      init: IndexController(),
      id: "index",
      builder: (_) {
        return Scaffold(
          appBar: AppBar(title: const Text("index")),
          body: SafeArea(child: _buildView()),
        );
      },
    );
  }
}
