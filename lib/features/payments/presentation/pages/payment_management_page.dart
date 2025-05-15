// lib/features/payments/presentation/pages/payment_management_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mytuition/config/router/route_names.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/payments/presentation/pages/payment_history_page.dart';
import 'package:mytuition/features/student_management/presentation/bloc/student_management_bloc.dart';
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

  // Action panel visibility state
  bool _isActionPanelVisible = false;

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

  void _toggleActionPanel() {
    setState(() {
      _isActionPanelVisible = !_isActionPanelVisible;
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
        title: const Text('Payment Management'),
        actions: [
          // Toggle selection mode
          IconButton(
            icon: Icon(_selectMode ? Icons.cancel : Icons.checklist),
            onPressed: _toggleSelectMode,
          ),
          // More options dropdown
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
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
              const PopupMenuItem<String>(
                value: 'payment_history',
                child: Row(
                  children: [
                    Icon(Icons.history, color: AppColors.primaryBlue),
                    SizedBox(width: 12),
                    Text('View Payment History'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'generate_monthly',
                child: Row(
                  children: [
                    Icon(Icons.article, color: AppColors.primaryBlue),
                    SizedBox(width: 12),
                    Text('Generate Monthly Payments'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'generate_missing',
                child: Row(
                  children: [
                    Icon(Icons.person_add, color: AppColors.accentTeal),
                    SizedBox(width: 12),
                    Text('Generate Missing Payments'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'send_reminders',
                child: Row(
                  children: [
                    Icon(Icons.notifications, color: AppColors.warning),
                    SizedBox(width: 12),
                    Text('Send Payment Reminders'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'payment_info',
                child: Row(
                  children: [
                    Icon(Icons.account_balance, color: AppColors.accentTeal),
                    SizedBox(width: 12),
                    Text('Payment Information'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh, color: AppColors.primaryBlue),
                    SizedBox(width: 12),
                    Text('Refresh'),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  height: 48,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.backgroundDark),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedMonth,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down),
                      items: List.generate(12, (index) {
                        final month = index + 1;
                        return DropdownMenuItem<int>(
                          value: month,
                          child: Text(
                            _getMonthName(month),
                            style: const TextStyle(
                              fontSize: 14,
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
              const SizedBox(width: 8),

              // Year dropdown
              Expanded(
                flex: 2,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.backgroundDark),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedYear,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                      items: List.generate(5, (index) {
                        final year = DateTime.now().year - 2 + index;
                        return DropdownMenuItem<int>(
                          value: year,
                          child: Text(
                            year.toString(),
                            style: const TextStyle(
                              fontSize: 14,
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          child: SizedBox(
            height: 40, // Reduced height from 48 to 40
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
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
            height: 50, // Reduced height to prevent overflow
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
        return const SizedBox(height: 50); // Reduced height
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
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(isSelected ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: color, width: 1.5)
                : Border.all(color: Colors.transparent),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      count.toString(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Checkbox(
                value: filteredPayments.isNotEmpty &&
                    _selectedPaymentIds.length == filteredPayments.length,
                onChanged: (_) => _selectAll(filteredPayments),
                visualDensity: VisualDensity.compact,
              ),
              Text(
                'Select All (${_selectedPaymentIds.length}/${filteredPayments.length})',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
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
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              icon: const Icon(Icons.notifications_outlined, size: 16),
              label:
                  const Text('Send Reminder', style: TextStyle(fontSize: 12)),
              onPressed: () => _showSendRemindersDialog(context),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              icon: const Icon(Icons.check_circle_outline, size: 16),
              label: const Text('Mark Paid', style: TextStyle(fontSize: 12)),
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
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }

        if (state is PaymentOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
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
                left: 12,
                right: 12,
                top: 4,
                bottom: _isActionPanelVisible
                    ? 180
                    : 80, // Adjust bottom padding for action panel
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
                size: 48,
                color: AppColors.textLight,
              ),
              const SizedBox(height: 16),
              const Text('Failed to load payment data'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  context.read<PaymentBloc>().add(
                        LoadPaymentsByMonthEvent(
                          month: _selectedMonth,
                          year: _selectedYear,
                        ),
                      );
                },
                child: const Text('Retry'),
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
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isSelected ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isSelected
            ? BorderSide(color: AppColors.primaryBlue, width: 1.5)
            : BorderSide.none,
      ),
      color: isSelected ? AppColors.primaryBlueLight.withOpacity(0.1) : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: _selectMode
            ? () => _togglePaymentSelection(payment.id)
            : () => _navigateToPaymentDetails(context, payment),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Checkbox if in select mode
              if (_selectMode)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
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
                              fontSize: 12,
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
                          fontSize: 11,
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
                      fontSize: 14,
                      color: isPaid ? AppColors.success : AppColors.textDark,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
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
                        fontSize: 10,
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

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height / 15),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.payment_outlined,
                size: 48,
                color: AppColors.textLight,
              ),
              const SizedBox(height: 16),
              const Text(
                'No payments found for this month',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Generate monthly payments to create payment records',
                style: TextStyle(
                  color: AppColors.textMedium,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _showGeneratePaymentsDialog(context),
                child: const Text('Generate Monthly Payments'),
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
                  size: 48,
                  color: AppColors.textLight,
                ),
                const SizedBox(height: 12),
                Text(
                  'No payments match your filters',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _statusFilter = 'All';
                    });
                  },
                  icon: const Icon(Icons.filter_alt_off, size: 16),
                  label: const Text('Clear Filters'),
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
        title: const Text('Mark Payments as Paid'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mark ${_selectedPaymentIds.length} selected payments as paid?',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: remarksController,
              decoration: const InputDecoration(
                labelText: 'Remarks (Optional)',
                hintText: 'Add any notes about these payments',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
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
            child: const Text('Mark as Paid'),
          ),
        ],
      ),
    );
  }

  // Dialog for sending payment reminders to selected students
  void _showSendRemindersDialog(BuildContext context) {
    if (_selectedPaymentIds.isEmpty) return;

    final messageController = TextEditingController(
        text:
            'Your payment for ${_getMonthName(_selectedMonth)} $_selectedYear is due.');
    final paymentBloc = context.read<PaymentBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Send Payment Reminders'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Send reminders to ${_selectedPaymentIds.length} selected students?',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Message',
                hintText: 'Enter reminder message',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);

              // Get selected payments
              final selectedPayments = _getSelectedPayments();
              if (selectedPayments.isEmpty) return;

              // Send reminders
              paymentBloc.add(
                SendPaymentRemindersEvent(
                  payments: selectedPayments,
                  message: messageController.text.trim(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
            ),
            child: const Text('Send Reminders'),
          ),
        ],
      ),
    );
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
        title: const Text('Send Reminders to All Unpaid'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Send reminders to all students with unpaid tuition?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Message',
                hintText: 'Enter reminder message',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
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
            child: const Text('Send to All Unpaid'),
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
        title: const Text('Generate Monthly Payments'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Calculate tuition for each student based on enrolled subjects',
              style: TextStyle(fontSize: 13),
            ),
            const Text(
              '• Create payment records for students without existing records',
              style: TextStyle(fontSize: 13),
            ),
            const Text(
              '• Skip students who already have payment records for this month',
              style: TextStyle(fontSize: 13),
            ),
            const Text(
              '• Skip students not enrolled in any classes',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            Text(
              'Generate payment records for ${_getMonthName(_selectedMonth)} $_selectedYear?',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
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
            child: const Text('Generate'),
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
        title: const Text('Generate Missing Payments'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Find students enrolled in classes but without payment records',
              style: TextStyle(fontSize: 13),
            ),
            const Text(
              '• Calculate tuition for each student based on enrolled subjects',
              style: TextStyle(fontSize: 13),
            ),
            const Text(
              '• Create payment records only for eligible students',
              style: TextStyle(fontSize: 13),
            ),
            const Text(
              '• Skip students already having payment records for this month',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            Text(
              'Generate missing payment records for ${_getMonthName(_selectedMonth)} $_selectedYear?',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
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
            child: const Text('Generate'),
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
