package com.emotion.mailbox.core;

import com.emotion.mailbox.dto.AuthRequest;
import com.emotion.mailbox.dto.AuthResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
public class AuthController {
    private final MailboxService service;
    
    @PostMapping("/signup")
    public void signup(@RequestBody AuthRequest req) {
        service.register(req.username(), req.password(), req.nickname());
    }
    
    @PostMapping("/login")
    public AuthResponse login(@RequestBody AuthRequest req) {
        return service.login(req.username(), req.password());
    }
    
    @PostMapping("/refresh")
    public AuthResponse refresh(@RequestHeader("RefreshToken") String token) {
        return service.refresh(token);
    }
}
