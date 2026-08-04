package com.financial.mockserver.dto;

import lombok.Data;

import java.math.BigDecimal;

/**
 * GET /api/v1/transactions 응답의 거래내역 1건.
 * documents/IMPLEMENTATION_GUIDE.md "거래내역 구현 규칙"에 정의된 필드만 포함한다.
 */
@Data
public class TransactionResponse {
    private String transactionId;
    private String sourceType;
    private Long sourceAccountId;
    private String institutionCode;
    private String institutionName;
    private String productCode;
    private String productName;
    private String accountNoMasked;
    private String transactionAt;
    private String transTypeCode;
    private String transTypeName;
    private String description;
    private String merchantName;
    private BigDecimal amount;
    private BigDecimal balanceAfter;
    private String currency;
}
