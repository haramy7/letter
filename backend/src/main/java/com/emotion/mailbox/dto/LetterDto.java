package com.emotion.mailbox.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;

public record LetterDto(
    Long id, 
    String content, 
    String date, 
    @JsonProperty("past") boolean isPast
) {
    public static LetterDto from(Long id, String content, LocalDate targetDate, boolean isPast) {
        return new LetterDto(
            id, 
            content, 
            targetDate.format(DateTimeFormatter.ISO_LOCAL_DATE), 
            isPast
        );
    }
}