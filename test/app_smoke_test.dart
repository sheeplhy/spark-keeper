import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spark_keeper/app/spark_keeper_app.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows launch, dashboard, and switches to plans', (tester) async {
    await tester.pumpWidget(const SparkKeeperApp());

    expect(find.text('轻量好友管理助手'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('本地电脑'), findsOneWidget);
    expect(find.text('暂无定时任务'), findsOneWidget);

    await tester.tap(find.text('计划').last);
    await tester.pumpAndSettle();

    expect(find.text('先检查，再启用正式发送'), findsOneWidget);
    expect(find.text('添加计划'), findsWidgets);
  });

  testWidgets('switches home connection mode and shows server form', (
    tester,
  ) async {
    await tester.pumpWidget(const SparkKeeperApp());
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('好友（不限）'), findsOneWidget);
    expect(find.text('扫码连接'), findsOneWidget);

    await tester.tap(find.text('本地电脑'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('云端服务器').last);
    await tester.pumpAndSettle();

    expect(find.text('服务器地址'), findsOneWidget);
    expect(find.text('AI Agent 一键部署'), findsOneWidget);
    expect(find.textContaining('自己部署不需要 API'), findsOneWidget);
    expect(find.textContaining('Ubuntu 22.04/24.04'), findsOneWidget);
  });

  testWidgets('opens the about page and shows the developer project', (
    tester,
  ) async {
    await tester.pumpWidget(const SparkKeeperApp());
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    await tester.tap(find.text('设置').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('关于我们'));
    await tester.pumpAndSettle();

    expect(find.text('sheeplhy'), findsOneWidget);
    expect(
      find.text('https://github.com/sheeplhy/sheeplhy.github.io'),
      findsOneWidget,
    );
    expect(find.text('打开项目主页'), findsOneWidget);
  });
}
