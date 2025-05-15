// lib/features/payments/presentation/bloc/payment_info_bloc.dart

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mytuition/features/payments/domain/entities/payment_info.dart';
import 'package:mytuition/features/payments/domain/repositories/payment_info_repository.dart';

part 'payment_info_event.dart';

part 'payment_info_state.dart';

class PaymentInfoBloc extends Bloc<PaymentInfoEvent, PaymentInfoState> {
  final PaymentInfoRepository _paymentInfoRepository;

  PaymentInfoBloc({
    required PaymentInfoRepository paymentInfoRepository,
  })  : _paymentInfoRepository = paymentInfoRepository,
        super(PaymentInfoInitial()) {
    on<LoadPaymentInfoEvent>(_onLoadPaymentInfo);
    on<SavePaymentInfoEvent>(_onSavePaymentInfo);
    on<AddBankAccountEvent>(_onAddBankAccount);
    on<UpdateBankAccountEvent>(_onUpdateBankAccount);
    on<DeleteBankAccountEvent>(_onDeleteBankAccount);
    on<AddEWalletEvent>(_onAddEWallet);
    on<UpdateEWalletEvent>(_onUpdateEWallet);
    on<DeleteEWalletEvent>(_onDeleteEWallet);
    on<AddOtherMethodEvent>(_onAddOtherMethod);
    on<UpdateOtherMethodEvent>(_onUpdateOtherMethod);
    on<DeleteOtherMethodEvent>(_onDeleteOtherMethod);
    on<UpdateAdditionalInfoEvent>(_onUpdateAdditionalInfo);
  }

  Future<void> _onLoadPaymentInfo(
      LoadPaymentInfoEvent event, Emitter<PaymentInfoState> emit) async {
    emit(PaymentInfoLoading());
    try {
      final paymentInfo = await _paymentInfoRepository.getPaymentInfo();
      emit(PaymentInfoLoaded(paymentInfo: paymentInfo));
    } catch (e) {
      emit(PaymentInfoError(message: 'Failed to load payment information: $e'));
    }
  }

  Future<void> _onSavePaymentInfo(
      SavePaymentInfoEvent event, Emitter<PaymentInfoState> emit) async {
    emit(PaymentInfoLoading());
    try {
      await _paymentInfoRepository.savePaymentInfo(event.paymentInfo);
      emit(PaymentInfoSaved(
        message: 'Payment information saved successfully',
        paymentInfo: event.paymentInfo,
      ));
    } catch (e) {
      emit(PaymentInfoError(message: 'Failed to save payment information: $e'));
    }
  }

  Future<void> _onAddBankAccount(
      AddBankAccountEvent event, Emitter<PaymentInfoState> emit) async {
    emit(PaymentInfoLoading());
    try {
      await _paymentInfoRepository.addBankAccount(event.bankAccount);
      final updatedInfo = await _paymentInfoRepository.getPaymentInfo();
      emit(PaymentInfoSaved(
        message: 'Bank account added successfully',
        paymentInfo: updatedInfo,
      ));
    } catch (e) {
      emit(PaymentInfoError(message: 'Failed to add bank account: $e'));
    }
  }

  Future<void> _onUpdateBankAccount(
      UpdateBankAccountEvent event, Emitter<PaymentInfoState> emit) async {
    emit(PaymentInfoLoading());
    try {
      await _paymentInfoRepository.updateBankAccount(event.bankAccount);
      final updatedInfo = await _paymentInfoRepository.getPaymentInfo();
      emit(PaymentInfoSaved(
        message: 'Bank account updated successfully',
        paymentInfo: updatedInfo,
      ));
    } catch (e) {
      emit(PaymentInfoError(message: 'Failed to update bank account: $e'));
    }
  }

  Future<void> _onDeleteBankAccount(
      DeleteBankAccountEvent event, Emitter<PaymentInfoState> emit) async {
    emit(PaymentInfoLoading());
    try {
      await _paymentInfoRepository.deleteBankAccount(event.accountId);
      final updatedInfo = await _paymentInfoRepository.getPaymentInfo();
      emit(PaymentInfoSaved(
        message: 'Bank account deleted successfully',
        paymentInfo: updatedInfo,
      ));
    } catch (e) {
      emit(PaymentInfoError(message: 'Failed to delete bank account: $e'));
    }
  }

  Future<void> _onAddEWallet(
      AddEWalletEvent event, Emitter<PaymentInfoState> emit) async {
    emit(PaymentInfoLoading());
    try {
      await _paymentInfoRepository.addEWallet(event.eWallet);
      final updatedInfo = await _paymentInfoRepository.getPaymentInfo();
      emit(PaymentInfoSaved(
        message: 'E-wallet added successfully',
        paymentInfo: updatedInfo,
      ));
    } catch (e) {
      emit(PaymentInfoError(message: 'Failed to add e-wallet: $e'));
    }
  }

  Future<void> _onUpdateEWallet(
      UpdateEWalletEvent event, Emitter<PaymentInfoState> emit) async {
    emit(PaymentInfoLoading());
    try {
      await _paymentInfoRepository.updateEWallet(event.eWallet);
      final updatedInfo = await _paymentInfoRepository.getPaymentInfo();
      emit(PaymentInfoSaved(
        message: 'E-wallet updated successfully',
        paymentInfo: updatedInfo,
      ));
    } catch (e) {
      emit(PaymentInfoError(message: 'Failed to update e-wallet: $e'));
    }
  }

  Future<void> _onDeleteEWallet(
      DeleteEWalletEvent event, Emitter<PaymentInfoState> emit) async {
    emit(PaymentInfoLoading());
    try {
      await _paymentInfoRepository.deleteEWallet(event.walletId);
      final updatedInfo = await _paymentInfoRepository.getPaymentInfo();
      emit(PaymentInfoSaved(
        message: 'E-wallet deleted successfully',
        paymentInfo: updatedInfo,
      ));
    } catch (e) {
      emit(PaymentInfoError(message: 'Failed to delete e-wallet: $e'));
    }
  }

  Future<void> _onAddOtherMethod(
      AddOtherMethodEvent event, Emitter<PaymentInfoState> emit) async {
    emit(PaymentInfoLoading());
    try {
      await _paymentInfoRepository.addOtherMethod(event.method);
      final updatedInfo = await _paymentInfoRepository.getPaymentInfo();
      emit(PaymentInfoSaved(
        message: 'Payment method added successfully',
        paymentInfo: updatedInfo,
      ));
    } catch (e) {
      emit(PaymentInfoError(message: 'Failed to add payment method: $e'));
    }
  }

  Future<void> _onUpdateOtherMethod(
      UpdateOtherMethodEvent event, Emitter<PaymentInfoState> emit) async {
    emit(PaymentInfoLoading());
    try {
      await _paymentInfoRepository.updateOtherMethod(event.method);
      final updatedInfo = await _paymentInfoRepository.getPaymentInfo();
      emit(PaymentInfoSaved(
        message: 'Payment method updated successfully',
        paymentInfo: updatedInfo,
      ));
    } catch (e) {
      emit(PaymentInfoError(message: 'Failed to update payment method: $e'));
    }
  }

  Future<void> _onDeleteOtherMethod(
      DeleteOtherMethodEvent event, Emitter<PaymentInfoState> emit) async {
    emit(PaymentInfoLoading());
    try {
      await _paymentInfoRepository.deleteOtherMethod(event.methodId);
      final updatedInfo = await _paymentInfoRepository.getPaymentInfo();
      emit(PaymentInfoSaved(
        message: 'Payment method deleted successfully',
        paymentInfo: updatedInfo,
      ));
    } catch (e) {
      emit(PaymentInfoError(message: 'Failed to delete payment method: $e'));
    }
  }

  Future<void> _onUpdateAdditionalInfo(
      UpdateAdditionalInfoEvent event, Emitter<PaymentInfoState> emit) async {
    emit(PaymentInfoLoading());
    try {
      await _paymentInfoRepository.updateAdditionalInfo(event.additionalInfo);
      final updatedInfo = await _paymentInfoRepository.getPaymentInfo();
      emit(PaymentInfoSaved(
        message: 'Additional information updated successfully',
        paymentInfo: updatedInfo,
      ));
    } catch (e) {
      emit(PaymentInfoError(
          message: 'Failed to update additional information: $e'));
    }
  }
}
