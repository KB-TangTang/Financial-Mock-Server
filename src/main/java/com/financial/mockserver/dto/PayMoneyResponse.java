package com.financial.mockserver.dto;

import lombok.Data;

import java.math.BigDecimal;

/**
 * GET /api/v1/assets/payMoney 응답의 페이머니 1건.
 */
@Data
public class PayMoneyResponse {
    private Long payMoneyId;
    private String providerCode;
    private String providerName;
    private String institutionName;
    private String walletName;
    private String currency;
    private BigDecimal balance;
    private BigDecimal availableAmount;
    private BigDecimal pointAmount;
    private String lastSyncAt;
}
