import 'package:flutter/material.dart';
import 'package:snapan_market/core/components/app_dropdown_field.dart';
import 'package:snapan_market/core/theme/app_colors.dart';
import 'package:snapan_market/features/ui_kit/components/m3_component_spec_card.dart';

/// Interactive showcase of form inputs, textfields, and dropdowns
class UiKitInputsSection extends StatefulWidget {
  const UiKitInputsSection({super.key});

  @override
  State<UiKitInputsSection> createState() => _UiKitInputsSectionState();
}

class _UiKitInputsSectionState extends State<UiKitInputsSection> {
  final TextEditingController _textCtrl = TextEditingController(text: 'Contoh teks input');
  final TextEditingController _searchCtrl = TextEditingController();
  String? _selectedCategory = 'PPLG (Pengembangan Perangkat Lunak)';
  bool _switchVal = true;
  bool _checkboxVal = true;

  @override
  void dispose() {
    _textCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B);
    final inputBg = isDark ? AppColors.darkSurfaceElevated : const Color(0xFFF8FAFC);
    final borderColor = isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      children: [
        // Standard Text Input
        M3ComponentSpecCard(
          title: 'Text Field & Search Bar',
          description:
              'Input teks bergaya Threads dengan background soft slate, subtle border, dan floating/placeholder hint.',
          preview: Column(
            children: [
              TextField(
                controller: _textCtrl,
                decoration: InputDecoration(
                  labelText: 'Nama Lengkap / Username',
                  filled: true,
                  fillColor: inputBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.0),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.0),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.0),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 14.0),
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Cari barang, tugas, atau thread...',
                  prefixIcon: const Icon(Icons.search, size: 20.0),
                  filled: true,
                  fillColor: inputBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(100.0),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(100.0),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(100.0),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          specDetails: Text(
            'Border radius 14dp untuk form field, 100dp untuk search bar capsule. Input background: #F8FAFC (Light) / #1D1F1F (Dark).',
            style: TextStyle(fontSize: 11.5, height: 1.45, color: textMuted),
          ),
        ),

        // AppDropdownField Custom Overlay
        M3ComponentSpecCard(
          title: 'AppDropdownField (Non-M3 Tonal Tint)',
          description:
              'Dropdown field kustom Snaps yang meniadakan beige/tonal tint bawaan M3, menjaga estetika minimalis OLED/White.',
          sourcePath: 'lib/core/components/app_dropdown_field.dart',
          preview: AppDropdownField(
            label: 'Jurusan / Konsentrasi Keahlian',
            value: _selectedCategory,
            options: const [
              'PPLG (Pengembangan Perangkat Lunak)',
              'DKV (Desain Komunikasi Visual)',
              'Kuliner / Tata Boga',
              'TKJ / Jaringan Komputer',
            ],
            onChanged: (val) {
              setState(() => _selectedCategory = val);
            },
          ),
          specDetails: Text(
            'Menampilkan menu popup melayang di posisi akurat tombol dengan rounded corner 16dp dan shadow halus.',
            style: TextStyle(fontSize: 11.5, height: 1.45, color: textMuted),
          ),
        ),

        // Toggles & Checkbox Selection
        M3ComponentSpecCard(
          title: 'Switch & Checkbox Controls',
          description:
              'Selektor biner untuk privasi akun, notifikasi, dan konfirmasi syarat COD.',
          preview: Column(
            children: [
              SwitchListTile.adaptive(
                title: const Text(
                  'Aktifkan Notifikasi Push',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
                ),
                activeColor: AppColors.primary,
                value: _switchVal,
                onChanged: (v) => setState(() => _switchVal = v),
              ),
              CheckboxListTile(
                title: const Text(
                  'Saya setuju bertemu di Spot COD sekolah',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
                ),
                activeColor: AppColors.primary,
                value: _checkboxVal,
                onChanged: (v) => setState(() => _checkboxVal = v ?? false),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
