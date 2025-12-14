import 'package:flutter/material.dart';
import '../../widgets/custom_snackbar.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class ManageAnalysesScreen extends StatefulWidget {
  static const routeName = '/admin/manage-analyses';
  @override
  _ManageAnalysesScreenState createState() => _ManageAnalysesScreenState();
}

class _ManageAnalysesScreenState extends State<ManageAnalysesScreen> {
  List<AnalysisItem> analysisList = [];
  int filterType = 0;
  DateTime? startDate;
  DateTime? endDate;
  String dateRangeText = '';
  bool isLoading = false;

  final List<String> filterOptions = [
    "All Analyses",
    "Normal (<10°)",
    "Mild (10-20°)",
    "Moderate (20-30°)",
    "Severe (>30°)"
  ];

  @override
  void initState() {
    super.initState();
    _loadAllAnalyses();
  }

  Future<void> _loadAllAnalyses() async {
    setState(() => isLoading = true);
    final api = Provider.of<ApiService>(context, listen: false);
    final analyses = await api.getAllAnalyses();
    setState(() {
      analysisList = analyses.cast<AnalysisItem>();
      dateRangeText = '';
      isLoading = false;
    });
  }

  Future<void> _filterAnalyses(int type) async {
    setState(() => filterType = type);
    if (type == 0) {
      _loadAllAnalyses();
      return;
    }
    setState(() => isLoading = true);
    final api = Provider.of<ApiService>(context, listen: false);
    final analyses = await api.getAllAnalyses();
    setState(() {
      analysisList = analyses.where((item) {
        switch (type) {
          case 1: return item.angle < 10;
          case 2: return item.angle >= 10 && item.angle < 20;
          case 3: return item.angle >= 20 && item.angle < 30;
          case 4: return item.angle >= 30;
          default: return true;
        }
      }).toList().cast<AnalysisItem>();
      dateRangeText = '';
      isLoading = false;
    });
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
      _loadAnalysesByDateRange();
    }
  }

  Future<void> _loadAnalysesByDateRange() async {
    if (startDate == null || endDate == null) return;
    setState(() => isLoading = true);
    final api = Provider.of<ApiService>(context, listen: false);
    final analyses = await api.getAnalysesByDateRange(
      startDate!,
      endDate!,
    );
    setState(() {
      analysisList = analyses.cast<AnalysisItem>();
      dateRangeText =
          "Date Range: ${DateFormat('yyyy-MM-dd').format(startDate!)} to ${DateFormat('yyyy-MM-dd').format(endDate!)}";
      isLoading = false;
    });
  }

  void _exportAnalyses() {
    CustomSnackbar.show(context, message: 'Export feature coming soon', type: SnackbarType.info);
  }

  void _clearFilter() {
    setState(() {
      filterType = 0;
      startDate = null;
      endDate = null;
      dateRangeText = '';
    });
    _loadAllAnalyses();
  }

  void _confirmDeleteAnalysis(AnalysisItem item, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Analysis'),
        content: Text('Are you sure you want to delete this analysis?'),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('Delete'),
            onPressed: () async {
              final api = Provider.of<ApiService>(context, listen: false);
              await api.deleteAnalysis(item.id.toString());
              setState(() {
                analysisList.removeAt(index);
              });
              Navigator.pop(context);
              CustomSnackbar.show(context, message: 'Analysis deleted', type: SnackbarType.success);
            },
          ),
        ],
      ),
    );
  }

  Color _getColorForAngle(double angle) {
    if (angle < 10) return Colors.green[700]!;
    if (angle < 20) return Colors.orange[800]!;
    if (angle < 30) return Colors.orange[400]!;
    return Colors.red[700]!;
  }

  String _getStatus(double angle) {
    if (angle < 10) return "Normal";
    if (angle < 20) return "Mild";
    if (angle < 30) return "Moderate";
    return "Severe";
  }

  String _formatDate(String dateString) {
    try {
      final inputFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
      final outputFormat = DateFormat('dd MMM yyyy, HH:mm');
      final date = inputFormat.parse(dateString);
      return outputFormat.format(date);
    } catch (_) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Analyses'),
        actions: [
          IconButton(
            icon: Icon(Icons.file_upload),
            onPressed: _exportAnalyses,
            tooltip: 'Export',
          ),
          IconButton(
            icon: Icon(Icons.filter_alt_off),
            onPressed: _clearFilter,
            tooltip: 'Clear Filter',
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButton<int>(
                          value: filterType,
                          items: List.generate(
                            filterOptions.length,
                            (i) => DropdownMenuItem(
                              value: i,
                              child: Text(filterOptions[i]),
                            ),
                          ),
                          onChanged: (val) {
                            if (val != null) _filterAnalyses(val);
                          },
                        ),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _pickDateRange,
                        child: Text('Date Filter'),
                      ),
                    ],
                  ),
                ),
                if (dateRangeText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        dateRangeText,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Total: ${analysisList.length} analyses',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: analysisList.length,
                    itemBuilder: (context, index) {
                      final item = analysisList[index];
                      final color = _getColorForAngle(item.angle);
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          title: Text(
                            'ID: #${item.id}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${item.userName} (${item.userEmail})'),
                              Text('Angle: ${item.angle.toStringAsFixed(2)}°',
                                  style: TextStyle(color: color)),
                              Text('Date: ${_formatDate(item.date)}'),
                              Text('Status: ${_getStatus(item.angle)}',
                                  style: TextStyle(color: color)),
                              if (item.notes != null && item.notes.isNotEmpty)
                                Text('Notes: ${item.notes}'),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmDeleteAnalysis(item, index),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class AnalysisItem {
  final int id;
  final int userId;
  final double angle;
  final String date;
  final String notes;
  final String imagePath;
  final String userName;
  final String userEmail;

  AnalysisItem({
    required this.id,
    required this.userId,
    required this.angle,
    required this.date,
    required this.notes,
    required this.imagePath,
    required this.userName,
    required this.userEmail,
  });
}