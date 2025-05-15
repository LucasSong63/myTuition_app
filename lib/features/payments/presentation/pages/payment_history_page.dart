// lib/features/payments/presentation/pages/payment_history_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/payments/domain/entities/payment_history_with_student.dart';
import '../bloc/payment_bloc.dart';
import '../../domain/entities/payment_history.dart';

class PaymentHistoryPage extends StatefulWidget {
  const PaymentHistoryPage({Key? key}) : super(key: key);

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'date';
  bool _ascending = false;

  @override
  void initState() {
    super.initState();
    // Load all payment history
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentBloc>().add(
            LoadAllPaymentHistoryEvent(),
          );
    });

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<PaymentBloc>().add(
                    LoadAllPaymentHistoryEvent(),
                  );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or ID...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
              ),
            ),
          ),

          // Sorting options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Text('Sort by:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _sortBy,
                  items: const [
                    DropdownMenuItem(value: 'date', child: Text('Date')),
                    DropdownMenuItem(value: 'amount', child: Text('Amount')),
                    DropdownMenuItem(
                        value: 'name', child: Text('Student Name')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _sortBy = value;
                      });
                    }
                  },
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: Icon(
                      _ascending ? Icons.arrow_upward : Icons.arrow_downward),
                  onPressed: () {
                    setState(() {
                      _ascending = !_ascending;
                    });
                  },
                  tooltip: _ascending ? 'Ascending' : 'Descending',
                ),
              ],
            ),
          ),

          // History list
          Expanded(
            child: BlocBuilder<PaymentBloc, PaymentState>(
              builder: (context, state) {
                if (state is PaymentLoading &&
                    !(state is AllPaymentHistoryLoaded)) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is AllPaymentHistoryLoaded) {
                  final history = state.history;

                  // Apply search filter
                  final filteredHistory = history.where((item) {
                    return item.studentName
                            .toLowerCase()
                            .contains(_searchQuery) ||
                        item.studentId.toLowerCase().contains(_searchQuery);
                  }).toList();

                  // Apply sorting
                  _sortHistory(filteredHistory);

                  if (filteredHistory.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 64,
                            color: AppColors.textLight,
                          ),
                          const SizedBox(height: 16),
                          _searchQuery.isNotEmpty
                              ? Text(
                                  'No payment history found matching "$_searchQuery"')
                              : const Text('No payment history found'),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredHistory.length,
                    itemBuilder: (context, index) {
                      final item = filteredHistory[index];
                      return _buildHistoryItem(item);
                    },
                  );
                }

                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Failed to load payment history'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<PaymentBloc>().add(
                                LoadAllPaymentHistoryEvent(),
                              );
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(PaymentHistoryWithStudent item) {
    // Determine status color
    Color statusColor;
    if (item.newStatus == 'paid') {
      statusColor = AppColors.success;
    } else if (item.newStatus == 'partial') {
      statusColor = AppColors.warning;
    } else {
      statusColor = AppColors.textMedium;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with student info and date
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _getAvatarColor(item.studentName),
                  child: Text(
                    item.studentName.isNotEmpty
                        ? item.studentName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.studentName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'ID: ${item.studentId}',
                        style: TextStyle(
                          color: AppColors.textMedium,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      DateFormat('dd MMM yyyy').format(item.date),
                      style: TextStyle(
                        color: AppColors.textMedium,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      DateFormat('hh:mm a').format(item.date),
                      style: TextStyle(
                        color: AppColors.textMedium,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),

            // Payment details
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RM ${item.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'For: ${_getMonthName(item.month)} ${item.year}',
                        style: TextStyle(
                          color: AppColors.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Status: ${_capitalizeFirst(item.newStatus)}',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            // Additional details
            if (item.remarks != null && item.remarks!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Remarks: ${item.remarks}',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: AppColors.textMedium,
                ),
              ),
            ],

            const SizedBox(height: 8),
            Text(
              'Recorded by: ${item.recordedBy}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sortHistory(List<PaymentHistoryWithStudent> history) {
    switch (_sortBy) {
      case 'date':
        history.sort((a, b) =>
            _ascending ? a.date.compareTo(b.date) : b.date.compareTo(a.date));
        break;
      case 'amount':
        history.sort((a, b) => _ascending
            ? a.amount.compareTo(b.amount)
            : b.amount.compareTo(a.amount));
        break;
      case 'name':
        history.sort((a, b) => _ascending
            ? a.studentName.compareTo(b.studentName)
            : b.studentName.compareTo(a.studentName));
        break;
    }
  }

  String _getMonthName(int month) {
    return DateFormat('MMMM').format(DateTime(2022, month));
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Color _getAvatarColor(String name) {
    final List<Color> colors = [
      AppColors.primaryBlue,
      AppColors.accentOrange,
      AppColors.accentTeal,
      AppColors.mathSubject,
      AppColors.scienceSubject,
      AppColors.englishSubject,
      AppColors.bahasaSubject,
      AppColors.chineseSubject,
    ];

    if (name.isEmpty) return colors[0];

    // Use a simple hash function to get a consistent color for the same name
    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash = (hash + name.codeUnitAt(i)) % colors.length;
    }

    return colors[hash];
  }
}
