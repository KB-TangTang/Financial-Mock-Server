package com.financial.mockserver.dto;

import lombok.Data;

import java.math.BigDecimal;

/**
 * GET /api/v1/assets/stocks 응답의 보유종목 1건.
 */
@Data
public class StockHoldingResponse {
    private String productCode;
    private String productName;
    private String marketCountry;
    private String currency;
    private BigDecimal quantity;
    private BigDecimal averagePurchasePrice;
    private BigDecimal lastPrice;
    private BigDecimal purchaseAmount;
    private BigDecimal marketValue;
    private BigDecimal profitLossAmount;
    private BigDecimal profitLossRate;

    public String getStockCode() {
        return productCode;
    }

    public void setStockCode(String stockCode) {
        this.productCode = stockCode;
    }

    public String getStockName() {
        return productName;
    }

    public void setStockName(String stockName) {
        this.productName = stockName;
    }
}
