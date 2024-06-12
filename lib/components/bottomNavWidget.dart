import 'package:event_manager/components/bottomNavProvider.dart';
import 'package:event_manager/components/constants.dart';
import 'package:event_manager/shared/exitdialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class BottomNavWidget extends StatelessWidget {
  const BottomNavWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<BottomTabsPageProvider>(
      builder: (context, bottomTabProvider, child) {
        final int currentPage = bottomTabProvider.currentPage;
        int previousPage = 0;
        return WillPopScope(
          onWillPop: () async {
            if (currentPage != 0) {
              bottomTabProvider.setCurrentPage(previousPage);
              return false;
            }
            return true;
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BottomNavigationBar(
                items: [
                  BottomNavigationBarItem(
                      label: 'Home', icon: _buildIcon(Icons.home)),
                  BottomNavigationBarItem(
                      label: 'Book Event',
                      icon: _buildIcon(Icons.book_rounded)),
                  BottomNavigationBarItem(
                      label: 'History',
                      icon: _buildIcon(Icons.history_rounded)),
                  BottomNavigationBarItem(
                      label: 'Notifications',
                      icon: _buildIcon(Icons.notifications)),
                  BottomNavigationBarItem(
                      label: 'Profile',
                      icon: _buildIcon(Icons.person_4_rounded)),
                ],
                currentIndex: bottomTabProvider.currentPage,
                iconSize: 16.h,
                type: BottomNavigationBarType.fixed,
                showUnselectedLabels: true,
                selectedIconTheme: IconThemeData(size: 18.h),
                selectedItemColor: Colors.red,
                unselectedItemColor: Colors.white,
                backgroundColor: Colors.black,
                selectedLabelStyle:
                    TextStyle(fontSize: 12.5.sp, color: Colors.red),
                unselectedLabelStyle:
                    TextStyle(fontSize: 12.5.sp, color: Colors.white),
                onTap: (page) async {
                  bottomTabProvider!.setCurrentPage(page);
                },
              )
            ],
          ),
        );
      },
    );
  }

  _buildIcon(IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 5.h),
      child: Icon(
        icon,
      ),
    );
  }
}
