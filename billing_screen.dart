import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/product.dart';
import '../models/bill.dart';
import '../widgets/product_card.dart';
import '../services/pdf_service.dart';
import 'package:intl/intl.dart';

class BillingScreen extends StatefulWidget {
  final String shopName;
  final String currencySymbol;
  const BillingScreen({
    super.key,
    required this.shopName,
    required this.currencySymbol,
  });

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class CartEntry {
  final Product product;
  int quantity;

  CartEntry({required this.product, required this.quantity});

  double get total => product.price * quantity;
}

class _BillingScreenState extends State<BillingScreen> {
  List<Product> _products = [];
  final Map<int, CartEntry> _cart = {}; // key: product id
  bool _isLoading = true;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _refreshProducts();
  }

  Future<void> _refreshProducts() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final data = await DBHelper.instance.getAllProducts();
      setState(() {
        _products = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  void _addToCart(Product product) {
    if (product.id == null) return;
    
    // Check if item is already in cart
    if (_cart.containsKey(product.id)) {
      final entry = _cart[product.id]!;
      if (entry.quantity < product.stock) {
        setState(() {
          entry.quantity++;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cannot exceed available stock level!")),
        );
      }
    } else {
      if (product.stock > 0) {
        setState(() {
          _cart[product.id!] = CartEntry(product: product, quantity: 1);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Product is out of stock.")),
        );
      }
    }
  }

  void _updateQuantity(int productId, int change) {
    if (!_cart.containsKey(productId)) return;
    final entry = _cart[productId]!;
    
    setState(() {
      final newQty = entry.quantity + change;
      if (newQty <= 0) {
        _cart.remove(productId);
      } else if (newQty > entry.product.stock) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cannot exceed available stock level!")),
        );
      } else {
        entry.quantity = newQty;
      }
    });
  }

  double get _cartTotal {
    return _cart.values.fold(0.0, (sum, entry) => sum + entry.total);
  }

  int get _cartItemCount {
    return _cart.values.fold(0, (sum, entry) => sum + entry.quantity);
  }

  Future<void> _checkoutBill() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Your cart is empty!")),
      );
      return;
    }

    final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    
    // Construct bill items
    final List<BillItem> billItems = _cart.values.map((entry) {
      return BillItem(
        productName: entry.product.name,
        price: entry.product.price,
        quantity: entry.quantity,
        total: entry.total,
      );
    }).toList();

    final bill = Bill(
      date: dateStr,
      total: _cartTotal,
      items: billItems,
    );

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Save to SQLite database (internally updates inventory stocks)
      final generatedId = await DBHelper.instance.saveBill(bill);
      final finalsavedBill = Bill(
        id: generatedId,
        date: bill.date,
        total: bill.total,
        items: bill.items,
      );

      // 2. Clear current cart
      setState(() {
        _cart.clear();
      });

      // 3. Trigger dynamic refresh of products (with updated stocks)
      await _refreshProducts();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bill Saved Successfully!")),
      );

      // 4. Trigger print of receipt PDF asynchronously
      _showPrintReceiptConfirmation(finalsavedBill);

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Checkout error: $e")),
      );
    }
  }

  void _showPrintReceiptConfirmation(Bill savedBill) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Save & Print Receipt"),
        content: Text("Bill of total ${widget.currencySymbol} ${savedBill.total.toStringAsFixed(2)} was saved successfully.\nWould you like to print the receipt now?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Maybe Later"),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              PDFService.printReceipt(savedBill, widget.shopName, widget.currencySymbol);
            },
            icon: const Icon(Icons.print),
            label: const Text("Print Receipt"),
          ),
        ],
      ),
    );
  }

  void _showCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final cartItems = _cart.values.toList();
            return Container(
              padding: EdgeInsets.only(
                top: 16,
                left: 16,
                right: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Shopping Cart (${_cartItemCount} items)",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: cartItems.isEmpty
                        ? const Center(child: Text("Cart is empty"))
                        : ListView.builder(
                            itemCount: cartItems.length,
                            itemBuilder: (context, idx) {
                              final entry = cartItems[idx];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(entry.product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                  "${widget.currencySymbol} ${entry.product.price.toStringAsFixed(2)} x ${entry.quantity}",
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, color: Colors.orange),
                                      onPressed: () {
                                        _updateQuantity(entry.product.id!, -1);
                                        setSheetState(() {});
                                        setState(() {});
                                      },
                                    ),
                                    Text(
                                      "${entry.quantity}",
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                      onPressed: () {
                                        _updateQuantity(entry.product.id!, 1);
                                        setSheetState(() {});
                                        setState(() {});
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Grand Total:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(
                          "${widget.currencySymbol} ${_cartTotal.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: cartItems.isEmpty
                          ? null
                          : () {
                              Navigator.pop(ctx);
                              _checkoutBill();
                            },
                      icon: const Icon(Icons.save_outlined),
                      label: const Text("Save & Generate Bill", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              );
            };
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _products
        .where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("SmartPOS Terminal", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(widget.shopName, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshProducts,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search box
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: "Search products by name...",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                  ),
                ),
                
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              const Text("No matches found in inventory."),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.15,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, idx) {
                            final p = filtered[idx];
                            return ProductCard(
                              product: p,
                              currencySymbol: widget.currencySymbol,
                              onTap: () => _addToCart(p),
                            );
                          },
                        ),
                ),
              ],
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 5,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: _showCartSheet,
              child: Row(
                children: [
                  Badge(
                    label: Text("$_cartItemCount"),
                    isLabelVisible: _cart.isNotEmpty,
                    child: Icon(Icons.shopping_cart, size: 32, color: Theme.of(context).primaryColor),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Estimated Total", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        "${widget.currencySymbol} ${_cartTotal.toStringAsFixed(2)}",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _cart.isEmpty ? null : _checkoutBill,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("CHECKOUT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(width: 8),
                  Icon(Icons.chevron_right),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
