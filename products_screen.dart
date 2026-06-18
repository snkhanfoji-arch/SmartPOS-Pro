import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/product.dart';

class ProductsScreen extends StatefulWidget {
  final String currencySymbol;
  const ProductsScreen({super.key, required this.currencySymbol});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Product> _products = [];
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
        SnackBar(content: Text("Error fetching products: $e")),
      );
    }
  }

  List<Product> get _filteredProducts {
    if (_searchQuery.isEmpty) return _products;
    return _products
        .where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _showProductDialog({Product? product}) {
    final nameController = TextEditingController(text: product?.name ?? '');
    final priceController = TextEditingController(text: product?.price.toString() ?? '');
    final stockController = TextEditingController(text: product?.stock.toString() ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(product == null ? "Add New Product" : "Edit Product"),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Product Name",
                      hintText: "e.g. Soda Can, Milk Carton",
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? "Enter valid name" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: "Price (${widget.currencySymbol})",
                      hintText: "0.00",
                    ),
                    validator: (v) {
                      if (v == null || double.tryParse(v) == null) {
                        return "Enter a valid number";
                      }
                      if (double.parse(v) < 0) return "Price cannot be negative";
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: stockController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Current Stock",
                      hintText: "e.g. 50, 100",
                    ),
                    validator: (v) {
                      if (v == null || int.tryParse(v) == null) {
                        return "Enter valid integer";
                      }
                      if (int.parse(v) < 0) return "Stock cannot be negative";
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            if (product != null)
              TextButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Delete Product?"),
                      content: Text("Are you sure you want to delete '${product.name}'?"),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("No")),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text("Delete", style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await DBHelper.instance.deleteProduct(product.id!);
                    if (mounted) {
                      Navigator.pop(context);
                      _refreshProducts();
                    }
                  }
                },
                child: const Text("Delete", style: TextStyle(color: Colors.red)),
              ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final tempProduct = Product(
                    id: product?.id,
                    name: nameController.text.trim(),
                    price: double.parse(priceController.text),
                    stock: int.parse(stockController.text),
                  );

                  if (product == null) {
                    await DBHelper.instance.insertProduct(tempProduct);
                  } else {
                    await DBHelper.instance.updateProduct(tempProduct);
                  }

                  if (mounted) {
                    Navigator.pop(context);
                    _refreshProducts();
                  }
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Products Inventory"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshProducts,
          )
        ],
      ),
      body: Column(
        children: [
          // Search box
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Search product by name...",
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              "No products found",
                              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(12.0),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.15,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, idx) {
                          final p = _filteredProducts[idx];
                          return InkWell(
                            onTap: () => _showProductDialog(product: p),
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      p.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "${widget.currencySymbol} ${p.price.toStringAsFixed(2)}",
                                          style: const TextStyle(
                                            color: Colors.indigo,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.warehouse,
                                              size: 14,
                                              color: p.stock > 10 ? Colors.green : Colors.deepOrange,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              "Qty: ${p.stock}",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: p.stock > 10 ? Colors.green : Colors.deepOrange,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductDialog(),
        icon: const Icon(Icons.add),
        label: const Text("New Product"),
      ),
    );
  }
}
