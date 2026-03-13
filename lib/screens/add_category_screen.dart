import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../database/db_helper.dart';

class AddCategoryScreen extends StatefulWidget {
  final String transactionType; // 'INCOME' or 'EXPENSE'

  const AddCategoryScreen({super.key, required this.transactionType});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _nameController = TextEditingController();
  
  // Default values
  int _selectedColor = 0xFF4FC3F7; // Light blue
  IconData _selectedIcon = Icons.category;

  final List<int> _colorOptions = [
    0xFFFFB74D, // Orange
    0xFFBA68C8, // Purple
    0xFF4FC3F7, // Light Blue
    0xFFE57373, // Red
    0xFF81C784, // Green
    0xFFFFD54F, // Yellow
    0xFF64B5F6, // Blue
    0xFF90A4AE, // Blue Grey
    0xFFF06292, // Pink
    0xFF4DB6AC, // Teal
  ];

  final List<IconData> _iconOptions = [
    Icons.category,
    Icons.fastfood,
    Icons.shopping_cart,
    Icons.directions_car,
    Icons.local_hospital,
    Icons.flight,
    Icons.school,
    Icons.home,
    Icons.pets,
    Icons.fitness_center,
    Icons.work,
    Icons.card_giftcard,
    Icons.account_balance_wallet,
    Icons.attach_money,
    Icons.computer,
  ];

  Future<void> _saveCategory() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a category name')),
      );
      return;
    }

    final newCategory = {
      'name': name,
      'icon_code': _selectedIcon.codePoint,
      'color': _selectedColor,
      'type': widget.transactionType,
    };

    await DatabaseHelper.instance.insertCategory(newCategory);
    
    if (mounted) {
      Navigator.pop(context, true); // Return true to signal success
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textMain),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'New ${widget.transactionType == 'INCOME' ? 'Income' : 'Expense'} Category',
          style: const TextStyle(
            color: AppColors.textMain,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Preview ---
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Color(_selectedColor).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _selectedIcon,
                    color: Color(_selectedColor),
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // --- Name Input ---
              const Text(
                'Category Name',
                style: TextStyle(
                  color: AppColors.textMain,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'e.g. Groceries',
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.cardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // --- Color Picker ---
              const Text(
                'Select Color',
                style: TextStyle(
                  color: AppColors.textMain,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _colorOptions.map((colorValue) {
                  final isSelected = _selectedColor == colorValue;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = colorValue),
                    child: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: Color(colorValue),
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                        boxShadow: isSelected 
                            ? [BoxShadow(color: Color(colorValue).withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2)] 
                            : null,
                      ),
                      child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              
              // --- Icon Picker ---
              const Text(
                'Select Icon',
                style: TextStyle(
                  color: AppColors.textMain,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: _iconOptions.map((iconData) {
                    final isSelected = _selectedIcon == iconData;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIcon = iconData),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryBlueLight : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          iconData,
                          color: isSelected ? AppColors.primaryBlue : AppColors.textSecondary,
                          size: 28,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 48),

              // --- Save Button ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveCategory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    'Save Category',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
