// lib/features/payments/presentation/widgets/e_wallet_form.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/payments/domain/entities/payment_info.dart';

class EWalletForm extends StatefulWidget {
  final EWallet? wallet;
  final Function(EWallet) onSave;

  const EWalletForm({
    Key? key,
    this.wallet,
    required this.onSave,
  }) : super(key: key);

  @override
  State<EWalletForm> createState() => _EWalletFormState();
}

class _EWalletFormState extends State<EWalletForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _isActive = true;

  // List of common Malaysian e-wallets for suggestions
  final List<String> _eWalletTypes = [
    'Touch \'n Go eWallet',
    'Boost',
    'GrabPay',
    'MAE',
    'BigPay',
    'ShopeePay',
    'Alipay',
    'WeChat Pay'
  ];

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing values if editing
    if (widget.wallet != null) {
      _typeController.text = widget.wallet!.type;
      _numberController.text = widget.wallet!.number;
      _nameController.text = widget.wallet!.name;
      _isActive = widget.wallet!.isActive;
    }
  }

  @override
  void dispose() {
    _typeController.dispose();
    _numberController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.wallet == null ? 'Add E-Wallet' : 'Edit E-Wallet'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // E-wallet type field with autocomplete
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return _eWalletTypes;
                  }
                  return _eWalletTypes.where((type) => type
                      .toLowerCase()
                      .contains(textEditingValue.text.toLowerCase()));
                },
                onSelected: (String selection) {
                  _typeController.text = selection;
                },
                fieldViewBuilder:
                    (context, controller, focusNode, onFieldSubmitted) {
                  // If editing, initialize controller with existing value
                  if (widget.wallet != null && controller.text.isEmpty) {
                    controller.text = widget.wallet!.type;
                  }

                  // Store reference to this controller
                  _typeController.text = controller.text;

                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    onChanged: (value) => _typeController.text = value,
                    decoration: const InputDecoration(
                      labelText: 'E-Wallet Service',
                      hintText: 'e.g., Touch \'n Go eWallet, Boost',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the e-wallet service name';
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 16),

              // E-wallet number/ID field
              TextFormField(
                controller: _numberController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number/ID',
                  hintText: 'Enter the phone number or ID linked to e-wallet',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the phone number or ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Account holder name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Account Name',
                  hintText: 'Enter the account holder name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the account name';
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
              final wallet = EWallet(
                id: widget.wallet?.id ?? '',
                type: _typeController.text,
                number: _numberController.text,
                name: _nameController.text,
                isActive: _isActive,
              );

              widget.onSave(wallet);
              Navigator.pop(context);
            }
          },
          child: Text(widget.wallet == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }
}
