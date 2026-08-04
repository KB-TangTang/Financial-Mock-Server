package com.financial.mockserver.support;

import lombok.Getter;

/**
 * 컨트롤러가 그대로 응답으로 사용할 HTTP status + body 묶음.
 * body는 동적 조립 시 ApiEnvelope&lt;T&gt; 객체(Jackson이 직렬화)이거나,
 * fixture 반환 시 이미 완성된 JSON 문자열(response_json 원문)이다.
 */
@Getter
public class MockApiResult {
    private final int httpStatus;
    private final Object body;

    public MockApiResult(int httpStatus, Object body) {
        this.httpStatus = httpStatus;
        this.body = body;
    }
}
