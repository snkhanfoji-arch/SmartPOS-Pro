import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/bill.dart';

class PDFService {
  static Future<void> printReceipt(
    Bill bill,
    String shopName,
    String currencySymbol,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // Thermal printer 80mm format
        margin: const pw.EdgeInsets.all(10),
        build: (pw.Context context) {
          return pw.Column(
            crossType: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Align(
                alignment: pw.Alignment.center,
                child: pw.Text(
                  shopName.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Align(
                alignment: pw.Alignment.center,
                child: pw.Text(
                  "*** RETAIL INVOICE ***",
                  style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
                ),
              ),
              pw.SizedBox(height: 8),

              // Meta details
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
              pw.Text("Bill ID: #${bill.id ?? 'Pending'}", style: const pw.TextStyle(fontSize: 9)),
              pw.Text("Date: ${bill.date}", style: const pw.TextStyle(fontSize: 9)),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 4),

              // Table header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text("Item Detail", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text("Price", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text("Qty", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text("Total", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),

              // Items List
              ...bill.items.map((item) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(item.productName, style: const pw.TextStyle(fontSize: 8)),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text(item.price.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.right),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text("x${item.quantity}", style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.right),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text(item.total.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.right),
                      ),
                    ],
                  ),
                );
              }),

              pw.SizedBox(height: 4),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 4),

              // Summary
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Total Items:", style: const pw.TextStyle(fontSize: 9)),
                  pw.Text("${bill.items.fold<int>(0, (sum, e) => sum + e.quantity)}", style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("GRAND TOTAL:", style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  pw.Text("$currencySymbol ${bill.total.toStringAsFixed(2)}", style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                ],
              ),

              pw.SizedBox(height: 8),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 8),

              // Footer
              pw.Align(
                alignment: pw.Alignment.center,
                child: pw.Text(
                  "Thank you for shopping with us!",
                  style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic),
                ),
              ),
              pw.Align(
                alignment: pw.Alignment.center,
                child: pw.Text(
                  "Powered by SmartPOS Pro",
                  style: pw.TextStyle(fontSize: 6, color: PdfColors.grey),
                ),
              ),
            ],
          );
        },
      ),
    );

    // This triggers the preview and printing/sharing sheet in Android natively
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'SmartPOS_Receipt_${bill.id ?? DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }
}
