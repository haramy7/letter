package com.emotion.mailbox.dto;

public record AuthResponse(String accessToken, String refreshToken, String nickname) {}
