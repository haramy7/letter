package com.emotion.mailbox.core;

import com.emotion.mailbox.domain.*;
import com.emotion.mailbox.dto.*;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class MailboxService {
    private final UserRepository userRepository;
    private final LetterRepository letterRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtProvider jwtProvider;

    @Transactional
    public void register(String username, String password, String nickname) {
        userRepository.save(User.builder()
                .username(username)
                .password(passwordEncoder.encode(password))
                .nickname(nickname)
                .build());
    }

    public AuthResponse login(String username, String password) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        if (!passwordEncoder.matches(password, user.getPassword())) {
            throw new IllegalArgumentException("Invalid password");
        }
        return new AuthResponse(
                jwtProvider.createAccessToken(username),
                jwtProvider.createRefreshToken(username),
                user.getNickname()
        );
    }

    public AuthResponse refresh(String refreshToken) {
        if (!jwtProvider.validateToken(refreshToken)) throw new IllegalArgumentException("Invalid refresh token");
        String username = jwtProvider.getUsername(refreshToken);
        User user = userRepository.findByUsername(username).orElseThrow();
        return new AuthResponse(
                jwtProvider.createAccessToken(username),
                refreshToken, 
                user.getNickname()
        );
    }

    @Transactional
    public void writeLetter(String username, String content) {
        User user = userRepository.findByUsername(username).orElseThrow();
        LocalDate today = LocalDate.now();
        if (letterRepository.existsByUserAndTargetDate(user, today)) {
            throw new IllegalStateException("Already written today");
        }
        letterRepository.save(Letter.builder()
                .user(user)
                .content(content)
                .targetDate(today) 
                .createdAt(LocalDateTime.now())
                .build());
    }

    @Transactional(readOnly = true)
    public List<LetterDto> getLetters(String username) {
        User user = userRepository.findByUsername(username).orElseThrow();
        LocalDate today = LocalDate.now();
        return letterRepository.findAllByUserAndTargetDateLessThanEqualOrderByTargetDateDesc(user, today).stream()
                .map(l -> LetterDto.from(l.getId(), l.getContent(), l.getTargetDate(), l.getTargetDate().isBefore(today)))
                .toList();
    }
    
    @Transactional(readOnly = true)
    public boolean hasWrittenToday(String username) {
        User user = userRepository.findByUsername(username).orElseThrow();
        return letterRepository.existsByUserAndTargetDate(user, LocalDate.now());
    }
    
    @Transactional
    public void deleteLetter(String username, Long letterId) {
        User user = userRepository.findByUsername(username).orElseThrow();
        Letter letter = letterRepository.findById(letterId)
                .orElseThrow(() -> new IllegalArgumentException("Letter not found"));
        if (!letter.getUser().getId().equals(user.getId())) {
            throw new IllegalArgumentException("Not authorized to delete this letter");
        }
        letterRepository.delete(letter);
    }
}
