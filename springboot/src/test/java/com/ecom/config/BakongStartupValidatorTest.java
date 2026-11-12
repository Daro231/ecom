package com.ecom.config;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class BakongStartupValidatorTest {

    private BakongStartupValidator validatorFor(String token, String accountId) {
        BakongProperties props = new BakongProperties();
        props.setToken(token);
        props.setAccountId(accountId);
        return new BakongStartupValidator(props);
    }

    @Test
    void missingTokenStopsStartupWithAClearMessage() {
        assertThatThrownBy(() -> validatorFor("", "shop@bank").validate())
                .isInstanceOf(IllegalStateException.class).hasMessageContaining("BAKONG_TOKEN");
        assertThatThrownBy(() -> validatorFor(null, "shop@bank").validate()).hasMessageContaining("BAKONG_TOKEN");
    }

    @Test
    void missingAccountIdStopsStartupWithAClearMessage() {
        assertThatThrownBy(() -> validatorFor("token", " ").validate())
                .isInstanceOf(IllegalStateException.class).hasMessageContaining("BAKONG_ACCOUNT_ID");
    }

    @Test
    void completeConfigurationPasses() {
        assertThatCode(() -> validatorFor("token", "shop@bank").validate()).doesNotThrowAnyException();
    }
}
