package org.mabrarov.dockercomposeinitcontainer;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloController {

  @RequestMapping("/")
  public String greeting() {
    return "Hello, World!";
  }
}
