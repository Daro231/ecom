package com.ecom.service;

import com.ecom.model.entity.Notification;
import com.ecom.model.enumerate.NotificationType;

/** Delivers a stored notification through one channel (email, SMS, push). */
public interface NotificationSender {
    boolean supports(NotificationType type);

    void send(Notification notification);
}
