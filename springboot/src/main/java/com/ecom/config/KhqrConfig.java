package com.ecom.config;

import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;

@Configuration
@EnableConfigurationProperties({KhqrProperties.class, BakongProperties.class})
@EnableScheduling
public class KhqrConfig {
}
