import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/message.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({Key? key}) : super(key: key);

  @override
  _MessagesScreenState createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<Message> _messages = [];
  bool _isLoading = true;
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    setState(() => _isLoading = true);
    try {
      final token = await _storage.read(key: 'jwt_token');

      final response = await http.get(
        Uri.parse('https://bolougo-api.runasp.net/api/messages'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _messages = data.map((json) => Message.fromJson(json)).toList();
        });
      } else {
        _showError('Erreur de chargement des messages');
      }
    } catch (e) {
      _showError('Erreur de connexion');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(int id) async {
    try {
      final token = await _storage.read(key: 'jwt_token');

      final response = await http.put(
        Uri.parse('https://bolougo-api.runasp.net/api/messages/$id/read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 204) {
        setState(() {
          final index = _messages.indexWhere((m) => m.id == id);
          if (index != -1) {
            _messages[index] = Message(
              id: _messages[index].id,
              name: _messages[index].name,
              phone: _messages[index].phone,
              email: _messages[index].email,
              messageText: _messages[index].messageText,
              isRead: true,
              createdAt: _messages[index].createdAt,
            );
          }
        });
      }
    } catch (e) {
      _showError('Erreur lors du marquage comme lu');
    }
  }

  Future<void> _deleteMessage(int id) async {
    try {
      final token = await _storage.read(key: 'jwt_token');

      final response = await http.delete(
        Uri.parse('https://bolougo-api.runasp.net/api/messages/$id'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 204) {
        setState(() {
          _messages.removeWhere((m) => m.id == id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message supprimé')),
        );
      }
    } catch (e) {
      _showError('Erreur de suppression');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages de Contact'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _messages.isEmpty
              ? const Center(child: Text('Aucun message reçu.'))
              : RefreshIndicator(
                  onRefresh: _fetchMessages,
                  child: ListView.builder(
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return Dismissible(
                        key: Key(message.id.toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20.0),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text("Confirmer"),
                                content: const Text("Voulez-vous vraiment supprimer ce message ?"),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text("ANNULER"),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: const Text("SUPPRIMER"),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        onDismissed: (direction) {
                          _deleteMessage(message.id);
                        },
                        child: Card(
                          color: message.isRead ? null : Colors.green.shade50,
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: ExpansionTile(
                            leading: Icon(
                              Icons.mail,
                              color: message.isRead ? Colors.grey : Colors.green,
                            ),
                            title: Text(
                              message.name,
                              style: TextStyle(
                                fontWeight: message.isRead ? FontWeight.normal : FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              "${message.createdAt.day}/${message.createdAt.month}/${message.createdAt.year}",
                              style: const TextStyle(fontSize: 12),
                            ),
                            onExpansionChanged: (expanded) {
                              if (expanded && !message.isRead) {
                                _markAsRead(message.id);
                              }
                            },
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (message.phone != null && message.phone!.isNotEmpty)
                                      Text("Tél: ${message.phone}"),
                                    if (message.email != null && message.email!.isNotEmpty)
                                      Text("Email: ${message.email}"),
                                    const SizedBox(height: 8),
                                    const Text("Message:", style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(message.messageText),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
