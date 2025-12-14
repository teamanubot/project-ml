import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseDebugScreen extends StatefulWidget {
  final Database db;
  const DatabaseDebugScreen({Key? key, required this.db}) : super(key: key);

  @override
  State<DatabaseDebugScreen> createState() => _DatabaseDebugScreenState();
}

class _DatabaseDebugScreenState extends State<DatabaseDebugScreen> {
  String databaseContent = '';

  @override
  void initState() {
    super.initState();
    displayDatabaseContent();
  }

  Future<void> displayDatabaseContent() async {
    final StringBuffer content = StringBuffer();
    final db = widget.db;

    // Display Users Table
    content.writeln('=== USERS TABLE ===\n');
    final List<Map<String, dynamic>> users = await db.rawQuery('SELECT * FROM users');
    if (users.isNotEmpty) {
      for (final user in users) {
        content.writeln('ID: ${user['id']}');
        content.writeln('Name: ${user['name']}');
        content.writeln('Email: ${user['email']}');
        content.writeln('Created: ${user['created']}');
        content.writeln('------------------------');
      }
    } else {
      content.writeln('No users found');
    }

    content.writeln('\n\n=== ANALYSES TABLE ===\n');
    final List<Map<String, dynamic>> analyses = await db.rawQuery('SELECT * FROM analyses');
    if (analyses.isNotEmpty) {
      for (final analysis in analyses) {
        content.writeln('ID: ${analysis['id']}');
        content.writeln('User ID: ${analysis['user_id']}');
        content.writeln('Angle: ${analysis['angle']}°');
        content.writeln('Date: ${analysis['date']}');
        content.writeln('Notes: ${analysis['notes']}');
        content.writeln('------------------------');
      }
    } else {
      content.writeln('No analyses found');
    }

    setState(() {
      databaseContent = content.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Database Debug')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: SelectableText(databaseContent),
        ),
      ),
    );
  }
}
