// lib/features/payments/presentation/widgets/bank_account_form.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/payments/domain/entities/payment_info.dart';

class BankAccountForm extends StatefulWidget {
  final BankAccount? account;
  final Function(BankAccount) onSave;

  const BankAccountForm({
    Key? key,
    this.account,
    required this.onSave,
  }) : super(key: key);

  @override
  State<BankAccountForm> createState() => _BankAccountFormState();
}

class _BankAccountFormState extends State<BankAccountForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _accountHolderController =
      TextEditingController();

  bool _isActive = true;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing values if editing
    if (widget.account != null) {
      _nameController.text = widget.account!.name;
      _accountNumberController.text = widget.account!.accountNumber;
      _accountHolderController.text = widget.account!.accountHolder;
      _isActive = widget.account!.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _accountNumberController.dispose();
    _accountHolderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          widget.account == null ? 'Add Bank Account' : 'Edit Bank Account'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bank name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Bank Name',
                  hintText: 'e.g., Maybank, CIMB, Public Bank',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the bank name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Account number field
              TextFormField(
                controller: _accountNumberController,
                decoration: const InputDecoration(
                  labelText: 'Account Number',
                  hintText: 'Enter the bank account number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the account number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Account holder field
              TextFormField(
                controller: _accountHolderController,
                decoration: const InputDecoration(
                  labelText: 'Account Holder',
                  hintText: 'Enter the account holder name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the account holder name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Is active switch
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Active',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  Switch(
                    value: _isActive,
                    activeColor: AppColors.success,
                    onChanged: (value) {
                      setState(() {
                        _isActive = value;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final account = BankAccount(
                id: widget.account?.id ?? '',
                name: _nameController.text,
                accountNumber: _accountNumberController.text,
                accountHolder: _accountHolderController.text,
                isActive: _isActive,
              );

              widget.onSave(account);
              Navigator.pop(context);
            }
          },
          child: Text(widget.account == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }
}
