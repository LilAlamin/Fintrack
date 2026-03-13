import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'dashboard_screen.dart';
import 'wallet_screen.dart'; // import the new screen
import 'add_transaction_screen.dart';
import 'stats_screen.dart';
import 'profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/feature_discovery.dart';
import '../utils/app_translations.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final GlobalKey _fabKey = GlobalKey();
  final GlobalKey _walletKey = GlobalKey();
  final GlobalKey _statsKey = GlobalKey();
  final GlobalKey _addWalletButtonKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const DashboardScreen(),
      WalletScreen(addWalletKey: _addWalletButtonKey),
      const StatsScreen(),
      const ProfileScreen(),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // _resetTutorialForTesting(); // Uncomment only if you want to force-reset for debugging
      _checkTutorial();
    });
  }

  Future<void> _checkTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isFirstRun = prefs.getBool('is_first_run') ?? true;
    final bool tutorialCompleted = prefs.getBool('interactive_tutorial_completed') ?? false;
    final bool tutorialDisabled = prefs.getBool('interactive_tutorial_disabled_forever') ?? false;

    // Only show if onboarding is done but interactive tutorial is not and not disabled
    if (!isFirstRun && !tutorialCompleted && !tutorialDisabled) {
      _startTutorialSequence();
    }
  }

  Future<void> _dismissTutorialForever() async {
    _overlayEntry?.remove();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('interactive_tutorial_disabled_forever', true);
  }

  void _startTutorialSequence() {
    _showSpotlight(
      key: _fabKey,
      title: 'Catat Transaksi',
      description: 'Ketuk di sini untuk mulai mencatat pengeluaran atau pemasukan pertama Anda!',
      onDismiss: _dismissTutorialForever,
      onNext: () {
        _overlayEntry?.remove();
        _showSpotlight(
          key: _walletKey,
          title: 'Dompet Digital',
          description: 'Kelola berbagai dompet dan saldo Anda di sini agar tetap terpantau.',
          onDismiss: _dismissTutorialForever,
          onNext: () {
            _overlayEntry?.remove();
            // Switch to Wallet Page
            _onItemTapped(1);
            // Wait for frame to render the new page
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showSpotlight(
                key: _addWalletButtonKey,
                title: 'Kenapa Banyak Wallet?',
                description: 'Anda bisa memisahkan uang ke banyak dompet (Mandiri, Dana, Cash). \n\n'
                    'Gunakan ini untuk memisahkan dana: \n'
                    '• Kebutuhan (Makan, Listrik) \n'
                    '• Keinginan (Hobi, Jajan) \n'
                    '• Tabungan / Dana Darurat',
                onDismiss: _dismissTutorialForever,
                onNext: () {
                  _overlayEntry?.remove();
                  _showSpotlight(
                    key: _statsKey,
                    title: 'Statistik Keuangan',
                    description: 'Lihat progres keuangan Anda dalam grafik yang cantik dan mudah dipahami.',
                    onDismiss: _dismissTutorialForever,
                    onNext: () async {
                      _overlayEntry?.remove();
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('interactive_tutorial_completed', true);
                    },
                    isLast: true,
                  );
                },
              );
            });
          },
        );
      },
    );
  }

  void _showSpotlight({
    required GlobalKey key,
    required String title,
    required String description,
    required VoidCallback onNext,
    VoidCallback? onDismiss,
    bool isLast = false,
  }) {
    _overlayEntry = OverlayEntry(
      builder: (context) => FeatureDiscovery(
        targetKey: key,
        title: title,
        description: description,
        onNext: onNext,
        onDismiss: onDismiss,
        isLast: isLast,
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      floatingActionButton: FloatingActionButton(
        key: _fabKey,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTransactionScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primaryBlue,
        shape: const CircleBorder(),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(icon: Icons.grid_view_rounded, label: AppTranslations.translate(context, 'home'), index: 0),
                _buildNavItem(icon: Icons.account_balance_wallet_rounded, label: AppTranslations.translate(context, 'wallet'), index: 1, key: _walletKey),
                const SizedBox(width: 40), // Space for FAB
                _buildNavItem(icon: Icons.analytics_outlined, label: AppTranslations.translate(context, 'stats'), index: 2, key: _statsKey),
                _buildNavItem(icon: Icons.person_rounded, label: AppTranslations.translate(context, 'profile'), index: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required int index, GlobalKey? key}) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? AppColors.primaryBlue : AppColors.textSecondary.withValues(alpha: 0.4);

    return Expanded(
      child: InkWell(
        key: key,
        onTap: () => _onItemTapped(index),
        splashColor: AppColors.primaryBlue.withValues(alpha: 0.05),
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: color,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
