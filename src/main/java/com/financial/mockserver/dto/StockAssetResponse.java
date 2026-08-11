package com.financial.mockserver.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

/**
 * GET /api/v1/assets/stocks 응답 data.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class StockAssetResponse {
    private Long accountId;
    private String accountName;
    private String institutionName;
    private String currency;
    private BigDecimal cashBalance;
    private BigDecimal totalPurchaseAmount;
    private BigDecimal totalMarketValue;
    private BigDecimal totalProfitLossAmount;
    private BigDecimal totalProfitLossRate;
    private List<StockHoldingResponse> holdings;
    private String lastSyncAt;
}
