package com.financial.mockserver.mapper;

import com.financial.mockserver.dto.BankTransactionResponse;
import com.financial.mockserver.dto.CardApprovalResponse;
import com.financial.mockserver.dto.CardBillResponse;
import com.financial.mockserver.dto.CardResponse;
import com.financial.mockserver.dto.DepositTransactionResponse;
import org.apache.ibatis.annotations.Param;

import java.util.List;

public interface MockRawFinancialMapper {
    List<BankTransactionResponse> findBankTransactions(
            @Param("userId") Long userId,
            @Param("accountId") Long accountId,
            @Param("yearMonth") String yearMonth);

    List<CardResponse> findCards(@Param("userId") Long userId);

    List<CardApprovalResponse> findCardApprovals(
            @Param("userId") Long userId,
            @Param("cardId") Long cardId,
            @Param("yearMonth") String yearMonth);

    List<CardBillResponse> findCardBills(
            @Param("userId") Long userId,
            @Param("cardId") Long cardId,
            @Param("billingMonth") String billingMonth);

    List<DepositTransactionResponse> findDepositTransactions(
            @Param("userId") Long userId,
            @Param("depositAccountId") Long depositAccountId,
            @Param("yearMonth") String yearMonth);
}
