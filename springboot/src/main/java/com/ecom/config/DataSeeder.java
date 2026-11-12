package com.ecom.config;

import com.ecom.model.entity.Address;
import com.ecom.model.entity.User;
import com.ecom.model.enumerate.Role;
import com.ecom.repository.AddressRepository;
import com.ecom.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/** Creates the demo accounts for the dev profile (the catalog comes from V2__seed.sql). */
@Component
@Profile("dev")
@RequiredArgsConstructor
@Slf4j
public class DataSeeder implements CommandLineRunner {
    private final UserRepository userRepository;
    private final AddressRepository addressRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    @Transactional
    public void run(String... args) {
        createUser("Admin", "admin@ecom.com", "Admin@123", Role.ADMIN);
        createUser("Staff", "staff@ecom.com", "Staff@123", Role.STAFF);
        User customer = createUser("Demo Customer", "customer@ecom.com", "Customer@123", Role.CUSTOMER);
        if (customer != null) {
            addressRepository.save(Address.builder().user(customer).receiverName("Demo Customer").phone("012345678")
                    .line1("No. 12, Street 271, Toul Kork").city("Phnom Penh").isDefault(true).build());
        }
    }

    private User createUser(String name, String email, String password, Role role) {
        if (userRepository.existsByEmail(email)) {
            return null;
        }
        log.info("Seeding demo user {}", email);
        return userRepository.save(User.builder().fullName(name).email(email).phone("012345678")
                .password(passwordEncoder.encode(password)).role(role).enabled(true).build());
    }
}
