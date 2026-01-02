//flutter_app/lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../models/person.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'add_person_screen.dart';
import 'edit_person_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Person> persons = [];
  bool isLoading = true;
  User? currentUser;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadUser();
    await _loadPersons();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getCurrentUser();
    setState(() => currentUser = user);
  }

  Future<void> _loadPersons() async {
    setState(() => isLoading = true);
    try {
      final loadedPersons = await ApiService.getPersons();
      setState(() {
        persons = loadedPersons;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showMessage(e.toString(), isError: true);
    }
  }

  Future<void> _deletePerson(int id) async {
    try {
      await ApiService.deletePerson(id);
      _loadPersons();
      _showMessage('Contact supprimé avec succès');
    } catch (e) {
      _showMessage(e.toString(), isError: true);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text('Déconnexion'),
        content: Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Se déconnecter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.logout();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _navigateToAdd() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddPersonScreen()),
    );
    if (result == true) _loadPersons();
  }

  void _navigateToEdit(Person person) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditPersonScreen(person: person)),
    );
    if (result == true) _loadPersons();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mes Contacts', style: TextStyle(fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
          ),
        ),
        actions: [
          if (currentUser != null)
            Padding(
              padding: EdgeInsets.only(right: 8),
              child: Center(
                child: Chip(
                  avatar: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Text(
                      currentUser!.username[0].toUpperCase(),
                      style: TextStyle(color: Color(0xFF667eea)),
                    ),
                  ),
                  label: Text(currentUser!.username),
                  backgroundColor: Colors.white.withOpacity(0.2),
                  labelStyle: TextStyle(color: Colors.white),
                ),
              ),
            ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF667eea).withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF667eea)),
                    SizedBox(height: 16),
                    Text('Chargement...', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            : persons.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.contacts_outlined, size: 100, color: Colors.grey[300]),
                        SizedBox(height: 16),
                        Text(
                          'Aucun contact',
                          style: TextStyle(fontSize: 20, color: Colors.grey[600]),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Appuyez sur + pour ajouter',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadPersons,
                    color: Color(0xFF667eea),
                    child: ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: persons.length,
                      itemBuilder: (ctx, index) {
                        final person = persons[index];
                        return Dismissible(
                          key: Key(person.id.toString()),
                          background: Container(
                            margin: EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.red, Colors.red[300]!],
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            alignment: Alignment.centerRight,
                            padding: EdgeInsets.only(right: 20),
                            child: Icon(Icons.delete, color: Colors.white, size: 30),
                          ),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (direction) async {
                            return await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                title: Text('Confirmer la suppression'),
                                content: Text(
                                  'Êtes-vous sûr de vouloir supprimer ${person.prenom} ${person.nom} ?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: Text('Annuler'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    child: Text(
                                      'Supprimer',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          onDismissed: (direction) {
                            _deletePerson(person.id!);
                          },
                          child: Card(
                            elevation: 3,
                            margin: EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(12),
                              leading: Container(
                                width: 55,
                                height: 55,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    person.prenom.isNotEmpty
                                        ? person.prenom[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                '${person.prenom} ${person.nom}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Row(
                                children: [
                                  Icon(Icons.phone, size: 14, color: Colors.grey),
                                  SizedBox(width: 4),
                                  Text(person.telephone),
                                ],
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.edit, color: Color(0xFF667eea)),
                                onPressed: () => _navigateToEdit(person),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAdd,
        icon: Icon(Icons.add),
        label: Text('Ajouter'),
        backgroundColor: Color(0xFF667eea),
        foregroundColor: Colors.white,
      ),
    );
  }
}