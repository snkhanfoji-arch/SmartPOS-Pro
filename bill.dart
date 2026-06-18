import 'dart:convert';

class BillItem {
  final String productName;
  final double price;
  final int quantity;
  final double total;

  BillItem({
    required this.productName,
    required this.price,
    required this.quantity,
    required this.total,
  });

  Map<String, dynamic> toMap() {
    return {
      'productName': productName,
      'price': price,
      'quantity': quantity,
      'total': total,
    };
  }

  factory BillItem.fromMap(Map<String, dynamic> map) {
    return BillItem(
      productName: map['productName'] as String,
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'] as int,
      total: (map['total'] as num).toDouble(),
    );
  }
}

class Bill {
  final int? id;
  final String date; // Store as ISO8601 string or format
  final double total;
  final List<BillItem> items;

  Bill({
    this.id,
    required this.date,
    required this.total,
    required this.items,
  });

  // Convert Bill to database Map representation with JSON string
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date,
      'total': total,
      'items_json': jsonEncode(items.map((e) => e.toMap()).toList()),
    };
  }

  // Create Bill from database Map representation
  factory Bill.fromMap(Map<String, dynamic> map) {
    final list = jsonDecode(map['items_json'] as String) as List;
    final List<BillItem> loadedItems = list
        .map((itemMap) => BillItem.fromMap(itemMap as Map<String, dynamic>))
        .toList();

    return Bill(
      id: map['id'] as int?,
      date: map['date'] as String,
      total: (map['total'] as num).toDouble(),
      items: loadedItems,
    );
  }
}
