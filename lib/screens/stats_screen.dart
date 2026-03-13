import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../database/db_helper.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  
  bool _isLoading = true;
  String _selectedTab = 'EXPENSE'; // 'EXPENSE' or 'INCOME'

  List<Map<String, dynamic>> _groupedData = [];
  double _totalAmount = 0.0;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final data = await DatabaseHelper.instance.getGroupedTransactions(_selectedTab);
    
    double total = 0;
    for (var row in data) {
      total += (row['total_amount'] as num).toDouble();
    }

    setState(() {
      _groupedData = data;
      _totalAmount = total;
      _isLoading = false;
      _touchedIndex = -1; // Reset selection on reload
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Statistics',
          style: TextStyle(color: AppColors.textMain, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
            : RefreshIndicator(
                onRefresh: _loadData,
                color: AppColors.primaryBlue,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTabSelector(),
                      const SizedBox(height: 32),
                      if (_groupedData.isEmpty)
                        _buildEmptyState()
                      else ...[
                        _buildChartSection(),
                        const SizedBox(height: 32),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: const Text('Top Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                        ),
                        const SizedBox(height: 16),
                        _buildLegendList(),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildTabSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(child: _buildTabButton('EXPENSE', 'Expense')),
            Expanded(child: _buildTabButton('INCOME', 'Income')),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String type, String label) {
    bool isSelected = _selectedTab == type;
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          setState(() => _selectedTab = type);
          _loadData();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? (type == 'INCOME' ? AppColors.successGreen : AppColors.dangerRed) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected ? [BoxShadow(color: (type == 'INCOME' ? AppColors.successGreen : AppColors.dangerRed).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Column(
          children: [
            Icon(Icons.pie_chart_outline, size: 80, color: AppColors.divider),
            const SizedBox(height: 16),
            Text(
              'No $_selectedTab data found',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection() {
    return Column(
      children: [
        SizedBox(
          height: 250,
          child: Stack(
            children: [
              PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          _touchedIndex = -1;
                          return;
                        }
                        _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                  centerSpaceRadius: 75,
                  sections: _getPieSections(),
                ),
              ),
              // Center Text showing total
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currencyFormat.format(_totalAmount),
                      style: TextStyle(
                        color: _selectedTab == 'INCOME' ? AppColors.successGreen : AppColors.dangerRed,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _getPieSections() {
    return List.generate(_groupedData.length, (i) {
      final isTouched = i == _touchedIndex;
      final double radius = isTouched ? 45.0 : 35.0;
      
      final row = _groupedData[i];
      final double amount = (row['total_amount'] as num).toDouble();
      final Color color = Color(row['color']);
      final double percentage = (amount / _totalAmount) * 100;

      return PieChartSectionData(
        color: color,
        value: amount,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: isTouched ? 16.0 : 12.0,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [Shadow(color: Colors.black26, blurRadius: 2)],
        ),
      );
    });
  }

  Widget _buildLegendList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: List.generate(_groupedData.length, (index) {
          final row = _groupedData[index];
          final String name = row['category_name'];
          final double amount = (row['total_amount'] as num).toDouble();
          final Color color = Color(row['color']);
          final double percentage = (amount / _totalAmount) * 100;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(color: AppColors.textMain, fontWeight: FontWeight.w600),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _currencyFormat.format(amount),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMain),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
