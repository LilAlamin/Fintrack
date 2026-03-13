import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../database/db_helper.dart';
import 'add_category_screen.dart';
import '../utils/app_translations.dart';

class AddTransactionScreen extends StatefulWidget {
  final bool initialIsExpense;

  const AddTransactionScreen({super.key, this.initialIsExpense = true});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  late bool isExpense;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();

  int _selectedCategoryIndex = 0;
  int _selectedPaymentIndex = 0;

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _wallets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    isExpense = widget.initialIsExpense;
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _amountFocusNode.requestFocus();
    });
  }
  
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final wallets = await DatabaseHelper.instance.getWallets();
    final categories = await DatabaseHelper.instance.getCategories(isExpense ? 'EXPENSE' : 'INCOME');
    
    setState(() {
      _wallets = wallets;
      _categories = categories;
      _selectedCategoryIndex = 0;
      if (_wallets.isNotEmpty && _selectedPaymentIndex >= wallets.length) {
        _selectedPaymentIndex = 0;
      }
      _isLoading = false;
    });
  }

  void _toggleType(bool expense) {
    if (isExpense == expense) return;
    setState(() {
      isExpense = expense;
    });
    _loadData();
  }

  Future<void> _saveTransaction() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppTranslations.translate(context, 'enter_amount_error'))));
      return;
    }
    
    double? amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppTranslations.translate(context, 'invalid_amount_error'))));
      return;
    }

    if (_categories.isEmpty || _wallets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppTranslations.translate(context, 'missing_category_wallet_error'))));
      return;
    }

    final categoryId = _categories[_selectedCategoryIndex]['id'];
    final walletId = _wallets[_selectedPaymentIndex]['id'];
    final type = isExpense ? 'EXPENSE' : 'INCOME';
    // Format date specifically for display later: e.g. "Oct 24" or use full date for sorting
    final date = DateFormat('MMM dd, yyyy').format(DateTime.now());

    Map<String, dynamic> row = {
      'title': _categories[_selectedCategoryIndex]['name'],
      'amount': amount,
      'type': type,
      'date': date,
      'wallet_id': walletId,
      'category_id': categoryId,
      'notes': _notesController.text,
    };

    await DatabaseHelper.instance.insertTransaction(row);

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    var format = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return format.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          AppTranslations.translate(context, 'add_transaction'),
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
        child: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
        : _wallets.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppTranslations.translate(context, 'no_actionable_wallets'),
                      style: const TextStyle(color: AppColors.textMain, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppTranslations.translate(context, 'add_wallet_first'),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
                      onPressed: () => Navigator.pop(context),
                      child: Text(AppTranslations.translate(context, 'go_back'), style: const TextStyle(color: Colors.white)),
                    )
                  ],
                ),
              )
            : Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTypeToggle(),
                    const SizedBox(height: 40),
                    _buildAmountInput(),
                    const SizedBox(height: 48),
                    _buildCategorySelection(),
                    const SizedBox(height: 32),
                    _buildPaymentMethodSelection(),
                    const SizedBox(height: 32),
                    _buildNotesInput(),
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

  Widget _buildTypeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _toggleType(true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isExpense ? AppColors.primaryBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                alignment: Alignment.center,
                child: Text(
                  AppTranslations.translate(context, 'expense_tab'),
                  style: TextStyle(
                    color: isExpense ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _toggleType(false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: !isExpense ? AppColors.primaryBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                alignment: Alignment.center,
                child: Text(
                  AppTranslations.translate(context, 'income_tab'),
                  style: TextStyle(
                    color: !isExpense ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInput() {
    return Center(
      child: Column(
        children: [
          Text(
            AppTranslations.translate(context, 'total_amount_small'),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 200,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlueLight.withOpacity(0.5),
                      blurRadius: 40,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Text(
                    'Rp ',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  IntrinsicWidth(
                    child: TextField(
                      controller: _amountController,
                      focusNode: _amountFocusNode,
                      keyboardType: TextInputType.number,
                      cursorColor: AppColors.primaryBlue,
                      style: const TextStyle(
                        color: AppColors.textMain,
                        fontSize: 64,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -2,
                      ),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: TextStyle(
                          color: AppColors.textSecondary.withOpacity(0.3),
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppTranslations.translate(context, 'category'),
              style: const TextStyle(
                color: AppColors.textMain,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              AppTranslations.translate(context, 'view_all_small'),
              style: const TextStyle(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              ...List.generate(_categories.length, (index) {
                final category = _categories[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedCategoryIndex = index),
                    child: _buildCategoryItem(
                      IconData(category['icon_code'], fontFamily: 'MaterialIcons'),
                      category['name'] as String,
                      _selectedCategoryIndex == index,
                      Color(category['color'] ?? 0xFF000000),
                    ),
                  ),
                );
              }),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddCategoryScreen(transactionType: isExpense ? 'EXPENSE' : 'INCOME'),
                    ),
                  ).then((value) {
                    if (value == true) {
                      _loadData(); // reload available categories
                    }
                  });
                },
                child: _buildAddCategoryItem(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(IconData icon, String label, bool isSelected, Color baseColor) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: isSelected ? Border.all(color: AppColors.primaryBlueLight, width: 2) : Border.all(color: Colors.transparent, width: 2),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primaryBlueLight.withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            color: isSelected ? baseColor : AppColors.textSecondary,
            size: 28,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            color: isSelected ? baseColor : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAddCategoryItem() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryBlueLight.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primaryBlue.withOpacity(0.5),
              width: 1,
              style: BorderStyle.solid,
            ),
          ),
          child: const Icon(
            Icons.add,
            color: AppColors.primaryBlue,
            size: 28,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          AppTranslations.translate(context, 'add_label'),
          style: const TextStyle(
            color: AppColors.primaryBlue,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppTranslations.translate(context, 'payment_method'),
          style: const TextStyle(
            color: AppColors.textMain,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: List.generate(_wallets.length, (index) {
              final wallet = _wallets[index];
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedPaymentIndex = index),
                  child: _buildPaymentItem(
                    IconData(wallet['icon_code'], fontFamily: 'MaterialIcons'),
                    wallet['name'] as String,
                    _formatCurrency(wallet['balance'] as double),
                    Color(wallet['color']),
                    _selectedPaymentIndex == index,
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentItem(
    IconData icon,
    String title,
    String balance,
    Color iconColor,
    bool isSelected,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryBlueLight.withOpacity(0.5) : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppColors.primaryBlue.withOpacity(0.3) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? AppColors.primaryBlue : AppColors.textMain,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                balance,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppTranslations.translate(context, 'notes_label'),
          style: const TextStyle(
            color: AppColors.textMain,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: AppTranslations.translate(context, 'add_note_hint'),
              hintStyle: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
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
        onPressed: _saveTransaction,
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
              AppTranslations.translate(context, 'save_transaction'),
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
