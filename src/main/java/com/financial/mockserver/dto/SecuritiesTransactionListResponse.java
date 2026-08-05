package com.financial.mockserver.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class SecuritiesTransactionListResponse {
    private List<SecuritiesTransactionResponse> transactions;
}
