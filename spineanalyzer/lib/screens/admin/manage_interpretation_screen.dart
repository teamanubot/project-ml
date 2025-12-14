import 'package:flutter/material.dart';
import '../../widgets/custom_snackbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ManageInterpretationScreen extends StatefulWidget {
  static const routeName = '/admin/manage-interpretation';
  @override
  _ManageInterpretationScreenState createState() => _ManageInterpretationScreenState();
}

class _ManageInterpretationScreenState extends State<ManageInterpretationScreen> {
  List<InterpretationRule> interpretationList = [];
  late SharedPreferences prefs;
  static const String INTERPRETATION_PREF = "InterpretationRules";

  @override
  void initState() {
    super.initState();
    _loadInterpretationRules();
  }

  Future<void> _loadInterpretationRules() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      interpretationList = [];
      if (!prefs.containsKey("rule_count")) {
        // Default rules
        interpretationList.add(InterpretationRule(
          minAngle: 0,
          maxAngle: 10,
          status: "Normal",
          description: "Tulang belakang normal, tidak perlu tindakan khusus",
          recommendation: "",
        ));
        interpretationList.add(InterpretationRule(
          minAngle: 10,
          maxAngle: 20,
          status: "Skoliosis Ringan",
          description: "Perlu pemantauan berkala, olahraga teratur",
          recommendation:
              "• Lakukan olahraga rutin seperti berenang, yoga, atau pilates\n"
              "• Perhatikan postur tubuh saat duduk dan berdiri\n"
              "• Lakukan peregangan punggung secara teratur\n"
              "• Hindari mengangkat beban berat secara berlebihan",
        ));
        interpretationList.add(InterpretationRule(
          minAngle: 20,
          maxAngle: 30,
          status: "Skoliosis Sedang",
          description: "Konsultasi dokter diperlukan, mungkin perlu terapi",
          recommendation:
              "• Konsultasi dengan fisioterapis untuk program latihan khusus\n"
              "• Lakukan terapi fisik dan latihan penguatan otot punggung\n"
              "• Pantau perkembangan skoliosis secara berkala\n"
              "• Hindari aktivitas yang memberikan tekanan berlebih pada tulang belakang\n"
              "• Pertimbangkan penggunaan brace jika direkomendasikan dokter",
        ));
        interpretationList.add(InterpretationRule(
          minAngle: 30,
          maxAngle: 100,
          status: "Skoliosis Berat",
          description: "Segera konsultasi dokter spesialis, perlu penanganan serius",
          recommendation:
              "• WAJIB konsultasi dengan dokter spesialis ortopedi\n"
              "• Lakukan pemeriksaan X-ray untuk evaluasi lebih detail\n"
              "• Ikuti program fisioterapi intensif\n"
              "• Pertimbangkan penggunaan brace korektif\n"
              "• Pantau perkembangan secara ketat dan rutin",
        ));
        _saveRules();
      } else {
        int count = prefs.getInt("rule_count") ?? 0;
        for (int i = 0; i < count; i++) {
          double minAngle = prefs.getDouble("min_$i") ?? 0;
          double maxAngle = prefs.getDouble("max_$i") ?? 0;
          String status = prefs.getString("status_$i") ?? "";
          String description = prefs.getString("desc_$i") ?? "";
          String recommendation = prefs.getString("recommendation_$i") ?? "";
          interpretationList.add(InterpretationRule(
            minAngle: minAngle,
            maxAngle: maxAngle,
            status: status,
            description: description,
            recommendation: recommendation,
          ));
        }
      }
    });
  }

  Future<void> _saveRules() async {
    await prefs.setInt("rule_count", interpretationList.length);
    for (int i = 0; i < interpretationList.length; i++) {
      final rule = interpretationList[i];
      await prefs.setDouble("min_$i", rule.minAngle);
      await prefs.setDouble("max_$i", rule.maxAngle);
      await prefs.setString("status_$i", rule.status);
      await prefs.setString("desc_$i", rule.description);
      await prefs.setString("recommendation_$i", rule.recommendation);
    }
  }

  void _showAddInterpretationDialog() {
    final minAngleController = TextEditingController();
    final maxAngleController = TextEditingController();
    final statusController = TextEditingController();
    final descController = TextEditingController();
    final recController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Interpretation Rule'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: minAngleController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Min Angle'),
              ),
              TextField(
                controller: maxAngleController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Max Angle'),
              ),
              TextField(
                controller: statusController,
                decoration: InputDecoration(labelText: 'Status'),
              ),
              TextField(
                controller: descController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: recController,
                decoration: InputDecoration(labelText: 'Recommendation'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('Add'),
            onPressed: () {
              try {
                final minAngle = double.parse(minAngleController.text);
                final maxAngle = double.parse(maxAngleController.text);
                final status = statusController.text;
                final desc = descController.text;
                final rec = recController.text;
                if (minAngle >= maxAngle) {
                  _showToast('Min angle must be less than max angle');
                  return;
                }
                if (status.trim().isEmpty) {
                  _showToast('Status cannot be empty');
                  return;
                }
                setState(() {
                  interpretationList.add(InterpretationRule(
                    minAngle: minAngle,
                    maxAngle: maxAngle,
                    status: status,
                    description: desc,
                    recommendation: rec,
                  ));
                });
                _saveRules();
                Navigator.pop(context);
                _showToast('Rule added successfully');
              } catch (_) {
                _showToast('Invalid angle values');
              }
            },
          ),
        ],
      ),
    );
  }

  void _showEditInterpretationDialog(int index) {
    final rule = interpretationList[index];
    final minAngleController = TextEditingController(text: rule.minAngle.toString());
    final maxAngleController = TextEditingController(text: rule.maxAngle.toString());
    final statusController = TextEditingController(text: rule.status);
    final descController = TextEditingController(text: rule.description);
    final recController = TextEditingController(text: rule.recommendation);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Interpretation Rule'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: minAngleController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Min Angle'),
              ),
              TextField(
                controller: maxAngleController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Max Angle'),
              ),
              TextField(
                controller: statusController,
                decoration: InputDecoration(labelText: 'Status'),
              ),
              TextField(
                controller: descController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: recController,
                decoration: InputDecoration(labelText: 'Recommendation'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('Update'),
            onPressed: () {
              try {
                final minAngle = double.parse(minAngleController.text);
                final maxAngle = double.parse(maxAngleController.text);
                final status = statusController.text;
                final desc = descController.text;
                final rec = recController.text;
                if (minAngle >= maxAngle) {
                  _showToast('Min angle must be less than max angle');
                  return;
                }
                setState(() {
                  interpretationList[index] = InterpretationRule(
                    minAngle: minAngle,
                    maxAngle: maxAngle,
                    status: status,
                    description: desc,
                    recommendation: rec,
                  );
                });
                _saveRules();
                Navigator.pop(context);
                _showToast('Rule updated successfully');
              } catch (_) {
                _showToast('Invalid angle values');
              }
            },
          ),
        ],
      ),
    );
  }

  void _deleteRule(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Rule'),
        content: Text('Are you sure you want to delete this rule?'),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('Delete'),
            onPressed: () {
              setState(() {
                interpretationList.removeAt(index);
              });
              _saveRules();
              Navigator.pop(context);
              _showToast('Rule deleted');
            },
          ),
        ],
      ),
    );
  }

  void _showToast(String message) {
    CustomSnackbar.show(context, message: message, type: SnackbarType.error);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Interpretations'),
        leading: BackButton(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddInterpretationDialog,
        child: Icon(Icons.add),
        tooltip: 'Add Interpretation Rule',
      ),
      body: ListView.builder(
        itemCount: interpretationList.length,
        itemBuilder: (context, index) {
          final rule = interpretationList[index];
          final recPreview = rule.recommendation.length > 50
              ? rule.recommendation.substring(0, 50) + '...'
              : rule.recommendation;
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text('${rule.minAngle.toStringAsFixed(0)}° - ${rule.maxAngle.toStringAsFixed(0)}°'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rule.status, style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(rule.description),
                  if (rule.recommendation.isNotEmpty)
                    Text('Rekomendasi: $recPreview'),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showEditInterpretationDialog(index),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteRule(index),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class InterpretationRule {
  double minAngle;
  double maxAngle;
  String status;
  String description;
  String recommendation;

  InterpretationRule({
    required this.minAngle,
    required this.maxAngle,
    required this.status,
    required this.description,
    required this.recommendation,
  });
}