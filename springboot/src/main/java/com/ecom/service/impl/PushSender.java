package com.ecom.service.impl;

import com.ecom.model.entity.Notification;
import com.ecom.model.enumerate.NotificationType;
import com.ecom.service.NotificationSender;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

/** Placeholder channel: records the message in the log instead of contacting a real provider. */
@Component
@Slf4j
public class PushSender implements NotificationSender {
    @Override
    public boolean supports(NotificationType type) {
        return type == NotificationType.PUSH;
    }

    @Override
    public void send(Notification notification) {
        log.info("[push] to={} title=\"{}\" message=\"{}\"", notification.getUser().getEmail(), notification.getTitle(), notification.getMessage());
    }
}
