import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/medicine.dart';
import '../providers/medicine_provider.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class MedicineScreen extends StatefulWidget {
  const MedicineScreen({super.key});

  @override
  State<MedicineScreen> createState() => _MedicineScreenState();
}

class _MedicineScreenState extends State<MedicineScreen> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    context.read<MedicineProvider>().fetchMedicines();
  }

  void _showForm({Medicine? medicine}) {
    final nameCtrl = TextEditingController(text: medicine?.name ?? '');
    final catCtrl = TextEditingController(text: medicine?.category ?? '');
    final stockCtrl = TextEditingController(
      text: medicine?.stock.toString() ?? '',
    );
    final priceCtrl = TextEditingController(
      text: medicine?.price.toString() ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              medicine == null ? 'Tambah Obat' : 'Edit Obat',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama Obat',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: catCtrl,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: stockCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Stok',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Harga',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7F1D1D),
                ),
                onPressed: () async {
                  final newMedicine = Medicine(
                    id: medicine?.id ?? 0,
                    name: nameCtrl.text,
                    category: catCtrl.text,
                    stock: int.tryParse(stockCtrl.text) ?? 0,
                    price: double.tryParse(priceCtrl.text) ?? 0,
                  );
                  final provider = context.read<MedicineProvider>();

                  try {
                    if (medicine == null) {
                      await provider.addMedicine(newMedicine);
                      _scaffoldKey.currentState?.showSnackBar(
                        const SnackBar(
                          content: Text('Obat berhasil ditambahkan!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      await provider.updateMedicine(medicine.id, newMedicine);
                      _scaffoldKey.currentState?.showSnackBar(
                        const SnackBar(
                          content: Text('Obat berhasil diupdate!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }

                    Navigator.pop(ctx);
                  } catch (e) {
                    _scaffoldKey.currentState?.showSnackBar(
                      SnackBar(
                        content: Text(
                          e.toString().replaceFirst('Exception: ', ''),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: Text(
                  medicine == null ? 'Tambah' : 'Simpan',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldKey,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF7F1D1D),
          title: const Text(
            'MInFarma',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () async {
                await ApiService().logout();
                if (!context.mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Cari nama atau kategori obat...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  context.read<MedicineProvider>().search(value);
                },
              ),
            ),
            Expanded(
              child: Consumer<MedicineProvider>(
                builder: (context, provider, child) {
                  if (provider.state == ViewState.loading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF7F1D1D),
                      ),
                    );
                  }

                  if (provider.state == ViewState.error) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 60,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 8),
                          Text(provider.errorMessage),
                          ElevatedButton(
                            onPressed: () => provider.fetchMedicines(),
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (provider.medicines.isEmpty) {
                    return const Center(child: Text('Tidak ada data obat.'));
                  }

                  return RefreshIndicator(
                    onRefresh: provider.fetchMedicines,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: provider.medicines.length,
                      itemBuilder: (_, index) {
                        final medicine = provider.medicines[index];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFF7F1D1D),
                              child: Icon(
                                Icons.medication,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              medicine.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${medicine.category} - Stok: ${medicine.stock}\n'
                              'Rp ${medicine.price.toStringAsFixed(0)}',
                            ),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.orange,
                                  ),
                                  onPressed: () {
                                    _showForm(medicine: medicine);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Konfirmasi Hapus'),
                                        content: const Text(
                                          'Apakah Anda yakin ingin menghapus obat ini?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: const Text('Batal'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            child: const Text('Hapus'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      try {
                                        await provider.deleteMedicine(
                                          medicine.id,
                                        );
                                        _scaffoldKey.currentState?.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Obat berhasil dihapus!',
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      } catch (e) {
                                        _scaffoldKey.currentState?.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              e.toString().replaceFirst(
                                                'Exception: ',
                                                '',
                                              ),
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFF7F1D1D),
          onPressed: _showForm,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}
