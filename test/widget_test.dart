// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Counter increments smoke test (self-contained)', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: TestCounterApp()));
    await tester.pumpAndSettle();

    // initial value should be '0'
    expect(find.text('0'), findsOneWidget);

    // tap the button
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // now value should be '1'
    expect(find.text('1'), findsOneWidget);
  });
}

class TestCounterApp extends StatefulWidget {
  const TestCounterApp({Key? key}) : super(key: key);
  @override
  State<TestCounterApp> createState() => _TestCounterAppState();
}

class _TestCounterAppState extends State<TestCounterApp> {
  int _counter = 0;
  void _increment() => setState(() => _counter++);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Counter')),
      body: Center(
        child: Text('$_counter', key: const ValueKey('counterText'), style: const TextStyle(fontSize: 24)),
      ),
      floatingActionButton: FloatingActionButton(onPressed: _increment, child: const Icon(Icons.add)),
    );
  }
}
