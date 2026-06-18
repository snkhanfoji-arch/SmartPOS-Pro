import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final String currencySymbol;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const ProductCard({
    super.key,
    required this.product,
    required this.currencySymbol,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    // Determine color badges depending on stock level
    Color stockColor = Colors.green.shade600;
    String stockLabel = "In Stock (${product.stock})";
    
    if (product.stock == 0) {
      stockColor = Colors.red.shade600;
      stockLabel = "Out of Stock";
    } else if (product.stock < 10) {
      stockColor = Colors.amber.shade700;
      stockLabel = "Low Stock (${product.stock})";
    }

    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: product.stock > 0 ? onTap : null,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: product.stock == 0 ? Colors.grey.shade100 : Colors.white,
          ),
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Product Name with auto scaling wrapped in column
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: product.stock == 0 ? Colors.grey : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Price Tag
                  Text(
                    "$currencySymbol ${product.price.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: product.stock == 0 ? Colors.grey : Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),

              // Stock Status Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: stockColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      stockLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: stockColor,
                      ),
                    ),
                  ),
                  
                  // Plus shortcut button to indicate tap adding
                  if (product.stock > 0)
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      child: Icon(
                        Icons.add,
                        size: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
