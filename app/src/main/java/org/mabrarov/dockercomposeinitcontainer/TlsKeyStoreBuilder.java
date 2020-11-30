package org.mabrarov.dockercomposeinitcontainer;

import static java.nio.charset.StandardCharsets.US_ASCII;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.security.KeyFactory;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.PrivateKey;
import java.security.cert.Certificate;
import java.security.cert.CertificateException;
import java.security.cert.CertificateFactory;
import java.security.spec.InvalidKeySpecException;
import java.security.spec.PKCS8EncodedKeySpec;
import java.util.Base64;
import java.util.Collection;
import java.util.Collections;
import java.util.regex.Pattern;
import lombok.extern.slf4j.Slf4j;
import lombok.val;

@Slf4j
public class TlsKeyStoreBuilder {

  private static final String KEY_STORE_FILE_NAME_PREFIX = "keyStore";
  private static final String KEY_STORE_FILE_NAME_SUFFIX = ".jks";
  private static final String PRIVATE_KEY_TYPE = "RSA";
  private static final String CERTIFICATE_TYPE = "X.509";
  private static final Pattern PRIVATE_KEY_PATTERN = Pattern.compile(
      "-+BEGIN\\s+.*PRIVATE\\s+KEY[^-]*-+(\\s|\\r|\\n)*([A-Za-z0-9+/=\\r\\n]+)-+END\\s+.*PRIVATE\\s+KEY[^-]*-+");

  public static String buildKeyStore(final String privateKeyFile, final String certificateFile,
      final String caCertificateFile, final String keyStoreType, final String password,
      final String keyAlias)
      throws CertificateException, NoSuchAlgorithmException, KeyStoreException, IOException, InvalidKeySpecException {
    val keyStore = buildEmptyKeyStore(keyStoreType);
    val privateKey = loadPrivateKey(privateKeyFile);
    val certificate = loadCertificates(certificateFile);
    val caCertificate = loadCaCertificates(caCertificateFile);
    keyStore.setKeyEntry(keyAlias, privateKey, toCharArray(password),
        toArray(certificate, caCertificate));
    val keyStoreFile = File.createTempFile(KEY_STORE_FILE_NAME_PREFIX, KEY_STORE_FILE_NAME_SUFFIX);
    saveKeyStore(keyStore, keyStoreFile, password);
    return keyStoreFile.getAbsolutePath();
  }

  private static KeyStore buildEmptyKeyStore(String keyStoreType)
      throws KeyStoreException, CertificateException, NoSuchAlgorithmException, IOException {
    val keyStore = KeyStore.getInstance(keyStoreType);
    keyStore.load(null, null);
    return keyStore;
  }

  private static PrivateKey loadPrivateKey(final String file)
      throws IOException, NoSuchAlgorithmException, InvalidKeySpecException {
    log.info("Loading private key: {}", file);
    val matcher = PRIVATE_KEY_PATTERN.matcher(readFile(file));
    if (!matcher.find()) {
      throw new InvalidKeySpecException("Found no private key: " + file);
    }
    val encodedKey = base64Decode(matcher.group(1));
    val keySpec = new PKCS8EncodedKeySpec(encodedKey);
    val keyFactory = KeyFactory.getInstance(PRIVATE_KEY_TYPE);
    return keyFactory.generatePrivate(keySpec);
  }

  private static void saveKeyStore(final KeyStore keyStore, final File file, final String password)
      throws IOException, CertificateException, NoSuchAlgorithmException, KeyStoreException {
    try (val outputStream = new FileOutputStream(file)) {
      keyStore.store(outputStream, toCharArray(password));
    }
  }

  private static Collection<? extends Certificate> loadCertificates(final String file)
      throws CertificateException, IOException {
    log.info("Loading certificates: {}", file);
    val certificateFactory = CertificateFactory.getInstance(CERTIFICATE_TYPE);
    try (val bundleInputStream = new FileInputStream(file)) {
      return certificateFactory.generateCertificates(bundleInputStream);
    }
  }

  private static Collection<? extends Certificate> loadCaCertificates(final String file)
      throws CertificateException, IOException {
    if (file == null) {
      return Collections.emptyList();
    }
    return loadCertificates(file);
  }

  private static Certificate[] toArray(final Collection<? extends Certificate> certificates1,
      final Collection<? extends Certificate> certificates2) {
    val chain = new Certificate[certificates1.size() + certificates2.size()];
    int index = 0;
    for (val certificate : certificates1) {
      chain[index++] = certificate;
    }
    for (val certificate : certificates2) {
      chain[index++] = certificate;
    }
    return chain;
  }

  private static char[] toCharArray(final String string) {
    return string == null ? null : string.toCharArray();
  }

  private static byte[] base64Decode(String base64) {
    return Base64.getMimeDecoder().decode(base64.getBytes(US_ASCII));
  }

  private static String readFile(String file) throws IOException {
    val stringBuilder = new StringBuilder();
    try (val inputStream = new FileInputStream(file);
        val inputStreamReader = new InputStreamReader(inputStream, US_ASCII);
        val bufferedReader = new BufferedReader(inputStreamReader)) {
      stringBuilder.append(bufferedReader.readLine());
    }
    return stringBuilder.toString();
  }
}
