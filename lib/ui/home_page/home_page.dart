import 'package:flutter/material.dart';
import 'package:v2net/ui/widgets/gap_widget/gap.dart';
import 'package:v2net/core/platform/vpn_api.g.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final ExpansibleController _controller;
  bool _isConnected = false;
  final VpnConnection _vpn = VpnConnection();

  @override
  void initState() {
    super.initState();
    _controller = ExpansibleController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onVpnStart() async {
    try {
      VpnResult result;

      // Выбираем метод в зависимости от текущего состояния
      if (_isConnected) {
        print('Отправляю команду stop()...');
        result = await _vpn.stop();
      } else {
        print('Отправляю команду start()...');
        result = await _vpn.start();
      }

      // Если Kotlin ответил успехом, меняем UI
      if (result.successful == true) {
        setState(() {
          _isConnected = !_isConnected;
        });
        print('VPN: Успешно! Состояние изменено.');
      } else {
        print('VPN Ошибка: ${result.error}');
      }
    } catch (e) {
      // Ловим краши от натива
      print('VPN: Критическая ошибка моста: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const .symmetric(horizontal: 12, vertical: 12),
            child: Column(
              children: [
                ConnectionButton(
                  isConnected: _isConnected,
                  onTap: _onVpnStart, // Передаем ссылку на функцию
                ),
                Gap(height: 12),
                Expansible(
                  headerBuilder: (context, animation) => _headerWidget(context, animation, _controller),
                  bodyBuilder: (context, animation) => _bodyWidget(),
                  controller: _controller,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

ListTile _headerWidget(BuildContext context, Animation<double> animation, ExpansibleController controller) {
  return ListTile(
    title: const Text('Subs name'),
    onTap: () {
      if (controller.isExpanded) {
        controller.collapse();
      } else {
        controller.expand();
      }
    },
    trailing: RotationTransition(
      turns: Tween<double>(begin: 0.0, end: 0.5).animate(animation),
      child: const Icon(Icons.arrow_drop_down),
    ),
  );
}

ListView _bodyWidget() {
  return ListView.separated(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemBuilder: (context, index) => _bodyWidgetItemBuilder(context, index),
    separatorBuilder: (context, index) => const Gap(height: 8),
    itemCount: 4,
  );
}

Container _bodyWidgetItemBuilder(BuildContext context, int index) {
  return Container(
    height: 20,
    width: double.maxFinite,
    decoration: BoxDecoration(borderRadius: .circular(12)),
    child: Text('Server ${index + 1}'),
  );
}

class ConnectionButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isConnected; // Добавили параметр состояния

  const ConnectionButton({
    super.key,
    required this.onTap,
    required this.isConnected, // Сделали обязательным
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        width: 80,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.black),
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // Меняем цвет в зависимости от ответа из Kotlin
            color: isConnected ? Colors.red : Colors.green,
          ),
          child: const Icon(Icons.power_settings_new, size: 40, color: Colors.white),
        ),
      ),
    );
  }
}
