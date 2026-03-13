import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';

// Gunakan link EXPORT langsung agar tidak ada delay pencadangan 5 menit dari Google "Publish to web"
const String _googleSheetCsvUrl = 'https://docs.google.com/spreadsheets/d/1lSlxWgpzxYfdtT_fy4OmxgW1DkaA7u26eepdsbAiQck/export?format=csv';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _isLoading = true;
  List<Map<String, String>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotification();
  }

  Future<void> _fetchNotification() async {
    if (_googleSheetCsvUrl.isEmpty) {
      // Jika URL kosong, gunakan data dummy bawaan
      setState(() {
        _notifications = [
          {
            'title': 'Pesan dari Developer',
            'date': 'Just now',
            'message': 'Selamat Datang! Selamat menggunakan aplikasi pencatatan keuangan ini sebaik mungkin.\n\nDari Lil Alamin.',
          }
        ];
        _isLoading = false;
      });
      return;
    }

    try {
      // Tambahkan parameter penangkal cache (cache-buster) agar mendapat data paling segar
      final String cacheBusterUrl = '$_googleSheetCsvUrl&t=${DateTime.now().millisecondsSinceEpoch}';
      final response = await http.get(Uri.parse(cacheBusterUrl));
      if (response.statusCode == 200) {
        // Asumsi format CSV: Title, Date, Message
        // Split by newline to get rows
        List<String> rows = response.body.split('\n');
        
        List<Map<String, String>> fetchedNotifications = [];

        // Loop mulai dari baris 1 (lewati header baris 0)
        for (int i = 1; i < rows.length; i++) {
          if (rows[i].trim().isEmpty) continue;

          List<String> columns = rows[i].split(','); 
          if (columns.length >= 3) {
            String title = columns[0].trim();
            String date = columns[1].trim();
            
            // Gabungkan sisa kolom jika pesan mengandung koma, hilangkan tanda kutip
            String fullMessage = columns.sublist(2).join(',').trim();
            if (fullMessage.startsWith('"') && fullMessage.endsWith('"')) {
              fullMessage = fullMessage.substring(1, fullMessage.length - 1);
            }
            String message = fullMessage.replaceAll('\\n', '\n');

            fetchedNotifications.add({
              'title': title,
              'date': date,
              'message': message,
            });
          }
        }
        
        setState(() {
          // Balik urutan agar notifikasi terbaru (di baris terbawah sheet) muncul paling atas
          _notifications = fetchedNotifications.reversed.toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching notification from CSV: $e');
      // Akan *fallback* otomatis ke data dummy
      setState(() {
        _notifications = [
          {
            'title': 'Pesan dari Developer',
            'date': 'Just now',
            'message': 'Selamat Datang! Selamat menggunakan aplikasi pencatatan keuangan ini sebaik mungkin.\n\nDari Lil Alamin.',
          }
        ];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: AppColors.textMain,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textMain),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recent',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_notifications.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      'Belum ada notifikasi.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                )
              else
                ..._notifications.map((notif) => Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: AppColors.primaryBlueLight,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlueLight.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.message_rounded,
                                color: AppColors.primaryBlue,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          notif['title'] ?? '',
                                          style: const TextStyle(
                                            color: AppColors.textMain,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        notif['date'] ?? '',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  SelectableLinkify(
                                    onOpen: (link) async {
                                      final Uri uri = Uri.parse(link.url);
                                      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                                        debugPrint('Could not launch ${link.url}');
                                      }
                                    },
                                    text: notif['message'] ?? '',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                      height: 1.5,
                                    ),
                                    linkStyle: const TextStyle(
                                      color: AppColors.primaryBlue,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }
}
