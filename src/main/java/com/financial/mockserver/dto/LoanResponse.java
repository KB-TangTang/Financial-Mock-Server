package com.financial.mockserver.dto;

import lombok.Data;

import java.math.BigDecimal;

/**
 * GET /api/v1/assets/loans 응답의 대출 1건.
 */
@Data
public class LoanResponse {
    private Long loanId;
    private String bankName;
    private String loanName;
    private String loanType;
    private String currency;
    private BigDecimal loanAmount;
    private BigDecimal balance;
    private BigDecimal interestRate;
    private String startDate;
    private String maturityDate;
    private BigDecimal monthlyPayment;
    private String nextPaymentDate;
}
