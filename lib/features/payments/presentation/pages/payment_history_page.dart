// lib/features/payments/presentation/pages/payment_history_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
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
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Payment History',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, size: 6.w),
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
          // Header with search and filters
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search bar
                Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Container(
                    height: 12.w,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(3.w),
                      border: Border.all(
                        color: AppColors.backgroundDark.withOpacity(0.3),
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(fontSize: 14.sp),
                      decoration: InputDecoration(
                        hintText: 'Search by name or ID...',
                        hintStyle: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textLight,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          size: 6.w,
                          color: AppColors.textMedium,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, size: 5.w),
                                onPressed: () {
                                  _searchController.clear();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 3.w,
                        ),
                      ),
                    ),
                  ),
                ),

                // Sorting options
                Padding(
                  padding: EdgeInsets.only(left: 4.w, right: 4.w, bottom: 3.w),
                  child: Row(
                    children: [
                      Icon(
                        Icons.sort,
                        size: 5.w,
                        color: AppColors.primaryBlue,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        'Sort by:',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildSortChip('Date', 'date'),
                              SizedBox(width: 2.w),
                              _buildSortChip('Amount', 'amount'),
                              SizedBox(width: 2.w),
                              _buildSortChip('Student', 'name'),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(left: 2.w),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(2.w),
                        ),
                        child: IconButton(
                          icon: Icon(
                            _ascending
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            size: 5.w,
                            color: AppColors.primaryBlue,
                          ),
                          onPressed: () {
                            setState(() {
                              _ascending = !_ascending;
                            });
                          },
                          constraints: BoxConstraints(
                            minWidth: 10.w,
                            minHeight: 10.w,
                          ),
                          padding: EdgeInsets.all(2.w),
                          tooltip: _ascending ? 'Ascending' : 'Descending',
                        ),
                      ),
                    ],
                  ),
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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: AppColors.primaryBlue,
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          'Loading payment history...',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.textMedium,
                          ),
                        ),
                      ],
                    ),
                  );
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
                    return _buildEmptyState();
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<PaymentBloc>().add(
                            LoadAllPaymentHistoryEvent(),
                          );
                    },
                    child: ListView.builder(
                      padding: EdgeInsets.all(4.w),
                      itemCount: filteredHistory.length,
                      itemBuilder: (context, index) {
                        final item = filteredHistory[index];
                        return _buildHistoryItem(item);
                      },
                    ),
                  );
                }

                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 12.w,
                        color: AppColors.textLight,
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        'Failed to load payment history',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      ElevatedButton.icon(
                        onPressed: () {
                          context.read<PaymentBloc>().add(
                                LoadAllPaymentHistoryEvent(),
                              );
                        },
                        icon: Icon(Icons.refresh, size: 5.w),
                        label: Text(
                          'Retry',
                          style: TextStyle(fontSize: 14.sp),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 3.w,
                          ),
                        ),
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

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _sortBy = value;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.5.w, vertical: 2.w),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryBlue
              : AppColors.backgroundDark.withOpacity(0.3),
          borderRadius: BorderRadius.circular(5.w),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryBlue
                : AppColors.backgroundDark.withOpacity(0.5),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textDark,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history,
                size: 15.w,
                color: AppColors.primaryBlue,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No results found'
                  : 'No Payment History',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try adjusting your search terms'
                  : 'Payment history will appear here once payments are recorded',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textMedium,
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isNotEmpty) ...[
              SizedBox(height: 3.h),
              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                },
                icon: Icon(Icons.clear, size: 5.w),
                label: Text(
                  'Clear Search',
                  style: TextStyle(fontSize: 14.sp),
                ),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: 5.w,
                    vertical: 3.w,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(PaymentHistoryWithStudent item) {
    // Determine status color
    Color statusColor;
    IconData statusIcon;
    if (item.newStatus == 'paid') {
      statusColor = AppColors.success;
      statusIcon = Icons.check_circle;
    } else if (item.newStatus == 'partial') {
      statusColor = AppColors.warning;
      statusIcon = Icons.pending;
    } else {
      statusColor = AppColors.textMedium;
      statusIcon = Icons.circle_outlined;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 3.w),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3.w),
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with student info and date
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 12.w,
                  height: 12.w,
                  decoration: BoxDecoration(
                    color: _getAvatarColor(item.studentName).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      item.studentName.isNotEmpty
                          ? item.studentName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: _getAvatarColor(item.studentName),
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 3.w),

                // Student info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.studentName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15.sp,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Row(
                        children: [
                          Icon(
                            Icons.badge_outlined,
                            size: 4.w,
                            color: AppColors.textMedium,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            'ID: ${item.studentId}',
                            style: TextStyle(
                              color: AppColors.textMedium,
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Date and time
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.5.w,
                        vertical: 1.w,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(2.w),
                      ),
                      child: Text(
                        DateFormat('dd MMM').format(item.date),
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(height: 1.w),
                    Text(
                      DateFormat('hh:mm a').format(item.date),
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 10.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 3.w),
            
            // Payment details section
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(2.w),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Amount
                      Row(
                        children: [
                          Icon(
                            Icons.payments,
                            size: 5.w,
                            color: AppColors.primaryBlue,
                          ),
                          SizedBox(width: 2.w),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'RM ${item.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.sp,
                                  color: AppColors.textDark,
                                ),
                              ),
                              Text(
                                '${_getMonthName(item.month)} ${item.year}',
                                style: TextStyle(
                                  color: AppColors.textMedium,
                                  fontSize: 11.sp,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Status badge
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 3.w,
                          vertical: 1.5.w,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(5.w),
                          border: Border.all(
                            color: statusColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              statusIcon,
                              size: 4.w,
                              color: statusColor,
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              _capitalizeFirst(item.newStatus),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Status transition
                  if (item.previousStatus != 'new') ...[
                    SizedBox(height: 2.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 1.w,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(1.5.w),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _capitalizeFirst(item.previousStatus),
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: AppColors.textMedium,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 1.5.w),
                            child: Icon(
                              Icons.arrow_forward,
                              size: 3.5.w,
                              color: AppColors.textMedium,
                            ),
                          ),
                          Text(
                            _capitalizeFirst(item.newStatus),
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Additional details
            if (item.remarks != null && item.remarks!.isNotEmpty) ...[
              SizedBox(height: 3.w),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: AppColors.warningLight.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2.w),
                  border: Border.all(
                    color: AppColors.warning.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.note,
                      size: 4.w,
                      color: AppColors.warning,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        item.remarks!,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: 3.w),

            // Footer with recorded by info
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 4.w,
                  color: AppColors.textLight,
                ),
                SizedBox(width: 1.w),
                Text(
                  'Recorded by: ${item.recordedBy}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.textLight,
                  ),
                ),
              ],
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
