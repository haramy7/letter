package com.emotion.mailbox.domain;

import org.springframework.data.jpa.repository.JpaRepository;
import java.time.LocalDate;
import java.util.List;

public interface LetterRepository extends JpaRepository<Letter, Long> {
    boolean existsByUserAndTargetDate(User user, LocalDate targetDate);
    List<Letter> findAllByUserAndTargetDateLessThanEqualOrderByTargetDateDesc(User user, LocalDate date);
}
