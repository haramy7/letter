package com.emotion.mailbox.core;

import com.emotion.mailbox.dto.LetterDto;
import com.emotion.mailbox.dto.LetterRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/letters")
@RequiredArgsConstructor
public class LetterController {
    private final MailboxService service;
    
    @PostMapping
    public void write(@RequestBody LetterRequest req) {
        String username = SecurityContextHolder.getContext().getAuthentication().getName();
        service.writeLetter(username, req.content());
    }
    
    @GetMapping
    public List<LetterDto> list() {
        String username = SecurityContextHolder.getContext().getAuthentication().getName();
        return service.getLetters(username);
    }
    
    @GetMapping("/today")
    public ResponseEntity<Boolean> checkToday() {
        String username = SecurityContextHolder.getContext().getAuthentication().getName();
        return ResponseEntity.ok(service.hasWrittenToday(username));
    }
    
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        String username = SecurityContextHolder.getContext().getAuthentication().getName();
        service.deleteLetter(username, id);
        return ResponseEntity.ok().build();
    }
}
