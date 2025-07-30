import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:playground_application/RecordingScreen.dart';

// 1. Controller with reactive state
class CounterController extends GetxController {
  var count = 0.obs;
  void increment() => count.value++;
}

// 2. App starts here
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // Bind dependencies
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'GetX Demo',
      initialRoute: '/',
      locale: Locale('en', 'US'),
      translations: MyTranslations(),
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      getPages: [
        GetPage(name: '/', page: () => HomePage(), binding: BindingsBuilder(() {
          Get.lazyPut<CounterController>(() => CounterController());
        })),
        GetPage(name: '/second', page: () => SecondPage()),
        GetPage(name: '/record', page: () => RecordingScreen()),
      ],
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<CounterController>();
    return Scaffold(
      appBar: AppBar(
        title: Text('home_title'.tr),
        actions: [
          IconButton(
            icon: Icon(Icons.language),
            onPressed: () {
              var next = Get.locale?.languageCode == 'en' ? Locale('es', 'ES') : Locale('en', 'US');
              Get.updateLocale(next);
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          children: [
            Obx(() => Text('Clicks: ${ctrl.count}')),
            ElevatedButton(
              child: Text('go_record'.tr),
              onPressed: () => Get.toNamed('/record'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: ctrl.increment,
        child: Icon(Icons.add),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(8),
        child: ElevatedButton(
          onPressed: () => Get.toNamed('/second'),
          child: Text('go_second'.tr),
        ),
      ),
    );
  }
}

class SecondPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<CounterController>();
    return Scaffold(
      appBar: AppBar(title: Text('second_title'.tr)),
      body: Center(child: Obx(() => Text('Clicks still: ${ctrl.count}'))),
    );
  }
}

// 3. Simple translations
class MyTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': {
      'home_title': 'Home Page',
      'go_second': 'Go to Second',
      'second_title': 'Second Page',
    },
    'es_ES': {
      'home_title': 'Página Principal',
      'go_second': 'Ir a Segunda',
      'second_title': 'Segunda Página',
    },
  };
}
