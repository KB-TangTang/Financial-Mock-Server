package com.financial.mockserver.dto;

import lombok.Data;

import java.math.BigDecimal;

@Data
public class DepositTransactionResponse {
    private Long transactionId;
    private Long depositAccountId;
    private String institutionCode;
    private String institutionName;
    private String accountNoMasked;
    private String productName;
    private String depositTypeCode;
    private String transactedAt;
    private String transTypeCode;
    private String transTypeName;
    private BigDecimal amount;
    private BigDecimal balanceAfter;
    private String description;
    private String currency;
}
