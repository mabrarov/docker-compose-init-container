package org.mabrarov.dockercomposeinitcontainer;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.cert.Certificate;
import java.security.cert.CertificateException;
import java.security.cert.CertificateFactory;
import java.security.cert.X509Certificate;
import java.util.Collection;
import java.util.regex.Pattern;
import lombok.extern.slf4j.Slf4j;
import lombok.val;

@Slf4j
public class TrustStoreBuilder {

  private static final String TRUST_STORE_TYPE = "JKS";
  private static final Pattern CA_STORE_FILE_PATTERN = Pattern
      .compile("CA_STORE([a-zA-Z0-9_]*)_FILE");
  private static final String CA_STORE_PASSWORD_VARIABLE_NAME_PREFIX = "CA_STORE";
  private static final Pattern CA_BUNDLE_FILE_PATTERN = Pattern
      .compile("CA_BUNDLE[a-zA-Z0-9_]*_FILE");
  private static final String TRUST_STORE_FILE_NAME_PREFIX = "trustStore";
  private static final String TRUST_STORE_FILE_NAME_SUFFIX = "." + TRUST_STORE_TYPE.toLowerCase();
  private static final String CA_BUNDLE_TYPE = "X.509";

  public static String buildTrustStore(final String password)
      throws KeyStoreException, IOException, CertificateException, NoSuchAlgorithmException {
    val trustStore = buildEmptyKeyStore();
    importCaStores(trustStore);
    importCaBundles(trustStore);
    val trustStoreFile = File
        .createTempFile(TRUST_STORE_FILE_NAME_PREFIX, TRUST_STORE_FILE_NAME_SUFFIX);
    saveKeyStore(trustStore, trustStoreFile, password);
    return trustStoreFile.getAbsolutePath();
  }

  private static KeyStore buildEmptyKeyStore()
      throws KeyStoreException, CertificateException, NoSuchAlgorithmException, IOException {
    val keyStore = KeyStore.getInstance(TRUST_STORE_TYPE);
    keyStore.load(null, null);
    return keyStore;
  }

  private static void importCaStores(final KeyStore trustStore)
      throws KeyStoreException, IOException, NoSuchAlgorithmException, CertificateException {
    val environmentVariables = System.getenv();
    for (val environmentVariable : environmentVariables.entrySet()) {
      val keyStoreFileVariableName = environmentVariable.getKey();
      val keyStoreFileMatcher = CA_STORE_FILE_PATTERN.matcher(keyStoreFileVariableName);
      if (!keyStoreFileMatcher.matches()) {
        continue;
      }
      val keyStoreFile = environmentVariable.getValue();
      if (keyStoreFile == null || keyStoreFile.isEmpty()) {
        continue;
      }
      val keyStorePasswordVariableName =
          CA_STORE_PASSWORD_VARIABLE_NAME_PREFIX + keyStoreFileMatcher.group(1);
      val keyStorePassword = System.getenv(keyStorePasswordVariableName);
      log.info("Importing certificates from key store: {}", keyStoreFile);
      importCertificatesFromKeyStore(trustStore, keyStoreFile, keyStorePassword);
    }
  }

  private static void importCaBundles(final KeyStore trustStore)
      throws KeyStoreException, IOException, CertificateException {
    val environmentVariables = System.getenv();
    for (val environmentVariable : environmentVariables.entrySet()) {
      val bundleFileVariableName = environmentVariable.getKey();
      if (!CA_BUNDLE_FILE_PATTERN.matcher(bundleFileVariableName).matches()) {
        continue;
      }
      val bundleFile = environmentVariable.getValue();
      if (bundleFile == null || bundleFile.isEmpty()) {
        continue;
      }
      log.info("Importing certificates from bundle: {}", bundleFile);
      importCertificatesFromBundle(trustStore, bundleFile);
    }
  }

  private static void saveKeyStore(final KeyStore keyStore, final File file, final String password)
      throws IOException, CertificateException, NoSuchAlgorithmException, KeyStoreException {
    try (val outputStream = new FileOutputStream(file)) {
      keyStore.store(outputStream, toCharArray(password));
    }
  }

  private static KeyStore loadKeyStore(final String file, String password)
      throws KeyStoreException, IOException, NoSuchAlgorithmException, CertificateException {
    val keyStore = KeyStore.getInstance(TRUST_STORE_TYPE);
    try (val keyStoreInputStream = new FileInputStream(file)) {
      keyStore.load(keyStoreInputStream, toCharArray(password));
    }
    return keyStore;
  }

  private static void importCertificatesFromKeyStore(final KeyStore trustStore,
      final String keyStoreFile, final String keyStorePassword)
      throws KeyStoreException, IOException, NoSuchAlgorithmException, CertificateException {
    val keyStore = loadKeyStore(keyStoreFile, keyStorePassword);
    val aliases = keyStore.aliases();
    while (aliases.hasMoreElements()) {
      val alias = aliases.nextElement();
      if (!keyStore.isCertificateEntry(alias)) {
        continue;
      }
      log.info("Importing certificate. Source: {}. Certificate alias: {}", keyStoreFile, alias);
      val certificate = keyStore.getCertificate(alias);
      trustStore.setCertificateEntry(alias, certificate);
    }
  }

  private static void importCertificatesFromBundle(final KeyStore trustStore, final String file)
      throws KeyStoreException, IOException, CertificateException {
    val certificates = loadCertificates(file);
    for (val certificate : certificates) {
      val x509Certificate = (X509Certificate) certificate;
      val principal = x509Certificate.getSubjectX500Principal();
      val alias = principal.getName("RFC2253");
      log.info("Importing certificate. Source: {}. Certificate alias: {}", file, alias);
      trustStore.setCertificateEntry(alias, certificate);
    }
  }

  private static Collection<? extends Certificate> loadCertificates(final String file)
      throws CertificateException, IOException {
    val certificateFactory = CertificateFactory.getInstance(CA_BUNDLE_TYPE);
    try (val bundleInputStream = new FileInputStream(file)) {
      return certificateFactory.generateCertificates(bundleInputStream);
    }
  }

  private static char[] toCharArray(final String string) {
    return string == null ? null : string.toCharArray();
  }

}
