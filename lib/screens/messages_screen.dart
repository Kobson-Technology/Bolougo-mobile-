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

  // Nombre de messages non lus
  int get _unreadCount => _messages.where((m) => !m.isRead).length;

  // Affiche la modale du message complet
  void _showFullMessage(BuildContext context, Message message) {
    if (!message.isRead) _markAsRead(message.id);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Poignée
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // En-tête
              Row(
                children: [
                  const Icon(Icons.mail, color: Color(0xFFEF4444)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (message.phone != null && message.phone!.isNotEmpty)
                Row(children: [
                  const Icon(Icons.phone, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(message.phone!, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ]),
              if (message.email != null && message.email!.isNotEmpty)
                Row(children: [
                  const Icon(Icons.email, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(message.email!, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ]),
              Text(
                "${message.createdAt.day}/${message.createdAt.month}/${message.createdAt.year} à ${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const Divider(height: 24),
              // Message
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  child: Text(
                    message.messageText,
                    style: const TextStyle(fontSize: 15, height: 1.7),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Messages de Contact'),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _unreadCount > 99 ? '99+' : '$_unreadCount',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ]
          ],
        ),
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
                                    child: const Text("SUPPRIMER", style: TextStyle(color: Colors.red)),
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
                          color: message.isRead ? null : Colors.red.shade50,
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: ListTile(
                            leading: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Icon(
                                  Icons.mail,
                                  color: message.isRead ? Colors.grey : const Color(0xFFEF4444),
                                  size: 28,
                                ),
                                if (!message.isRead)
                                  Positioned(
                                    top: -4, right: -4,
                                    child: Container(
                                      width: 10, height: 10,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFEF4444),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            title: Text(
                              message.name,
                              style: TextStyle(
                                fontWeight: message.isRead ? FontWeight.normal : FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              message.messageText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: message.isRead ? Colors.grey : Colors.black87,
                                fontSize: 13,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "${message.createdAt.day}/${message.createdAt.month}",
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.chevron_right, color: Colors.grey),
                              ],
                            ),
                            onTap: () => _showFullMessage(context, message),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
