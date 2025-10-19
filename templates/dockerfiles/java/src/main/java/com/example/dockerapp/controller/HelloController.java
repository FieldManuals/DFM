package com.example.dockerapp.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import java.util.HashMap;
import java.util.Map;

@RestController
public class HelloController {

    @GetMapping("/")
    public Map<String, String> hello() {
        Map<String, String> response = new HashMap<>();
        response.put("message", "Java Docker Template");
        response.put("java_version", System.getProperty("java.version"));
        response.put("environment", System.getenv().getOrDefault("ENVIRONMENT", "development"));
        return response;
    }
}
