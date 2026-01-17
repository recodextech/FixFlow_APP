import 'package:flutter/foundation.dart';
import '../models/client.dart';
import '../services/database_service.dart';

class ClientProvider with ChangeNotifier {
  List<Client> _clients = [];
  final DatabaseService _dbService = DatabaseService();
  bool _isLoading = false;

  List<Client> get clients => _clients;
  bool get isLoading => _isLoading;

  ClientProvider() {
    loadClients();
  }

  Future<void> loadClients() async {
    _isLoading = true;
    notifyListeners();

    try {
      _clients = await _dbService.getClients();
    } catch (e) {
      debugPrint('Error loading clients: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addClient(Client client) async {
    try {
      final id = await _dbService.insertClient(client);
      _clients.add(client.copyWith(id: id));
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding client: $e');
      rethrow;
    }
  }

  Future<void> updateClient(Client client) async {
    try {
      await _dbService.updateClient(client);
      final index = _clients.indexWhere((c) => c.id == client.id);
      if (index != -1) {
        _clients[index] = client;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating client: $e');
      rethrow;
    }
  }

  Future<void> deleteClient(int id) async {
    try {
      await _dbService.deleteClient(id);
      _clients.removeWhere((c) => c.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting client: $e');
      rethrow;
    }
  }
}
