package org.mabrarov.dockercomposeinitcontainer;

import java.io.IOException;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.cert.CertificateException;
import java.security.spec.InvalidKeySpecException;
import lombok.val;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.web.filter.CommonsRequestLoggingFilter;

@SpringBootApplication
public class Application {

  private static final String TRUST_STORE_PASSWORD_ENVIRONMENT_VARIABLE = "TRUST_STORE_PASSWORD";
  private static final String TLS_KEY_FILE_ENVIRONMENT_VARIABLE = "TLS_KEY_FILE";
  private static final String TLS_CERT_FILE_ENVIRONMENT_VARIABLE = "TLS_CERT_FILE";
  private static final String TLS_CA_CERT_FILE_ENVIRONMENT_VARIABLE = "TLS_CA_CERT_FILE";
  private static final String TLS_KEYSTORE_PASSWORD_ENVIRONMENT_VARIABLE = "TLS_KEY_STORE_PASSWORD";
  private static final String TLS_KEY_ALIAS_ENVIRONMENT_VARIABLE = "TLS_KEY_ALIAS";
  private static final String TLS_KEY_STORE_TYPE = "PKCS12";

  public static void main(final String[] args)
      throws CertificateException, NoSuchAlgorithmException, KeyStoreException, IOException, InvalidKeySpecException {
    configureJavaTrustStore();
    configureSpringBootTlsKeyStore();
    SpringApplication.run(Application.class, args);
  }

  private static void configureJavaTrustStore()
      throws KeyStoreException, IOException, CertificateException, NoSuchAlgorithmException {
    val confTrustStorePassword = System.getenv(TRUST_STORE_PASSWORD_ENVIRONMENT_VARIABLE);
    val trustStorePassword = confTrustStorePassword == null ? "changeit" : confTrustStorePassword;
    val trustStoreFile = TrustStoreBuilder.buildTrustStore(trustStorePassword);
    System.setProperty("javax.net.ssl.trustStore", trustStoreFile);
    System.setProperty("javax.net.ssl.trustStorePassword", trustStorePassword);
  }

  private static void configureSpringBootTlsKeyStore()
      throws InvalidKeySpecException, CertificateException, NoSuchAlgorithmException, KeyStoreException, IOException {
    val privateKeyFile = System.getenv(TLS_KEY_FILE_ENVIRONMENT_VARIABLE);
    if (privateKeyFile == null || privateKeyFile.isEmpty()) {
      return;
    }
    val certificateFile = System.getenv(TLS_CERT_FILE_ENVIRONMENT_VARIABLE);
    val caCertificateFile = System.getenv(TLS_CA_CERT_FILE_ENVIRONMENT_VARIABLE);
    val keyStorePassword = System.getenv(TLS_KEYSTORE_PASSWORD_ENVIRONMENT_VARIABLE);
    val keyAlias = System.getenv(TLS_KEY_ALIAS_ENVIRONMENT_VARIABLE);
    val keyStoreFile = TlsKeyStoreBuilder
        .buildKeyStore(privateKeyFile, certificateFile, caCertificateFile, TLS_KEY_STORE_TYPE,
            keyStorePassword, keyAlias);
    System.setProperty("server.ssl.enabled", "true");
    System.setProperty("server.ssl.key-store", keyStoreFile);
    System.setProperty("server.ssl.key-store-type", TLS_KEY_STORE_TYPE);
    System.setProperty("server.ssl.key-store-password", keyStorePassword);
    System.setProperty("server.ssl.key-alias", keyAlias);
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
