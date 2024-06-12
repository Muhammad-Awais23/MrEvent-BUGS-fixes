import 'package:event_manager/components/LoadingWidget.dart';
import 'package:event_manager/components/bottomNavProvider.dart';
import 'package:event_manager/components/bottomNavWidget.dart';
import 'package:event_manager/shared/exitdialog.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

class BottomTabsPage extends StatefulWidget {
  const BottomTabsPage({Key? key}) : super(key: key);

  @override
  State<BottomTabsPage> createState() => _BottomTabsPageState();
}

class _BottomTabsPageState extends State<BottomTabsPage>
    with WidgetsBindingObserver {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<BottomTabsPageProvider>(
        builder: (context, value, child) {
          if (value.pages.isEmpty) {
            return const Center(
              child: loadingWidget(),
            );
          }
          return value.pages[value.currentPage];
        },
      ),
      bottomNavigationBar: const BottomNavWidget(),
    );
  }
}
