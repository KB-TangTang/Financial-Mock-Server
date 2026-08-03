package com.financial.mockserver.dto;

import lombok.Data;

import java.math.BigDecimal;

/**
 * POST /codef/v1/account/balance 응답 data.
 */
@Data
public class CodefBalanceResponse {
    private Long accountId;
    private String institutionName;
    private BigDecimal balance;
    private BigDecimal availableAmount;
    private BigDecimal valuationAmount;
    private String currency;
    private String snapshotAt;
}
