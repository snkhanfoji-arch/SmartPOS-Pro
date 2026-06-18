import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'database/db_helper.dart';
import 'screens/billing_screen.dart';
import 'screens/products_screen.dart';
import 'screens/history_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Safe DB initialization test run
  await DBHelper.instance.database;
  runApp(const SmartPOSApp());
}

class SmartPOSApp extends StatelessWidget {
  const SmartPOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartPOS Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.indigo,
        primaryColor: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF6F8FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          primary: Colors.indigo,
        ),
      ),
      home: const MainTabShell(),
    );
  }
}

class MainTabShell extends StatefulWidget {
  const MainTabShell({super.key});

  @override
  State<MainTabShell> createState() => _MainTabShellState();
}

class _MainTabShellState extends State<MainTabShell> {
  int _currentTabIndex = 0;
  
  // Custom Settings State
  String _shopName = "SmartPOS Pro";
  String _currencySymbol = "₨";

  final _shopNameController = TextEditingController();
  final _currencyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _shopNameController.text = _shopName;
    _currencyController.text = _currencySymbol;
  }

  void _triggerSqliteBackup() async {
    try {
      final path = await DBHelper.instance.exportDatabaseBackup();
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Backup Successful"),
            content: Text("DB backup exported successfully as:\n$path\n\nYou can copy this .db file to safe storage."),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK")),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Backup failed: $e")),
        );
      }
    }
  }

  void _showSettingsDrawer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Store Settings & Utilities",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 10),
                TextField(
                  controller: _shopNameController,
                  decoration: const InputDecoration(
                    labelText: "Store / Shop Name",
                    prefixIcon: Icon(Icons.store),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _currencyController,
                  decoration: const InputDecoration(
                    labelText: "Currency Symbol",
                    prefixIcon: Icon(Icons.currency_exchange),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Colors.blueGrey,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _triggerSqliteBackup,
                        icon: const Icon(Icons.backup),
                        label: const Text("Offline JSON / .db Backup"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _shopName = _shopNameController.text.trim().isNotEmpty
                            ? _shopNameController.text.trim()
                            : "SmartPOS Pro";
                        _currencySymbol = _currencyController.text.trim().isNotEmpty
                            ? _currencyController.text.trim()
                            : "₨";
                      });
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Settings saved successfully!")),
                      );
                    },
                    child: const Text("Save Configuration", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Render selected index screen with relevant parameters
    final List<Widget> screens = [
      BillingScreen(shopName: _shopName, currencySymbol: _currencySymbol),
      ProductsScreen(currencySymbol: _currencySymbol),
      HistoryScreen(shopName: _shopName, currencySymbol: _currencySymbol),
    ];

    return Scaffold(
      body: SafeArea(
        child: screens[_currentTabIndex],
      ),
      floatingActionButton: _currentTabIndex != 1 // Show settings fab only when not covering add product fab
          ? FloatingActionButton.small(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.white,
              onPressed: _showSettingsDrawer,
              child: const Icon(Icons.settings),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentTabIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate_outlined),
            activeIcon: Icon(Icons.calculate),
            label: "Billing",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: "Inventory",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: "History",
          ),
        ],
      ),
    );
  }
}
