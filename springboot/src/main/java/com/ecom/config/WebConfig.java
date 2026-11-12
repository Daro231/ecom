package com.ecom.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.nio.file.Path;

@Configuration
public class WebConfig implements WebMvcConfigurer {
    private final Path uploadDir;

    public WebConfig(@Value("${app.upload-dir}") String uploadDir) {
        this.uploadDir = Path.of(uploadDir).toAbsolutePath().normalize();
    }

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        try {
            java.nio.file.Files.createDirectories(uploadDir);
        } catch (java.io.IOException ex) {
            throw new IllegalStateException("Cannot create upload directory " + uploadDir, ex);
        }
        String location = uploadDir.toUri().toString();
        registry.addResourceHandler("/uploads/**").addResourceLocations(location.endsWith("/") ? location : location + "/");
    }
}
