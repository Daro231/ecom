package com.ecom.service;

import com.ecom.common.exception.ConflictException;
import com.ecom.common.exception.UnauthorizedException;
import com.ecom.model.entity.User;
import com.ecom.model.enumerate.Role;
import com.ecom.model.request.LoginRequest;
import com.ecom.model.request.RegisterRequest;
import com.ecom.model.response.AuthResponse;
import com.ecom.repository.UserRepository;
import com.ecom.security.JwtService;
import com.ecom.service.impl.AuthServiceImpl;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {
    @Mock
    UserRepository userRepository;
    @Mock
    PasswordEncoder passwordEncoder;
    @Mock
    JwtService jwtService;
    @InjectMocks
    AuthServiceImpl authService;

    @Test
    void registerWithDuplicateEmailIsRejected() {
        when(userRepository.existsByEmail("dup@test.com")).thenReturn(true);

        assertThatThrownBy(() -> authService.register(new RegisterRequest("Dup", "dup@test.com", "Passw0rd!", null)))
                .isInstanceOf(ConflictException.class);
        verify(userRepository, never()).save(any());
    }

    @Test
    void registerCreatesCustomerWithEncodedPassword() {
        when(userRepository.existsByEmail("new@test.com")).thenReturn(false);
        when(passwordEncoder.encode("Passw0rd!")).thenReturn("encoded");
        when(userRepository.save(any(User.class))).thenAnswer(inv -> inv.getArgument(0));
        when(jwtService.generateToken(any(User.class))).thenReturn("jwt-token");

        AuthResponse response = authService.register(new RegisterRequest("New", " New@Test.com ", "Passw0rd!", "012"));

        assertThat(response.accessToken()).isEqualTo("jwt-token");
        assertThat(response.user().email()).isEqualTo("new@test.com");
        assertThat(response.user().role()).isEqualTo(Role.CUSTOMER);
    }

    @Test
    void loginWithWrongPasswordIsUnauthorized() {
        User user = TestData.user(1);
        when(userRepository.findByEmail("user1@test.com")).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("wrong", "hash")).thenReturn(false);

        assertThatThrownBy(() -> authService.login(new LoginRequest("user1@test.com", "wrong")))
                .isInstanceOf(UnauthorizedException.class);
    }

    @Test
    void loginWithUnknownEmailIsUnauthorized() {
        when(userRepository.findByEmail("nobody@test.com")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> authService.login(new LoginRequest("nobody@test.com", "x")))
                .isInstanceOf(UnauthorizedException.class);
    }

    @Test
    void loginWithDisabledAccountIsUnauthorized() {
        User user = TestData.user(1);
        user.setEnabled(false);
        when(userRepository.findByEmail("user1@test.com")).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("ok", "hash")).thenReturn(true);

        assertThatThrownBy(() -> authService.login(new LoginRequest("user1@test.com", "ok")))
                .isInstanceOf(UnauthorizedException.class).hasMessageContaining("disabled");
    }

    @Test
    void loginSucceedsWithCorrectCredentials() {
        User user = TestData.user(1);
        when(userRepository.findByEmail("user1@test.com")).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("ok", "hash")).thenReturn(true);
        when(jwtService.generateToken(user)).thenReturn("jwt");

        assertThat(authService.login(new LoginRequest("user1@test.com", "ok")).accessToken()).isEqualTo("jwt");
    }
}
