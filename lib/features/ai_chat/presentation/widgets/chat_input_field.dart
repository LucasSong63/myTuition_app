import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../../config/theme/app_colors.dart';

class ChatInputField extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSend;
  final bool isLoading;
  final bool canSend;

  const ChatInputField({
    Key? key,
    required this.controller,
    required this.onSend,
    this.isLoading = false,
    this.canSend = true,
  }) : super(key: key);

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  void _onSendPressed() {
    if (_hasText && widget.canSend && !widget.isLoading) {
      widget.onSend(widget.controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(2.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.divider),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(3.h),
                  border: Border.all(color: AppColors.divider),
                ),
                child: TextField(
                  controller: widget.controller,
                  enabled: widget.canSend && !widget.isLoading,
                  maxLines: null,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: widget.canSend
                        ? 'Ask me anything...'
                        : 'Daily limit reached',
                    hintStyle: TextStyle(
                      color: AppColors.textLight,
                      fontSize: 15.sp,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 2.5.w,
                      vertical: 1.5.h,
                    ),
                    border: InputBorder.none,
                    suffixIcon: _hasText ? _buildClearButton() : null,
                  ),
                  onSubmitted: (value) => _onSendPressed(),
                ),
              ),
            ),
            SizedBox(width: 1.w),
            _buildSendButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildClearButton() {
    return IconButton(
      onPressed: () {
        widget.controller.clear();
        setState(() {
          _hasText = false;
        });
      },
      icon: Icon(
        Icons.clear,
        color: AppColors.textLight,
        size: 2.5.h,
      ),
    );
  }

  Widget _buildSendButton() {
    final canSend = _hasText && widget.canSend && !widget.isLoading;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: canSend ? AppColors.primaryBlue : AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(3.h),
        child: InkWell(
          onTap: canSend ? _onSendPressed : null,
          borderRadius: BorderRadius.circular(3.h),
          child: Container(
            width: 6.h,
            height: 6.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3.h),
            ),
            child: widget.isLoading
                ? Padding(
                    padding: EdgeInsets.all(1.5.h),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.white),
                    ),
                  )
                : Icon(
                    Icons.send,
                    color: canSend ? AppColors.white : AppColors.textLight,
                    size: 2.5.h,
                  ),
          ),
        ),
      ),
    );
  }
}
