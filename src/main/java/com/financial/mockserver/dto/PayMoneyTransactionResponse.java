package com.financial.mockserver.dto;

import lombok.Data;

import java.math.BigDecimal;

@Data
public class PayMoneyTransactionResponse {
    private Long transactionId;
    private Long payMoneyId;
    private String providerCode;
    private String providerName;
    private String institutionName;
    private String walletId;
    private String walletName;
    private String transactedAt;
    private String transTypeCode;
    private String transTypeName;
    private BigDecimal amount;
    private BigDecimal balanceAfter;
    private BigDecimal pointAmount;
    private BigDecimal pointBalanceAfter;
    private String merchantName;
    private String description;
    private String currency;
}
