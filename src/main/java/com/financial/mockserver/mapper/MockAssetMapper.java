package com.financial.mockserver.mapper;

import com.financial.mockserver.dto.AccountResponse;
import com.financial.mockserver.dto.CodefBalanceResponse;
import com.financial.mockserver.dto.DepositResponse;
import com.financial.mockserver.dto.LoanResponse;
import com.financial.mockserver.dto.PayMoneyResponse;
import com.financial.mockserver.dto.StockAssetResponse;
import com.financial.mockserver.dto.StockHoldingResponse;
import org.apache.ibatis.annotations.Param;

import java.util.List;

public interface MockAssetMapper {
    List<AccountResponse> findBankAccounts(@Param("userId") Long userId);

    List<DepositResponse> findDeposits(@Param("userId") Long userId);

    String findDepositLastSyncAt(@Param("userId") Long userId);

    StockAssetResponse findStockAccountSummary(@Param("userId") Long userId);

    List<StockHoldingResponse> findStockHoldings(@Param("accountId") Long accountId);

    List<LoanResponse> findLoans(@Param("userId") Long userId);

    String findLoanLastSyncAt(@Param("userId") Long userId);

    List<PayMoneyResponse> findPayMoney(@Param("userId") Long userId);

    Long findAccountIdByMaskedNo(@Param("userId") Long userId, @Param("accountNoMasked") String accountNoMasked);

    Long findFirstDepositAccountId(@Param("userId") Long userId);

    CodefBalanceResponse findLatestBalance(@Param("accountId") Long accountId);
}
