package org.mabrarov.dockercomposeinitcontainer;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class Main {

  public static void main(String[] args) {
    setJavaTrustStorePassword();
    SpringApplication.run(Main.class, args);
  }

  private static void setJavaTrustStorePassword() {
    final String trustStorePassword = System.getenv("TRUST_STORE_PASSWORD");
    if (trustStorePassword != null) {
      System.setProperty("javax.net.ssl.trustStorePassword", trustStorePassword);
    }
  }
}
