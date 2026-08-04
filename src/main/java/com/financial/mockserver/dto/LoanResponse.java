package com.financial.mockserver.dto;

import lombok.Data;

import java.math.BigDecimal;

/**
 * GET /api/v1/assets/loans 응답의 대출 1건.
 */
@Data
public class LoanResponse {
    private Long loanId;
    private String institutionCode;
    private String institutionName;
    private String productName;
    private String accountTypeCode;
    private String accountStatusCode;
    private String loanNoMasked;
    private String currency;
    private BigDecimal principal;
    private BigDecimal balance;
    private BigDecimal interestRate;
    private String repaymentMethodCode;
    private String startDate;
    private String maturityDate;
    private BigDecimal monthlyPayment;
    private String nextPaymentDate;

    public BigDecimal getLoanAmount() {
        return principal;
    }

    public void setLoanAmount(BigDecimal loanAmount) {
        this.principal = loanAmount;
    }
}
