package com.financial.mockserver.dto;

import lombok.Data;

import java.math.BigDecimal;

/**
 * GET /api/v1/transactions 응답의 거래내역 1건.
 * documents/IMPLEMENTATION_GUIDE.md "거래내역 구현 규칙"에 정의된 필드만 포함한다.
 */
@Data
public class TransactionResponse {
    private Long transactionId;
    private String accountType;
    private String accountName;
    private String institutionName;
    private String transactionAt;
    private String merchantName;
    private BigDecimal amount;
    private String direction;
    private BigDecimal balanceAfter;
}
