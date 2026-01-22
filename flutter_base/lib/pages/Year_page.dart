import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/event_service.dart';
import 'month_view.dart';
import 'event_edit_page.dart';

class YearPage extends StatefulWidget {
  @override
  _YearPageState createState() => _YearPageState();
}

class _YearPageState extends State<YearPage> {
  late int _selectedYear;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showYearPicker() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('选择年份'),
        content: SizedBox(
          width: 300,
          height: 300,
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: 21,
            itemBuilder: (context, idx) {
              final year = DateTime.now().year - 10 + idx;
              final isSelected = year == _selectedYear;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedYear = year);
                  Navigator.pop(ctx);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.deepPurple
                        : Colors.deepPurple.shade700,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      year.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: isSelected ? 18 : 16,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventService = context.watch<EventService>();
    return Column(
      children: [
        // Year selector header
        Container(
          color: Colors.deepPurple.shade900,
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, color: Colors.white),
                onPressed: () => setState(() => _selectedYear--),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _showYearPicker,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        _selectedYear.toString(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right, color: Colors.white),
                onPressed: () => setState(() => _selectedYear++),
              ),
            ],
          ),
        ),
        // 12-month grid
        Expanded(
          child: GridView.builder(
            controller: _scrollController,
            padding: EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.0,
            ),
            itemCount: 12,
            itemBuilder: (context, idx) {
              final month = idx + 1;
              final monthStart = DateTime(_selectedYear, month, 1);
              final monthEnd = month == 12
                  ? DateTime(_selectedYear + 1, 1, 1)
                  : DateTime(_selectedYear, month + 1, 1);
              final eventsInMonth = eventService.events
                  .where(
                    (e) =>
                        e.startTime.isAfter(monthStart) &&
                        e.startTime.isBefore(monthEnd),
                  )
                  .length;
              return _buildMonthCard(month, eventsInMonth, monthStart);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMonthCard(int month, int eventCount, DateTime monthDate) {
    final monthShort = [
      '1月',
      '2月',
      '3月',
      '4月',
      '5月',
      '6月',
      '7月',
      '8月',
      '9月',
      '10月',
      '11月',
      '12月',
    ][month - 1];
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(title: Text('${_selectedYear}年${monthShort}')),
              body: MonthView(initialDate: monthDate),
              floatingActionButton: FloatingActionButton(
                child: Icon(Icons.add),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EventEditPage()),
                  );
                },
              ),
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.deepPurple.shade800,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              monthShort,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$eventCount 个事件',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
