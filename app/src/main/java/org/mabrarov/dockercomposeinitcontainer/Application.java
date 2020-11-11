package org.mabrarov.dockercomposeinitcontainer;

import lombok.val;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.web.filter.CommonsRequestLoggingFilter;

@SpringBootApplication
public class Application {

  public static void main(final String[] args) {
    setJavaTrustStoreFile();
    setJavaTrustStorePassword();
    SpringApplication.run(Application.class, args);
  }

  private static void setJavaTrustStoreFile() {
    val trustStoreFile = System.getenv("TRUST_STORE_FILE");
    if (trustStoreFile != null) {
      System.setProperty("javax.net.ssl.trustStore", trustStoreFile);
    }
  }

  private static void setJavaTrustStorePassword() {
    val trustStorePassword = System.getenv("TRUST_STORE_PASSWORD");
    if (trustStorePassword != null) {
      System.setProperty("javax.net.ssl.trustStorePassword", trustStorePassword);
    }
  }

  @Bean
  public CommonsRequestLoggingFilter requestLoggingFilter() {
    val filter = new CommonsRequestLoggingFilter();
    filter.setIncludeClientInfo(true);
    filter.setIncludeHeaders(true);
    filter.setIncludeQueryString(true);
    return filter;
  }
}
