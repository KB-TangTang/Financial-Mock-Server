package com.financial.mockserver.service.impl;

import com.financial.mockserver.dto.AccountListResponse;
import com.financial.mockserver.dto.AccountResponse;
import com.financial.mockserver.dto.ApiEnvelope;
import com.financial.mockserver.dto.DepositListResponse;
import com.financial.mockserver.dto.DepositResponse;
import com.financial.mockserver.dto.LoanListResponse;
import com.financial.mockserver.dto.LoanResponse;
import com.financial.mockserver.dto.PayMoneyListResponse;
import com.financial.mockserver.dto.PayMoneyResponse;
import com.financial.mockserver.dto.StockAssetResponse;
import com.financial.mockserver.dto.StockHoldingResponse;
import com.financial.mockserver.mapper.MockAssetMapper;
import com.financial.mockserver.service.MockAssetService;
import com.financial.mockserver.support.MockApiResult;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Collections;
import java.util.List;

@Service
public class MockAssetServiceImpl extends AbstractMockApiService implements MockAssetService {

    @Autowired
    private MockAssetMapper assetMapper;

    @Override
    public MockApiResult getBankAccounts(String scenarioKey, String scenarioOverride) {
        return respond("GET", "/api/v1/assets/accounts", scenarioKey, scenarioOverride, null,
                (ctx, traceId, timestamp) -> {
                    List<AccountResponse> accounts = assetMapper.findBankAccounts(ctx.getUser().getId());
                    AccountListResponse data = new AccountListResponse(accounts);
                    return ApiEnvelope.of("SUCCESS", "계좌 목록 조회 성공", data, traceId, timestamp);
                });
    }

    @Override
    public MockApiResult getDeposits(String scenarioKey, String scenarioOverride) {
        return respond("GET", "/api/v1/assets/deposits", scenarioKey, scenarioOverride, null,
                (ctx, traceId, timestamp) -> {
                    Long userId = ctx.getUser().getId();
                    List<DepositResponse> deposits = assetMapper.findDeposits(userId);
                    BigDecimal totalPrincipal = sum(deposits, DepositResponse::getPrincipal);
                    BigDecimal totalBalance = sum(deposits, DepositResponse::getBalance);
                    String lastSyncAt = deposits.isEmpty() ? null : assetMapper.findDepositLastSyncAt(userId);
                    DepositListResponse data = new DepositListResponse(
                            deposits, totalPrincipal, totalBalance, lastSyncAt);
                    return ApiEnvelope.of("SUCCESS", "Deposit assets fetched successfully", data, traceId, timestamp);
                });
    }

    @Override
    public MockApiResult getStocks(String scenarioKey, String scenarioOverride) {
        return respond("GET", "/api/v1/assets/stocks", scenarioKey, scenarioOverride, null,
                (ctx, traceId, timestamp) -> {
                    StockAssetResponse summary = assetMapper.findStockAccountSummary(ctx.getUser().getId());
                    StockAssetResponse data = (summary == null)
                            ? emptyStockAsset()
                            : withHoldingsAndTotals(summary);
                    return ApiEnvelope.of("SUCCESS", "주식 자산 조회 성공", data, traceId, timestamp);
                });
    }

    @Override
    public MockApiResult getLoans(String scenarioKey, String scenarioOverride) {
        return respond("GET", "/api/v1/assets/loans", scenarioKey, scenarioOverride, null,
                (ctx, traceId, timestamp) -> {
                    Long userId = ctx.getUser().getId();
                    List<LoanResponse> loans = assetMapper.findLoans(userId);
                    BigDecimal totalLoanAmount = sum(loans, LoanResponse::getLoanAmount);
                    BigDecimal totalBalance = sum(loans, LoanResponse::getBalance);
                    String lastSyncAt = loans.isEmpty() ? null : assetMapper.findLoanLastSyncAt(userId);
                    LoanListResponse data = new LoanListResponse(loans, totalLoanAmount, totalBalance, lastSyncAt);
                    return ApiEnvelope.of("SUCCESS", "대출 자산 조회 성공", data, traceId, timestamp);
                });
    }

    @Override
    public MockApiResult getPayMoney(String scenarioKey, String scenarioOverride) {
        return respond("GET", "/api/v1/assets/payMoney", scenarioKey, scenarioOverride, null,
                (ctx, traceId, timestamp) -> {
                    List<PayMoneyResponse> payMoney = assetMapper.findPayMoney(ctx.getUser().getId());
                    BigDecimal totalBalance = sum(payMoney, PayMoneyResponse::getBalance);
                    BigDecimal totalPointAmount = sum(payMoney, PayMoneyResponse::getPointAmount);
                    PayMoneyListResponse data = new PayMoneyListResponse(payMoney, totalBalance, totalPointAmount);
                    return ApiEnvelope.of("SUCCESS", "페이머니 조회 성공", data, traceId, timestamp);
                });
    }

    private StockAssetResponse withHoldingsAndTotals(StockAssetResponse summary) {
        List<StockHoldingResponse> holdings = assetMapper.findStockHoldings(summary.getAccountId());
        summary.setHoldings(holdings);
        summary.setTotalPurchaseAmount(sum(holdings, StockHoldingResponse::getPurchaseAmount));
        summary.setTotalMarketValue(sum(holdings, StockHoldingResponse::getMarketValue));
        summary.setTotalProfitLossAmount(sum(holdings, StockHoldingResponse::getProfitLossAmount));

        BigDecimal totalPurchase = summary.getTotalPurchaseAmount();
        if (totalPurchase.compareTo(BigDecimal.ZERO) == 0) {
            summary.setTotalProfitLossRate(BigDecimal.ZERO);
        } else {
            BigDecimal rate = summary.getTotalProfitLossAmount()
                    .multiply(BigDecimal.valueOf(100))
                    .divide(totalPurchase, 4, RoundingMode.HALF_UP);
            summary.setTotalProfitLossRate(rate);
        }
        return summary;
    }

    private StockAssetResponse emptyStockAsset() {
        return new StockAssetResponse(null, null, null, "KRW",
                BigDecimal.ZERO, BigDecimal.ZERO, BigDecimal.ZERO, BigDecimal.ZERO,
                Collections.emptyList(), null);
    }

    private <T> BigDecimal sum(List<T> items, java.util.function.Function<T, BigDecimal> extractor) {
        BigDecimal total = BigDecimal.ZERO;
        for (T item : items) {
            BigDecimal value = extractor.apply(item);
            if (value != null) {
                total = total.add(value);
            }
        }
        return total;
    }
}
