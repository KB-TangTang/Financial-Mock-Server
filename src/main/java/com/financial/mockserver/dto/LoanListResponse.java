package com.financial.mockserver.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

/**
 * GET /api/v1/assets/loans 응답 data.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class LoanListResponse {
    private List<LoanResponse> loans;
    private BigDecimal totalLoanAmount;
    private BigDecimal totalBalance;
    private String lastSyncAt;
}
