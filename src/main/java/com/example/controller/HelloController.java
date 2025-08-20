package com.example.controller;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.example.service.UserService;

@RestController
@RequestMapping("/api")
public class HelloController {
    @Autowired
    private UserService userService;

    @GetMapping("/users")
    public ResponseEntity<List<String>> getUsers() {
        return ResponseEntity.ok(userService.getAllUsers());
    }

    @GetMapping("/users/{id}")
    public ResponseEntity<String> getUser(@PathVariable String id) {
        return ResponseEntity.ok(userService.getUserById(id));
    }

    @GetMapping("/admin")
    public ResponseEntity<String> adminPanel() {
        return ResponseEntity.ok(userService.getAdminPanel());
    }
    
    // VULNERABILITY: Debug endpoint exposed
    @GetMapping("/debug")
    public ResponseEntity<String> debugInfo() {
        return ResponseEntity.ok(userService.getDebugInfo());
    }
    
    // VULNERABILITY: XSS vulnerability through query parameter
    @GetMapping("/search")
    public ResponseEntity<String> search(@RequestParam String query) {
        // No input sanitization
        return ResponseEntity.ok("<html><body>Search results for: " + query + "</body></html>");
    }

    // VULNERABILITY: Information disclosure in exception handler
    @ExceptionHandler(Exception.class)
    public ResponseEntity<String> handleException(Exception ex) {
        // Returns full stack trace
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body("Internal Error: " + ex.getMessage() + " - " + ex.getClass().getName());
    }
}