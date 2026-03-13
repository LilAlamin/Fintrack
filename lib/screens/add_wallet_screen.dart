import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../database/db_helper.dart';
import '../utils/app_translations.dart';

class AddWalletScreen extends StatefulWidget {
  const AddWalletScreen({super.key});

  @override
  State<AddWalletScreen> createState() => _AddWalletScreenState();
}

class _AddWalletScreenState extends State<AddWalletScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  
  // Custom wallet icons to choose from
  final List<Map<String, dynamic>> _walletIcons = [
    {'icon': Icons.account_balance_wallet, 'color': 0xFF00AA5B}, // Green
    {'icon': Icons.account_balance, 'color': 0xFF00387A}, // Dark Blue
    {'icon': Icons.savings, 'color': 0xFFF78F1E}, // Orange
    {'icon': Icons.payment, 'color': 0xFF118EEA}, // Light Blue
    {'icon': Icons.credit_card, 'color': 0xFFBA68C8}, // Purple
    {'icon': Icons.monetization_on, 'color': 0xFFFFB74D}, // Yellow
  ];

  int _selectedIconIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveWallet() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppTranslations.translate(context, 'enter_wallet_name_error'))));
      return;
    }

    double? startingBalance = double.tryParse(_balanceController.text.trim());
    if (startingBalance == null) {
      startingBalance = 0.0; // Allow 0 starting balance
    }

    final selectedIconInfo = _walletIcons[_selectedIconIndex];
    
    Map<String, dynamic> walletData = {
      'name': name,
      'balance': startingBalance,
      'icon_code': (selectedIconInfo['icon'] as IconData).codePoint,
      'color': selectedIconInfo['color'],
    };

    await DatabaseHelper.instance.insertWallet(walletData);

    if (mounted) {
      Navigator.pop(context, true); // Return true to indicate change
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          AppTranslations.translate(context, 'add_wallet'),
          style: const TextStyle(
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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNameInput(),
                    const SizedBox(height: 32),
                    _buildBalanceInput(),
                    const SizedBox(height: 32),
                    _buildIconSelection(),
                  ],
                ),
              ),
            ),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildNameInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppTranslations.translate(context, 'wallet_name'),
          style: const TextStyle(
            color: AppColors.textMain,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider),
          ),
          child: TextField(
            controller: _nameController,
            focusNode: _nameFocusNode,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: AppTranslations.translate(context, 'wallet_name_hint'),
              hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.5)),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppTranslations.translate(context, 'starting_balance'),
          style: const TextStyle(
            color: AppColors.textMain,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider),
          ),
          child: TextField(
            controller: _balanceController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
            decoration: InputDecoration(
              prefixText: 'Rp ',
              prefixStyle: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 18),
              hintText: '0',
              hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.5)),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIconSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppTranslations.translate(context, 'cover_icon'),
          style: const TextStyle(
            color: AppColors.textMain,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: List.generate(_walletIcons.length, (index) {
            final iconData = _walletIcons[index]['icon'] as IconData;
            final colorValue = _walletIcons[index]['color'] as int;
            final isSelected = _selectedIconIndex == index;
            
            return GestureDetector(
              onTap: () => setState(() => _selectedIconIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? Color(colorValue).withOpacity(0.2) : AppColors.cardBackground,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Color(colorValue) : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Icon(
                  iconData,
                  color: isSelected ? Color(colorValue) : AppColors.textSecondary,
                  size: 28,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: AppColors.navyBackground.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: ElevatedButton(
        onPressed: _saveWallet,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 20),
            const SizedBox(width: 8),
            Text(
              AppTranslations.translate(context, 'add_wallet'),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
