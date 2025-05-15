// lib/features/courses/presentation/pages/subject_cost_configuration_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import '../bloc/subject_cost_bloc.dart';
import '../../domain/entities/subject_cost.dart';

class SubjectCostConfigurationPage extends StatefulWidget {
  const SubjectCostConfigurationPage({Key? key}) : super(key: key);

  @override
  State<SubjectCostConfigurationPage> createState() =>
      _SubjectCostConfigurationPageState();
}

class _SubjectCostConfigurationPageState
    extends State<SubjectCostConfigurationPage> {
  @override
  void initState() {
    super.initState();
    context.read<SubjectCostBloc>().add(LoadAllSubjectCostsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tuition Fee Configuration'),
      ),
      body: BlocConsumer<SubjectCostBloc, SubjectCostState>(
        listener: (context, state) {
          if (state is SubjectCostError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }

          if (state is SubjectCostActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is SubjectCostLoading &&
              !(state is AllSubjectCostsLoaded)) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AllSubjectCostsLoaded) {
            final subjectCosts = state.subjectCosts;

            if (subjectCosts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.money_off_outlined,
                      size: 64,
                      color: AppColors.textLight,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No subject costs configured',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Set up tuition fees for each subject',
                      style: TextStyle(
                        color: AppColors.textMedium,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        _showAddSubjectCostDialog(context);
                      },
                      child: const Text('Add Subject Cost'),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<SubjectCostBloc>().add(LoadAllSubjectCostsEvent());
                return Future.delayed(const Duration(milliseconds: 1000));
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: subjectCosts.length,
                itemBuilder: (context, index) {
                  final cost = subjectCosts[index];
                  return _buildSubjectCostCard(context, cost);
                },
              ),
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Failed to load subject costs'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context
                        .read<SubjectCostBloc>()
                        .add(LoadAllSubjectCostsEvent());
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddSubjectCostDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSubjectCostCard(BuildContext context, SubjectCost cost) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 40,
              decoration: BoxDecoration(
                color: _getSubjectColor(cost.subjectName),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cost.subjectName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Last updated: ${_formatDate(cost.lastUpdated)}',
                    style: TextStyle(
                      color: AppColors.textMedium,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'RM ${cost.cost.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _showEditSubjectCostDialog(context, cost),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSubjectCostDialog(BuildContext context) {
    final subjectController = TextEditingController();
    final costController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Subject Cost'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: subjectController,
              decoration: const InputDecoration(
                labelText: 'Subject Name',
                hintText: 'e.g., Mathematics',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: costController,
              decoration: const InputDecoration(
                labelText: 'Cost (RM)',
                hintText: 'e.g., 100.00',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final subject = subjectController.text.trim();
              final costText = costController.text.trim();

              if (subject.isEmpty || costText.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in all fields'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final cost = double.tryParse(costText);
              if (cost == null || cost <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid cost'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context);

              context.read<SubjectCostBloc>().add(
                    AddSubjectCostEvent(
                      subjectName: subject,
                      cost: cost,
                    ),
                  );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditSubjectCostDialog(BuildContext context, SubjectCost cost) {
    final costController = TextEditingController(text: cost.cost.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${cost.subjectName} Cost'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: costController,
              decoration: const InputDecoration(
                labelText: 'Cost (RM)',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final costText = costController.text.trim();

              if (costText.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a cost'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final newCost = double.tryParse(costText);
              if (newCost == null || newCost <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid cost'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context);

              context.read<SubjectCostBloc>().add(
                    UpdateSubjectCostEvent(
                      subjectCostId: cost.id,
                      newCost: newCost,
                    ),
                  );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getSubjectColor(String subject) {
    subject = subject.toLowerCase();
    if (subject.contains('math')) return AppColors.mathSubject;
    if (subject.contains('science')) return AppColors.scienceSubject;
    if (subject.contains('english')) return AppColors.englishSubject;
    if (subject.contains('bahasa')) return AppColors.bahasaSubject;
    if (subject.contains('chinese')) return AppColors.chineseSubject;
    return AppColors.primaryBlue;
  }
}
