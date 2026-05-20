import 'package:flutter/foundation.dart';
import '../models/customer.dart';
import '../database/database_helper.dart';

class CollectionProvider with ChangeNotifier {
  Set<int> _collectionIds = {};
  List<Customer> _collectionCustomers = [];
  bool _isLoading = false;

  Set<int> get collectionIds => _collectionIds;
  List<Customer> get collectionCustomers => _collectionCustomers;
  int get count => _collectionIds.length;
  bool get isLoading => _isLoading;

  bool isInCollection(int customerId) {
    return _collectionIds.contains(customerId);
  }

  Future<void> loadCollectionList() async {
    _isLoading = true;
    notifyListeners();

    final ids = await DatabaseHelper.instance.getCollectionListCustomerIds();
    _collectionIds = ids.toSet();

    final allCustomers = await DatabaseHelper.instance.getAllCustomers();
    _collectionCustomers = allCustomers
        .where((c) => _collectionIds.contains(c.id))
        .toList();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addToCollection(int customerId) async {
    await DatabaseHelper.instance.addToCollectionList(customerId);
    await loadCollectionList();
  }

  Future<void> removeFromCollection(int customerId) async {
    await DatabaseHelper.instance.removeFromCollectionList(customerId);
    await loadCollectionList();
  }

  Future<void> clearCollection() async {
    await DatabaseHelper.instance.clearCollectionList();
    await loadCollectionList();
  }
}
