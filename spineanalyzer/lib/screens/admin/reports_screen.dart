import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class ReportsScreen extends StatefulWidget {
  static const routeName = '/admin/reports';
  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int totalUsers = 0;
  int totalAnalyses = 0;
  double avgAngle = 0.0;
  int highRiskCount = 0;
  int normalPercent = 0, mildPercent = 0, moderatePercent = 0, severePercent = 0;
  int selectedPeriod = 0;
  String startDate = '';
  String endDate = '';
  bool isLoading = false;

  final List<String> periods = [
    "All Time",
    "Last 7 Days",
    "Last 30 Days",
    "Last 3 Months",
    "Last Year",
    "Custom Range"
  ];

  @override
  void initState() {
    super.initState();
    _loadBasicStatistics();
  }

  Future<void> _loadBasicStatistics() async {
    setState(() => isLoading = true);
    final api = Provider.of<ApiService>(context, listen: false);
    final stats = await api.getDashboardStatistics();
    setState(() {
      totalUsers = stats['totalUsers'] ?? 0;
      totalAnalyses = stats['totalAnalyses'] ?? 0;
      avgAngle = stats['averageAngle']?.toDouble() ?? 0.0;
      highRiskCount = stats['severeCount'] ?? 0;
      normalPercent = stats['normalPercent'] ?? 0;
      mildPercent = stats['mildPercent'] ?? 0;
      moderatePercent = stats['moderatePercent'] ?? 0;
      severePercent = stats['severePercent'] ?? 0;
      isLoading = false;
    });
  }

  Future<void> _loadFilteredStatistics() async {
    setState(() => isLoading = true);
    final api = Provider.of<ApiService>(context, listen: false);
    // Pastikan startDate dan endDate bertipe DateTime
    final stats = await api.getStatisticsByDateRange(DateTime.parse(startDate), DateTime.parse(endDate));
    setState(() {
      totalUsers = stats['totalUsers'] ?? 0;
      totalAnalyses = stats['totalAnalyses'] ?? 0;
      avgAngle = stats['averageAngle']?.toDouble() ?? 0.0;
      highRiskCount = stats['severeCount'] ?? 0;
      normalPercent = stats['normalPercent'] ?? 0;
      mildPercent = stats['mildPercent'] ?? 0;
      moderatePercent = stats['moderatePercent'] ?? 0;
      severePercent = stats['severePercent'] ?? 0;
      isLoading = false;
    });
    _showToast('Filtered: $startDate to $endDate');
  }

  void _handlePeriodSelection(int position) {
    setState(() => selectedPeriod = position);
    final now = DateTime.now();
    final dateFormat = DateFormat('yyyy-MM-dd');
    endDate = dateFormat.format(now);
    switch (position) {
      case 0: // All Time
        startDate = '';
        endDate = '';
        _loadBasicStatistics();
        break;
      case 1: // Last 7 Days
        startDate = dateFormat.format(now.subtract(Duration(days: 7)));
        _loadFilteredStatistics();
        break;
      case 2: // Last 30 Days
        startDate = dateFormat.format(now.subtract(Duration(days: 30)));
        _loadFilteredStatistics();
        break;
      case 3: // Last 3 Months
        startDate = dateFormat.format(DateTime(now.year, now.month - 3, now.day));
        _loadFilteredStatistics();
        break;
      case 4: // Last Year
        startDate = dateFormat.format(DateTime(now.year - 1, now.month, now.day));
        _loadFilteredStatistics();
        break;
      case 5: // Custom Range
        _showDateRangePicker();
        break;
    }
  }

  void _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        startDate = DateFormat('yyyy-MM-dd').format(picked.start);
        endDate = DateFormat('yyyy-MM-dd').format(picked.end);
      });
      _loadFilteredStatistics();
    }
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildProgressBar(String label, int percent, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: $percent%'),
        SizedBox(height: 4),
        LinearProgressIndicator(
          value: percent / 100.0,
          color: color,
          backgroundColor: color.withOpacity(0.2),
          minHeight: 8,
        ),
        SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reports & Analytics'),
        leading: BackButton(),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<int>(
                        value: selectedPeriod,
                        items: List.generate(
                          periods.length,
                          (i) => DropdownMenuItem(
                            value: i,
                            child: Text(periods[i]),
                          ),
                        ),
                        onChanged: (val) {
                          if (val != null) _handlePeriodSelection(val);
                        },
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _showDateRangePicker,
                      child: Text('Date Range'),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text('Overview', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatCard('Total Users', totalUsers.toString()),
                            _buildStatCard('Total Analyses', totalAnalyses.toString()),
                            _buildStatCard('Avg Angle', '${avgAngle.toStringAsFixed(1)}°'),
                            _buildStatCard('Severe Cases', highRiskCount.toString()),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                _buildProgressBar('Normal', normalPercent, Colors.green),
                _buildProgressBar('Mild', mildPercent, Colors.orange),
                _buildProgressBar('Moderate', moderatePercent, Colors.amber),
                _buildProgressBar('Severe', severePercent, Colors.red),
                SizedBox(height: 16),
                Card(
                  child: Container(
                    height: 200,
                    alignment: Alignment.center,
                    child: Text('Pie/Bar/Line Chart Placeholder\n(Integrate fl_chart or similar)'),
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _showToast('Report generation - coming soon'),
                  child: Text('Generate Report'),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Text(label),
      ],
    );
  }
}