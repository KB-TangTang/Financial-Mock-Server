package com.financial.mockserver.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 모든 API 응답이 공통으로 따르는 envelope 구조.
 * README.md, documents/IMPLEMENTATION_GUIDE.md의 응답 규칙을 따른다.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ApiEnvelope<T> {
    private String code;
    private String message;
    private T data;
    private String traceId;
    private String timestamp;

    public static <T> ApiEnvelope<T> of(String code, String message, T data, String traceId, String timestamp) {
        return new ApiEnvelope<>(code, message, data, traceId, timestamp);
    }
}
