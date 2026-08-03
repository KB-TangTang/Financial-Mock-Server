package com.financial.mockserver.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * GET /api/v1/assets/accounts 응답 data.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class AccountListResponse {
    private List<AccountResponse> accounts;
}
