import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/admin_service.dart';

class OfficeSettingsPage extends StatefulWidget {
  const OfficeSettingsPage({super.key});

  @override
  State<OfficeSettingsPage> createState() => _OfficeSettingsPageState();
}

class _OfficeSettingsPageState extends State<OfficeSettingsPage> {
  final AdminService _service = AdminService();
  
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  final TextEditingController _toleranceController = TextEditingController(text: "15");
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  // Parse string "08:00:00" ke TimeOfDay
  TimeOfDay _stringToTime(String timeString) {
    final parts = timeString.split(":");
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  // Format TimeOfDay ke String "08:00:00"
  String _timeToString(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute:00";
  }

  Future<void> _fetchSettings() async {
    final data = await _service.getOfficeSettings();
    if (data.isNotEmpty && mounted) {
      setState(() {
        _startTime = _stringToTime(data['office_start_time']);
        _endTime = _stringToTime(data['office_end_time']);
        _toleranceController.text = data['late_tolerance_minutes'].toString();
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    final success = await _service.updateOfficeSettings(
      _timeToString(_startTime),
      _timeToString(_endTime),
      int.parse(_toleranceController.text)
    );
    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Jam kerja berhasil disimpan!"), backgroundColor: AppColors.success)
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal menyimpan"), backgroundColor: AppColors.error)
      );
    }
  }

  Future<void> _selectTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) _startTime = picked; else _endTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        title: Text("Pengaturan Jam Kerja", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Aturan Jam Kantor", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 20),
              
              // JAM MASUK
              _buildTimeRow("Jam Masuk Kantor", _startTime, () => _selectTime(true)),
              const Divider(height: 30),
              
              // JAM PULANG
              _buildTimeRow("Jam Pulang Kantor", _endTime, () => _selectTime(false)),
              const Divider(height: 30),

              // TOLERANSI
              Text("Toleransi Keterlambatan (Menit)", style: GoogleFonts.poppins(color: Colors.grey[700])),
              const SizedBox(height: 10),
              TextField(
                controller: _toleranceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  suffixText: "Menit",
                  hintText: "Contoh: 15"
                ),
              ),
              
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text("SIMPAN PENGATURAN", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeRow(String label, TimeOfDay time, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.poppins(color: Colors.grey[700])),
            const SizedBox(height: 5),
            Text(
              time.format(context), 
              style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)
            ),
          ],
        ),
        IconButton(
          onPressed: onTap, 
          icon: const Icon(Icons.edit, color: Colors.blue),
          style: IconButton.styleFrom(backgroundColor: Colors.blue.withValues(alpha: 0.1)),
        )
      ],
    );
  }
}