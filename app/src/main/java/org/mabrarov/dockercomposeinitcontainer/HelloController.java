package org.mabrarov.dockercomposeinitcontainer;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import lombok.extern.slf4j.Slf4j;
import lombok.val;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Slf4j
@RestController
public class HelloController {

  private final String greeting;

  public HelloController() {
    val configuredGreeting = readGreetingFromConfigFile();
    greeting = configuredGreeting == null ? "Hello, World!" : configuredGreeting;
  }

  @RequestMapping("/")
  public String greeting() {
    return greeting;
  }

  private static String readGreetingFromConfigFile() {
    val greetingFileName = System.getenv("GREETING_FILE");
    if (greetingFileName == null) {
      log.warn("Name of config file with greeting is not defined");
      return null;
    }
    val greetingFile = new File(greetingFileName);
    if (!greetingFile.exists()) {
      log.warn("Config file with greeting does not exist: {}", greetingFileName);
      return null;
    }
    try (val fileReader = new FileReader(greetingFile);
        val bufferedReader = new BufferedReader(fileReader)) {
      return bufferedReader.readLine();
    } catch (final IOException e) {
      log.error("Failed to read greeting from config file: {}", greetingFileName, e);
      return null;
    }
  }
}
