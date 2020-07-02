package org.mabrarov.dockercomposeinitcontainer;

import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Slf4j
@RestController
public class HelloController {

  @RequestMapping("/")
  public String greeting() {
    return "Hello, World!";
  }
}
