import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import 'add_material_screen.dart';
import 'qr_material_scanner_screen.dart';
import 'weighbridge_ticket_screen.dart';

class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFF0B1326),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111C38),
        title: const Text('Stores Ledger', style: TextStyle(color: Color(0xFFF1F5F9))),
        actions: [
          IconButton(
            tooltip: 'Weighbridge & Gate Pass',
            icon: const Icon(Icons.scale_rounded, color: Color(0xFFFFB95F)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WeighbridgeTicketScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Scan QR / Tag',
            icon: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF38BDF8)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QrMaterialScannerScreen()),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF0284C7),
          labelColor: const Color(0xFF0284C7),
          unselectedLabelColor: const Color(0xFF94A3B8),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'GRN'),
            Tab(text: 'GIN'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Color(0xFFF1F5F9)),
              decoration: InputDecoration(
                hintText: 'Search material code or description...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFF162347),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF26396E)),
                ),
              ),
              onChanged: (val) {
                setState(() {});
              },
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildList('All', provider),
                _buildList('GRN', provider),
                _buildList('GIN', provider),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'weighbridge_fab',
            backgroundColor: const Color(0xFF1E2E5C),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const WeighbridgeTicketScreen()));
            },
            icon: const Icon(Icons.scale_rounded, color: Color(0xFFFFB95F), size: 18),
            label: const Text('Weighbridge', style: TextStyle(color: Color(0xFFF1F5F9), fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(width: 8),
          FloatingActionButton.extended(
            heroTag: 'qr_scanner_fab',
            backgroundColor: const Color(0xFF0284C7),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const QrMaterialScannerScreen()));
            },
            icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 20),
            label: const Text('Scan QR Tag', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          FloatingActionButton(
            heroTag: 'add_material_fab',
            backgroundColor: const Color(0xFF162347),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AddMaterialScreen()));
            },
            child: const Icon(Icons.add, color: Color(0xFF38BDF8)),
          ),
        ],
      ),
    );
  }

  Widget _buildList(String filter, AppProvider provider) {
    final query = _searchController.text.toLowerCase();
    final list = provider.materials.where((m) {
      if (filter != 'All' && m['docType'] != filter) return false;
      if (query.isNotEmpty) {
        final code = (m['code'] ?? '').toString().toLowerCase();
        final desc = (m['description'] ?? '').toString().toLowerCase();
        if (!code.contains(query) && !desc.contains(query)) return false;
      }
      return true;
    }).toList();

    if (list.isEmpty) {
      return const Center(child: Text('No materials found', style: TextStyle(color: Color(0xFF94A3B8))));
    }

    return ListView.builder(
      itemCount: list.length,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        final item = list[index];
        final isGrn = item['docType'] == 'GRN';
        return Card(
          color: const Color(0xFF162347),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item['code'] ?? 'DOC-00${index + 1}', style: const TextStyle(color: Color(0xFFF1F5F9), fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isGrn ? const Color(0xFF4EDEA3).withAlpha(51) : const Color(0xFFFFB95F).withAlpha(51),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(isGrn ? 'GRN' : 'GIN', style: TextStyle(color: isGrn ? const Color(0xFF4EDEA3) : const Color(0xFFFFB95F), fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Material: ${item['description'] ?? 'Unknown'}', style: const TextStyle(color: Color(0xFFF1F5F9))),
                Text('Quantity: ${item['quantity'] ?? 0} ${item['unit'] ?? ''}', style: const TextStyle(color: Color(0xFF94A3B8))),
                const SizedBox(height: 8),
                Text('Source: ${item['source'] ?? 'Unknown'}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                Text('Date: ${item['date'] ?? 'N/A'}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
              ],
            ),
          ),
        );
      },
    );
  }
}
