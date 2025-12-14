import 'package:flutter/material.dart';
import '../../widgets/custom_snackbar.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';

class ManageUsersScreen extends StatefulWidget {
  static const routeName = '/admin/manage-users';
  @override
  _ManageUsersScreenState createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  List<UserItem> userList = [];
  List<UserItem> filteredList = [];
  bool isLoading = false;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => isLoading = true);
    final api = Provider.of<ApiService>(context, listen: false);
    final users = await api.getAllUsersWithAnalysisCount();
    setState(() {
      userList = users.cast<UserItem>();
      filteredList = List.from(users);
      isLoading = false;
    });
  }

  void _filterUsers(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredList = List.from(userList);
      } else {
        final lowerQuery = query.toLowerCase();
        filteredList = userList.where((user) =>
          user.name.toLowerCase().contains(lowerQuery) ||
          user.email.toLowerCase().contains(lowerQuery)
        ).toList();
      }
    });
  }

  void _editUser(UserItem user) {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('Update'),
            onPressed: () async {
              final newName = nameController.text.trim();
              final newEmail = emailController.text.trim();
              if (newName.isEmpty || newEmail.isEmpty) {
                _showToast('Please fill all fields');
                return;
              }
              final api = Provider.of<ApiService>(context, listen: false);
              final result = await api.updateUser(user.id.toString(), newName, newEmail);
              if (result) {
                _showToast('User updated successfully');
                Navigator.pop(context);
                _loadUsers();
              } else {
                _showToast('Failed to update user');
              }
            },
          ),
        ],
      ),
    );
  }

  void _confirmDeleteUser(UserItem user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.name}? This will also delete all their analyses.'),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('Delete'),
            onPressed: () async {
              final api = Provider.of<ApiService>(context, listen: false);
              final result = await api.deleteUser(user.id.toString());
              if (result) {
                _showToast('User deleted successfully');
                Navigator.pop(context);
                _loadUsers();
              } else {
                _showToast('Failed to delete user');
              }
            },
          ),
        ],
      ),
    );
  }

  void _viewUserAnalyses(UserItem user) {
    _showToast('View analyses for ${user.name}');
    // TODO: Navigate to user's analyses screen
  }

  void _showToast(String message) {
    CustomSnackbar.show(context, message: message, type: SnackbarType.error);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Users'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Search users...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _filterUsers,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final user = filteredList[index];
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          title: Text(user.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.email),
                              Text('Joined: ${user.createdAt}'),
                              Text('Analyses: ${user.analysisCount}'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _editUser(user),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _confirmDeleteUser(user),
                              ),
                              IconButton(
                                icon: Icon(Icons.bar_chart, color: Colors.green),
                                onPressed: () => _viewUserAnalyses(user),
                              ),
                            ],
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

class UserItem {
  final int id;
  final String name;
  final String email;
  final String createdAt;
  final int analysisCount;

  UserItem({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
    required this.analysisCount,
  });
}