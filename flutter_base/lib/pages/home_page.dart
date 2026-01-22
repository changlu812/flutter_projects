import 'package:flutter/material.dart';
import 'month_view.dart';
import 'week_view.dart';
import 'day_view.dart';
import 'Year_page.dart';
import 'event_edit_page.dart';

class CustomTopNavigation extends StatefulWidget {
  @override
  _CustomTopNavigationState createState() => _CustomTopNavigationState();
}

class _CustomTopNavigationState extends State<CustomTopNavigation>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Widget> _views = [YearPage(), MonthView(), WeekView(), DayView()];
  final List<String> _tabs = ['年', '月', '周', '日'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            '时光糖',
            style: TextStyle(
              color: Colors.deepPurple,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: Colors.deepPurple.shade100,
        foregroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          labelColor: Colors.deepPurple,
          labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          unselectedLabelColor: Colors.grey,
          tabs: () {
            final List<Widget> tabs = [];
            for (final tab in _tabs) {
              tabs.add(Tab(text: tab));
            }
            return tabs;
          }(),
        ),
      ),
      body: TabBarView(controller: _tabController, children: _views),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => EventEditPage()),
          );
          setState(() {});
        },
      ),
    );
  }
}
