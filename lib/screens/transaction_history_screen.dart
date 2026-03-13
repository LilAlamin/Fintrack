import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../database/db_helper.dart';
import '../utils/app_translations.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  double _totalIncome = 0;
  double _totalExpense = 0;
  List<Map<String, dynamic>> _allTransactions = [];
  List<Map<String, dynamic>> _filteredTransactions = [];
  bool _isLoading = true;

  // Filter states
  String _searchQuery = '';
  String _selectedDateRange = 'All Time'; // 'All Time', 'Last 7 Days', 'Last 30 Days'
  String _selectedType = 'All Types'; // 'All Types', 'Income', 'Expense'
  String _selectedCategory = 'All Categories'; 

  List<Map<String, dynamic>> _availableCategories = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final trans = await DatabaseHelper.instance.getTransactions(); // get all
    final categoriesList = await DatabaseHelper.instance.database.then((db) => db.query('categories'));
    
    setState(() {
      _allTransactions = trans;
      _availableCategories = categoriesList;
      _isLoading = false;
    });
    _applyFilters();
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = _allTransactions.where((tx) {
      // 1. Search Query
      if (_searchQuery.isNotEmpty) {
        final title = tx['title'].toString().toLowerCase();
        final notes = (tx['notes'] ?? '').toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        if (!title.contains(query) && !notes.contains(query)) {
          return false;
        }
      }
      
      // 2. Type Filter
      if (_selectedType != 'All Types') {
        if (_selectedType.toUpperCase() != tx['type']) {
          return false;
        }
      }

      // 3. Category Filter
      if (_selectedCategory != 'All Categories') {
         if (tx['category_name'] != _selectedCategory) {
           return false;
         }
      }

      // 4. Date Filter
      if (_selectedDateRange != 'All Time') {
        try {
          final txDate = DateFormat('MMM dd, yyyy').parse(tx['date']);
          final now = DateTime.now();
          final difference = now.difference(txDate).inDays;
          
          if (_selectedDateRange == 'Last 7 Days' && difference > 7) return false;
          if (_selectedDateRange == 'Last 30 Days' && difference > 30) return false;
        } catch (e) {
          // ignore parsing errors
        }
      }

      return true;
    }).toList();

    double income = 0;
    double expense = 0;
    for (var tx in filtered) {
      if (tx['type'] == 'INCOME') {
        income += (tx['amount'] as num).toDouble();
      } else {
        expense += (tx['amount'] as num).toDouble();
      }
    }

    setState(() {
      _filteredTransactions = filtered;
      _totalIncome = income;
      _totalExpense = expense;
    });
  }

  String _formatCurrency(double amount) {
    var format = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return format.format(amount);
  }

  // Groups transactions by date to display nicely grouped sections
  Map<String, List<Map<String, dynamic>>> _groupTransactionsByDate() {
    Map<String, List<Map<String, dynamic>>> groups = {};
    for (var tx in _filteredTransactions) {
      String date = tx['date']; // "MMM dd, yyyy" format from save
      if (!groups.containsKey(date)) {
        groups[date] = [];
      }
      groups[date]!.add(tx);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.primaryBlueLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: AppColors.primaryBlue),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          AppTranslations.translate(context, 'transaction_history'),
          style: const TextStyle(
            color: AppColors.textMain,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.divider),
              ),
              child: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.divider),
              ),
              child: const Icon(Icons.more_vert, color: AppColors.textSecondary, size: 20),
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
        : RefreshIndicator(
            onRefresh: _loadData,
            color: AppColors.primaryBlue,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: 16),
                  _buildFilterChips(),
                  const SizedBox(height: 24),
                  _buildSummaryCards(),
                  const SizedBox(height: 24),
                  if (_filteredTransactions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          AppTranslations.translate(context, 'no_transactions_found'),
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    ..._buildGroupedTransactions(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
      ),
    );
  }

  List<Widget> _buildGroupedTransactions() {
    final grouped = _groupTransactionsByDate();
    List<Widget> sections = [];
    
    grouped.forEach((date, trans) {
      sections.add(
        _buildDateSection(
          date: date.toUpperCase(),
          count: '${trans.length} ${AppTranslations.translate(context, 'transactions')}',
          transactions: trans.map((tx) {
            bool isExpense = tx['type'] == 'EXPENSE';
            return _buildTransactionItem(
              title: tx['title'],
              category: '${tx['category_name']} • ${tx['wallet_name']}',
              amount: '${isExpense ? '-' : '+'}${_formatCurrency(tx['amount'])}',
              isExpense: isExpense,
              notes: tx['notes'] as String?,
              icon: IconData(tx['category_icon'], fontFamily: 'MaterialIcons'),
              iconColor: Color(tx['category_color']),
              iconBgColor: Color(tx['category_color']).withOpacity(0.1),
            );
          }).toList(),
        ),
      );
      sections.add(const SizedBox(height: 24));
    });
    
    return sections;
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        onChanged: (value) {
          _searchQuery = value;
          _applyFilters();
        },
        decoration: InputDecoration(
          icon: const Icon(Icons.search, color: AppColors.textSecondary),
          hintText: AppTranslations.translate(context, 'search_transactions'),
          hintStyle: const TextStyle(color: AppColors.textSecondary),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: _showDateRangePicker,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _selectedDateRange == 'All Time' ? AppColors.cardBackground : AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _selectedDateRange == 'All Time' ? AppColors.divider : Colors.transparent),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, color: _selectedDateRange == 'All Time' ? AppColors.textSecondary : Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    AppTranslations.translate(context, _selectedDateRange.toLowerCase().replaceAll(' ', '_')),
                    style: TextStyle(color: _selectedDateRange == 'All Time' ? AppColors.textSecondary : Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: GestureDetector(
            onTap: _showTypePicker,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _selectedType == 'All Types' ? AppColors.cardBackground : AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _selectedType == 'All Types' ? AppColors.divider : Colors.transparent),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.filter_list, color: _selectedType == 'All Types' ? AppColors.textSecondary : Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    AppTranslations.translate(context, _selectedType.toLowerCase().replaceAll(' ', '_')).replaceAll(' ', '\n'), // All\nTypes
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _selectedType == 'All Types' ? AppColors.textSecondary : Colors.white, fontSize: 10, height: 1.2),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: GestureDetector(
            onTap: _showCategoryPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _selectedCategory == 'All Categories' ? AppColors.cardBackground : AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _selectedCategory == 'All Categories' ? AppColors.divider : Colors.transparent),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.category, color: _selectedCategory == 'All Categories' ? AppColors.textSecondary : Colors.white, size: 16),
                  const SizedBox(height: 4),
                  Text(
                    _selectedCategory == 'All Categories' ? AppTranslations.translate(context, 'category') : _selectedCategory,
                    style: TextStyle(color: _selectedCategory == 'All Categories' ? AppColors.textSecondary : Colors.white, fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showDateRangePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['All Time', 'Last 7 Days', 'Last 30 Days'].map((range) {
              return ListTile(
                title: Text(range),
                trailing: _selectedDateRange == range ? const Icon(Icons.check, color: AppColors.primaryBlue) : null,
                onTap: () {
                  setState(() => _selectedDateRange = range);
                  _applyFilters();
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      }
    );
  }

  void _showTypePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['All Types', 'Income', 'Expense'].map((type) {
              return ListTile(
                title: Text(type),
                trailing: _selectedType == type ? const Icon(Icons.check, color: AppColors.primaryBlue) : null,
                onTap: () {
                  setState(() => _selectedType = type);
                  _applyFilters();
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      }
    );
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(AppTranslations.translate(context, 'all_categories')),
                  trailing: _selectedCategory == 'All Categories' ? const Icon(Icons.check, color: AppColors.primaryBlue) : null,
                  onTap: () {
                    setState(() => _selectedCategory = 'All Categories');
                    _applyFilters();
                    Navigator.pop(context);
                  },
                ),
                const Divider(),
                ..._availableCategories.map((cat) {
                  return ListTile(
                    leading: Icon(IconData(cat['icon_code'], fontFamily: 'MaterialIcons'), color: Color(cat['color'])),
                    title: Text(cat['name']),
                    trailing: _selectedCategory == cat['name'] ? const Icon(Icons.check, color: AppColors.primaryBlue) : null,
                    onTap: () {
                      setState(() => _selectedCategory = cat['name']);
                      _applyFilters();
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.successGreen.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppTranslations.translate(context, 'total_income_small'),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '+${_formatCurrency(_totalIncome)}',
                    style: const TextStyle(
                      color: AppColors.successGreen,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.dangerRed.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppTranslations.translate(context, 'total_expense_small'),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '-${_formatCurrency(_totalExpense)}',
                    style: const TextStyle(
                      color: AppColors.dangerRed,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSection({
    required String date,
    required String count,
    required List<Widget> transactions,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              date,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            Text(
              count,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...transactions.map((w) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: w,
            )),
      ],
    );
  }

  Widget _buildTransactionItem({
    required String title,
    required String category,
    required String amount,
    required bool isExpense,
    String? notes,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
  }) {
    final statusColor = isExpense ? AppColors.dangerRed : AppColors.successGreen;
    final statusBgColor = isExpense ? AppColors.dangerRedLight : AppColors.successGreenLight;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textMain,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                if (notes != null && notes.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    notes,
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.8),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isExpense ? AppTranslations.translate(context, 'expense') : AppTranslations.translate(context, 'income'),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
