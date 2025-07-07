// lib/features/payments/presentation/pages/payment_management_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:mytuition/config/router/route_names.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/payments/presentation/pages/payment_history_page.dart';
import '../../../notifications/presentation/widgets/send_notification_bottom_sheet.dart';
import '../bloc/payment_bloc.dart';
import '../../domain/entities/payment.dart';
import 'payment_detail_page.dart';

class PaymentManagementPage extends StatefulWidget {
  const PaymentManagementPage({Key? key}) : super(key: key);

  @override
  State<PaymentManagementPage> createState() => _PaymentManagementPageState();
}

class _PaymentManagementPageState extends State<PaymentManagementPage> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'All';

  // Track selected payments for bulk actions
  final Set<String> _selectedPaymentIds = {};
  bool _selectMode = false;

  @override
  void initState() {
    super.initState();
    // Load payments for the current month and year
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentBloc>().add(
            LoadPaymentsByMonthEvent(
              month: _selectedMonth,
              year: _selectedYear,
            ),
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

  void _toggleSelectMode() {
    setState(() {
      _selectMode = !_selectMode;
      if (!_selectMode) {
        _selectedPaymentIds.clear();
      }
    });
  }

  void _togglePaymentSelection(String paymentId) {
    setState(() {
      if (_selectedPaymentIds.contains(paymentId)) {
        _selectedPaymentIds.remove(paymentId);
      } else {
        _selectedPaymentIds.add(paymentId);
      }
    });
  }

  void _selectAll(List<Payment> payments) {
    setState(() {
      if (_selectedPaymentIds.length == payments.length) {
        // If all are selected, deselect all
        _selectedPaymentIds.clear();
      } else {
        // Otherwise, select all
        _selectedPaymentIds.clear();
        for (final payment in payments) {
          _selectedPaymentIds.add(payment.id);
        }
      }
    });
  }

  // Apply status filter
  void _applyStatusFilter(String status) {
    setState(() {
      _statusFilter = status;
    });
  }

  // Filter payments based on search query and status filter - properly handling studentId
  List<Payment> _filterPayments(List<Payment> payments) {
    return payments.where((payment) {
      // Status filter
      if (_statusFilter != 'All' &&
          payment.status != _statusFilter.toLowerCase()) {
        return false;
      }

      // Search filter - ensure we're searching in the correct studentId field
      if (_searchQuery.isNotEmpty) {
        // The studentId in the Payment entity is set directly from the studentId
        // field in Firestore when creating the Payment object
        return payment.studentName.toLowerCase().contains(_searchQuery) ||
            payment.studentId.toLowerCase().contains(_searchQuery);
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Payment Management',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        actions: [
          // Toggle selection mode
          IconButton(
            icon: Icon(_selectMode ? Icons.cancel : Icons.checklist, size: 6.w),
            onPressed: _toggleSelectMode,
          ),
          // More options dropdown
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, size: 6.w),
            onSelected: (value) {
              switch (value) {
                case 'payment_history':
                  _navigateToPaymentHistory(context);
                  break;
                case 'generate_monthly':
                  _showGeneratePaymentsDialog(context);
                  break;
                case 'generate_missing':
                  _showGenerateMissingPaymentsDialog(context);
                  break;
                case 'send_reminders':
                  _showSendAllRemindersDialog(context);
                  break;
                case 'payment_info':
                  context.pushNamed(RouteNames.tutorPaymentInfo);
                  break;
                case 'refresh':
                  _loadPayments();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'payment_history',
                child: Row(
                  children: [
                    Icon(Icons.history, color: AppColors.primaryBlue, size: 5.w),
                    SizedBox(width: 3.w),
                    Text('View Payment History', style: TextStyle(fontSize: 14.sp)),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'generate_monthly',
                child: Row(
                  children: [
                    Icon(Icons.article, color: AppColors.primaryBlue, size: 5.w),
                    SizedBox(width: 3.w),
                    Text('Generate Monthly Payments', style: TextStyle(fontSize: 14.sp)),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'generate_missing',
                child: Row(
                  children: [
                    Icon(Icons.person_add, color: AppColors.accentTeal, size: 5.w),
                    SizedBox(width: 3.w),
                    Text('Generate Missing Payments', style: TextStyle(fontSize: 14.sp)),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'send_reminders',
                child: Row(
                  children: [
                    Icon(Icons.notifications, color: AppColors.warning, size: 5.w),
                    SizedBox(width: 3.w),
                    Text('Send Payment Reminders', style: TextStyle(fontSize: 14.sp)),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'payment_info',
                child: Row(
                  children: [
                    Icon(Icons.account_balance, color: AppColors.accentTeal, size: 5.w),
                    SizedBox(width: 3.w),
                    Text('Payment Information', style: TextStyle(fontSize: 14.sp)),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh, color: AppColors.primaryBlue, size: 5.w),
                    SizedBox(width: 3.w),
                    Text('Refresh', style: TextStyle(fontSize: 14.sp)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Compact header section (month/year selector + search)
              _buildHeader(),

              // Status Summary Cards (more compact design)
              _buildStatusCards(),

              // Selection controls (when in select mode)
              if (_selectMode) _buildSelectionControls(),

              // Selection action buttons (when items are selected)
              if (_selectMode && _selectedPaymentIds.isNotEmpty)
                _buildSelectionActionButtons(),

              // Payments List (now takes more screen space)
              Expanded(
                child: _buildPaymentsList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Month and Year selectors in a row
        Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
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
          child: Row(
            children: [
              // Month dropdown
              Expanded(
                flex: 3,
                child: Container(
                  height: 11.h > 50.0 ? 50.0 : 11.h,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.backgroundDark),
                    borderRadius: BorderRadius.circular(2.w),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedMonth,
                      isExpanded: true,
                      icon: Icon(Icons.keyboard_arrow_down, size: 5.w),
                      items: List.generate(12, (index) {
                        final month = index + 1;
                        return DropdownMenuItem<int>(
                          value: month,
                          child: Text(
                            _getMonthName(month),
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedMonth = value;
                            _selectedPaymentIds.clear();
                          });
                          context.read<PaymentBloc>().add(
                                LoadPaymentsByMonthEvent(
                                  month: value,
                                  year: _selectedYear,
                                ),
                              );
                        }
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(width: 2.w),

              // Year dropdown
              Expanded(
                flex: 2,
                child: Container(
                  height: 11.h > 50.0 ? 50.0 : 11.h,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.backgroundDark),
                    borderRadius: BorderRadius.circular(2.w),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 3.w),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedYear,
                      isExpanded: true,
                      icon: Icon(Icons.keyboard_arrow_down, size: 5.w),
                      items: List.generate(5, (index) {
                        final year = DateTime.now().year - 2 + index;
                        return DropdownMenuItem<int>(
                          value: year,
                          child: Text(
                            year.toString(),
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedYear = value;
                            _selectedPaymentIds.clear();
                          });
                          context.read<PaymentBloc>().add(
                                LoadPaymentsByMonthEvent(
                                  month: _selectedMonth,
                                  year: value,
                                ),
                              );
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Search field (below month/year selectors with reduced height)
        Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          color: Colors.white,
          child: SizedBox(
            height: 10.h > 48.0 ? 48.0 : 10.h,
            child: TextField(
              controller: _searchController,
              style: TextStyle(fontSize: 14.sp),
              decoration: InputDecoration(
                hintText: 'Search...',
                hintStyle: TextStyle(fontSize: 14.sp),
                prefixIcon: Icon(Icons.search, size: 5.w),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, size: 5.w),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(2.w),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 2.h),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // STATUS CARDS: Fixed to prevent overflow
  Widget _buildStatusCards() {
    return BlocBuilder<PaymentBloc, PaymentState>(
      builder: (context, state) {
        if (state is PaymentsByMonthLoaded) {
          final payments = state.payments;

          // Calculate summary stats
          int totalPayments = payments.length;
          int paidCount = payments.where((p) => p.status == 'paid').length;
          int unpaidCount = payments.where((p) => p.status == 'unpaid').length;
          int partialCount =
              payments.where((p) => p.status == 'partial').length;

          return Container(
            height: 11.h,
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            child: Row(
              children: [
                _buildStatusCard(
                    'Total', totalPayments, AppColors.primaryBlue, 'All'),
                _buildStatusCard('Paid', paidCount, AppColors.success, 'paid'),
                _buildStatusCard(
                    'Unpaid', unpaidCount, AppColors.error, 'unpaid'),
                _buildStatusCard(
                    'Partial', partialCount, AppColors.warning, 'partial'),
              ],
            ),
          );
        }
        return SizedBox(height: 11.h);
      },
    );
  }

  // Creates a more compact status indicator card to prevent overflow
  Widget _buildStatusCard(
      String label, int count, Color color, String statusFilter) {
    final isSelected = _statusFilter == statusFilter;

    return Expanded(
      child: GestureDetector(
        onTap: () => _applyStatusFilter(statusFilter),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 1.w),
          decoration: BoxDecoration(
            color: color.withOpacity(isSelected ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(2.w),
            border: isSelected
                ? Border.all(color: color, width: 0.4.w)
                : Border.all(color: Colors.transparent),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 2.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                SizedBox(height: 0.5.h),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Controls for selection mode
  Widget _buildSelectionControls() {
    return BlocBuilder<PaymentBloc, PaymentState>(
      builder: (context, state) {
        final filteredPayments = state is PaymentsByMonthLoaded
            ? _filterPayments(state.payments)
            : <Payment>[];

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          child: Row(
            children: [
              Checkbox(
                value: filteredPayments.isNotEmpty &&
                    _selectedPaymentIds.length == filteredPayments.length,
                onChanged: (_) => _selectAll(filteredPayments),
                visualDensity: VisualDensity.compact,
              ),
              Expanded(
                child: Text(
                  'Select All (${_selectedPaymentIds.length}/${filteredPayments.length})',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Action buttons for selected items
  Widget _buildSelectionActionButtons() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 2.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2.w),
                ),
              ),
              icon: Icon(Icons.notifications_outlined, size: 4.w),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('Send Reminder', style: TextStyle(fontSize: 12.sp)),
              ),
              onPressed: () => _showSendRemindersDialog(context),
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 2.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2.w),
                ),
              ),
              icon: Icon(Icons.check_circle_outline, size: 4.w),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('Mark Paid', style: TextStyle(fontSize: 12.sp)),
              ),
              onPressed: () => _showBulkMarkAsPaidDialog(context),
            ),
          ),
        ],
      ),
    );
  }

// Part 2: Payment List and Core Functionality

  // Main payments list builder (expanded to take more screen space)
  Widget _buildPaymentsList() {
    return BlocConsumer<PaymentBloc, PaymentState>(
      listener: (context, state) {
        if (state is PaymentError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message, style: TextStyle(fontSize: 14.sp)),
              backgroundColor: Colors.red,
            ),
          );
        }

        if (state is PaymentOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message, style: TextStyle(fontSize: 14.sp)),
              backgroundColor: AppColors.success,
            ),
          );

          // Clear selection after bulk action
          setState(() {
            _selectedPaymentIds.clear();
            _selectMode = false;
          });
        }
      },
      builder: (context, state) {
        if (state is PaymentLoading && !(state is PaymentsByMonthLoaded)) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is PaymentsByMonthLoaded) {
          final payments = state.payments;

          if (payments.isEmpty) {
            return _buildEmptyState();
          }

          // Apply filters to the payments
          final filteredPayments = _filterPayments(payments);

          // Check if filtered list is empty
          if (filteredPayments.isEmpty) {
            return _buildNoResultsState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<PaymentBloc>().add(
                    LoadPaymentsByMonthEvent(
                      month: _selectedMonth,
                      year: _selectedYear,
                    ),
                  );
              return Future.delayed(const Duration(milliseconds: 1000));
            },
            child: ListView.builder(
              padding: EdgeInsets.only(
                left: 3.w,
                right: 3.w,
                top: 1.h,
                bottom: 10.h,
              ),
              itemCount: filteredPayments.length,
              itemBuilder: (context, index) {
                final payment = filteredPayments[index];
                return _buildPaymentListItem(context, payment);
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
              SizedBox(height: 4.h),
              Text('Failed to load payment data', style: TextStyle(fontSize: 14.sp)),
              SizedBox(height: 3.h),
              ElevatedButton(
                onPressed: () {
                  context.read<PaymentBloc>().add(
                        LoadPaymentsByMonthEvent(
                          month: _selectedMonth,
                          year: _selectedYear,
                        ),
                      );
                },
                child: Text('Retry', style: TextStyle(fontSize: 14.sp)),
              ),
            ],
          ),
        );
      },
    );
  }

  // Redesigned payment list item - with proper student ID display
  Widget _buildPaymentListItem(BuildContext context, Payment payment) {
    final isPaid = payment.status == 'paid';
    final isPartial = payment.status == 'partial';
    final isSelected = _selectedPaymentIds.contains(payment.id);

    // Get status color
    Color statusColor;
    if (isPaid) {
      statusColor = AppColors.success;
    } else if (isPartial) {
      statusColor = AppColors.warning;
    } else {
      statusColor = AppColors.error;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: isSelected ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(2.w),
        side: isSelected
            ? BorderSide(color: AppColors.primaryBlue, width: 0.4.w)
            : BorderSide.none,
      ),
      color: isSelected ? AppColors.primaryBlueLight.withOpacity(0.1) : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(2.w),
        onTap: _selectMode
            ? () => _togglePaymentSelection(payment.id)
            : () => _navigateToPaymentDetails(context, payment),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.5.h),
          child: Row(
            children: [
              // Checkbox if in select mode
              if (_selectMode)
                Padding(
                  padding: EdgeInsets.only(right: 2.w),
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (_) => _togglePaymentSelection(payment.id),
                    visualDensity: VisualDensity.compact,
                  ),
                ),

              // Student info - taking more space and displaying the correct studentId
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.studentName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        // The studentId field in the Payment entity already has
                        // the correct ID from the Firebase document
                        Expanded(
                          child: Text(
                            'ID: ${payment.studentId}',
                            style: TextStyle(
                              color: AppColors.textMedium,
                              fontSize: 12.sp,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (payment.paidDate != null)
                      Text(
                        '• ${DateFormat('dd/MM/yy').format(payment.paidDate!)}',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.success,
                        ),
                      ),
                  ],
                ),
              ),

              // Payment amount and status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'RM ${payment.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                      color: isPaid ? AppColors.success : AppColors.textDark,
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 1.h),
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(1.5.w),
                    ),
                    child: Text(
                      isPaid
                          ? 'Paid'
                          : isPartial
                              ? 'Partial'
                              : 'Unpaid',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 10.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      children: [
        SizedBox(height: 10.h),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.payment_outlined,
                size: 12.w,
                color: AppColors.textLight,
              ),
              SizedBox(height: 4.h),
              Text(
                'No payments found for this month',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 2.h),
              Text(
                'Generate monthly payments to create payment records',
                style: TextStyle(
                  color: AppColors.textMedium,
                  fontSize: 14.sp,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4.h),
              ElevatedButton(
                onPressed: () => _showGeneratePaymentsDialog(context),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                ),
                child: Text('Generate Monthly Payments', style: TextStyle(fontSize: 14.sp)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoResultsState() {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 12.w,
                  color: AppColors.textLight,
                ),
                SizedBox(height: 3.h),
                Text(
                  'No payments match your filters',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 2.h),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _statusFilter = 'All';
                    });
                  },
                  icon: Icon(Icons.filter_alt_off, size: 4.w),
                  label: Text('Clear Filters', style: TextStyle(fontSize: 14.sp)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToPaymentDetails(BuildContext context, Payment payment) {
    // Capture the BLoC before navigation
    final paymentBloc = context.read<PaymentBloc>();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: paymentBloc, // Use the captured BLoC instance
          child: PaymentDetailPage(
            payment: payment,
            onPaymentUpdated: () {
              // Will be called when payment is updated
              if (mounted) {
                paymentBloc.add(
                  LoadPaymentsByMonthEvent(
                    month: _selectedMonth,
                    year: _selectedYear,
                  ),
                );
              }
            },
          ),
        ),
      ),
    ).then((_) {
      // When returning, reload data
      if (mounted) {
        // Add a slight delay to ensure UI is updated first
        Future.delayed(const Duration(milliseconds: 100), () {
          paymentBloc.add(
            LoadPaymentsByMonthEvent(
              month: _selectedMonth,
              year: _selectedYear,
            ),
          );
        });
      }
    });
  }

  // Helper for getting month name
  String _getMonthName(int month) {
    return DateFormat('MMMM').format(DateTime(2022, month));
  }

  // Get selected payments list
  List<Payment> _getSelectedPayments() {
    if (context.read<PaymentBloc>().state is! PaymentsByMonthLoaded) {
      return [];
    }

    final state = context.read<PaymentBloc>().state as PaymentsByMonthLoaded;
    return state.payments
        .where((p) => _selectedPaymentIds.contains(p.id))
        .toList();
  }

  // Part 3: Dialog implementations

  // Dialog for bulk marking payments as paid
  void _showBulkMarkAsPaidDialog(BuildContext context) {
    if (_selectedPaymentIds.isEmpty) return;

    final remarksController = TextEditingController();
    final paymentBloc = context.read<PaymentBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Mark Payments as Paid', style: TextStyle(fontSize: 16.sp)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mark ${_selectedPaymentIds.length} selected payments as paid?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
            ),
            SizedBox(height: 4.h),
            TextField(
              controller: remarksController,
              style: TextStyle(fontSize: 14.sp),
              decoration: InputDecoration(
                labelText: 'Remarks (Optional)',
                labelStyle: TextStyle(fontSize: 14.sp),
                hintText: 'Add any notes about these payments',
                hintStyle: TextStyle(fontSize: 12.sp),
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: TextStyle(fontSize: 14.sp)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);

              // Get selected payments
              final selectedPayments = _getSelectedPayments();
              if (selectedPayments.isEmpty) return;

              // Process bulk payment
              paymentBloc.add(
                BulkMarkPaymentsAsPaidEvent(
                  payments: selectedPayments,
                  remarks: remarksController.text.trim(),
                  recordedBy: 'tutor-leong', // Should come from auth
                  sendNotification: true,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: Text('Mark as Paid', style: TextStyle(fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }

  // Dialog for sending payment reminders to selected students
  void _showSendRemindersDialog(BuildContext context) {
    if (_selectedPaymentIds.isEmpty) return;

    // Get selected payments
    final selectedPayments = _getSelectedPayments();
    if (selectedPayments.isEmpty) return;

    // Get student IDs and names
    final studentIds = selectedPayments.map((p) => p.studentId).toList();
    final studentNames = selectedPayments.map((p) => p.studentName).toList();

    // Show the notification bottom sheet
    SendNotificationBottomSheet.show(
      context: context,
      studentIds: studentIds,
      studentNames: studentNames,
      defaultTitle: 'Payment Reminder',
      defaultMessage:
          'Your payment for ${_getMonthName(_selectedMonth)} $_selectedYear is due.',
      notificationType: 'payment_reminder',
    ).then((success) {
      if (success == true) {
        // Optionally refresh payments or show a success message
      }
    });
  }

  // Dialog for sending reminders to all students with unpaid payments
  void _showSendAllRemindersDialog(BuildContext context) {
    final messageController = TextEditingController(
        text:
            'Your payment for ${_getMonthName(_selectedMonth)} $_selectedYear is due.');
    final paymentBloc = context.read<PaymentBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Send Reminders to All Unpaid', style: TextStyle(fontSize: 16.sp)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Send reminders to all students with unpaid tuition?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
            ),
            SizedBox(height: 4.h),
            TextField(
              controller: messageController,
              style: TextStyle(fontSize: 14.sp),
              decoration: InputDecoration(
                labelText: 'Message',
                labelStyle: TextStyle(fontSize: 14.sp),
                hintText: 'Enter reminder message',
                hintStyle: TextStyle(fontSize: 12.sp),
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: TextStyle(fontSize: 14.sp)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);

              // Send reminders to all unpaid
              paymentBloc.add(
                SendAllUnpaidRemindersEvent(
                  month: _selectedMonth,
                  year: _selectedYear,
                  message: messageController.text.trim(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
            ),
            child: Text('Send to All Unpaid', style: TextStyle(fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }

  // Dialog for generating monthly payments
  void _showGeneratePaymentsDialog(BuildContext context) {
    // Capture the BLoC before creating the dialog
    final paymentBloc = context.read<PaymentBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Generate Monthly Payments', style: TextStyle(fontSize: 16.sp)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
            ),
            SizedBox(height: 2.h),
            Text(
              '• Calculate tuition for each student based on enrolled subjects',
              style: TextStyle(fontSize: 13.sp),
            ),
            Text(
              '• Create payment records for students without existing records',
              style: TextStyle(fontSize: 13.sp),
            ),
            Text(
              '• Skip students who already have payment records for this month',
              style: TextStyle(fontSize: 13.sp),
            ),
            Text(
              '• Skip students not enrolled in any classes',
              style: TextStyle(fontSize: 13.sp),
            ),
            SizedBox(height: 4.h),
            Text(
              'Generate payment records for ${_getMonthName(_selectedMonth)} $_selectedYear?',
              style: TextStyle(fontSize: 14.sp),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: TextStyle(fontSize: 14.sp)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // Use the captured BLoC
              paymentBloc.add(
                GenerateMonthlyPaymentsEvent(
                  month: _selectedMonth,
                  year: _selectedYear,
                ),
              );
            },
            child: Text('Generate', style: TextStyle(fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }

  // Dialog for generating missing payments
  void _showGenerateMissingPaymentsDialog(BuildContext context) {
    // Capture the BLoC before creating the dialog
    final paymentBloc = context.read<PaymentBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Generate Missing Payments', style: TextStyle(fontSize: 16.sp)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
            ),
            SizedBox(height: 2.h),
            Text(
              '• Find students enrolled in classes but without payment records',
              style: TextStyle(fontSize: 13.sp),
            ),
            Text(
              '• Calculate tuition for each student based on enrolled subjects',
              style: TextStyle(fontSize: 13.sp),
            ),
            Text(
              '• Create payment records only for eligible students',
              style: TextStyle(fontSize: 13.sp),
            ),
            Text(
              '• Skip students already having payment records for this month',
              style: TextStyle(fontSize: 13.sp),
            ),
            SizedBox(height: 4.h),
            Text(
              'Generate missing payment records for ${_getMonthName(_selectedMonth)} $_selectedYear?',
              style: TextStyle(fontSize: 14.sp),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: TextStyle(fontSize: 14.sp)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // Use the captured BLoC
              paymentBloc.add(
                GenerateMissingPaymentsEvent(
                  month: _selectedMonth,
                  year: _selectedYear,
                ),
              );
            },
            child: Text('Generate', style: TextStyle(fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }

// Add a helper method for the payment history navigation too
  void _navigateToPaymentHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<PaymentBloc>(),
          child: const PaymentHistoryPage(),
        ),
      ),
    );
  }

  void _loadPayments() {
    context.read<PaymentBloc>().add(
          LoadPaymentsByMonthEvent(
            month: _selectedMonth,
            year: _selectedYear,
          ),
        );
  }
}
