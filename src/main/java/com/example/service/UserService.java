package com.example.service;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

@Service
public class UserService {
    private static final Logger logger = LoggerFactory.getLogger(UserService.class);
    
    private final List<String> users = Arrays.asList("user1", "user2", "user3", "admin", "guest");
    
    public List<String> getAllUsers() {
        logger.info("Fetching all users");
        // VULNERABILITY: No access control - anyone can see all users
        return users;
    }
    
    public String getUserById(String id) {
        logger.info("Fetching user with ID: {}", id);
        
        // VULNERABILITY 1: SQL Injection - constructing SQL with user input
        try {
            String sql = "SELECT * FROM users WHERE id = '" + id + "'";
            logger.info("Executing SQL: {}", sql); // VULNERABILITY: SQL query logging
            
            // Simulated SQL injection vulnerability
            if (id.contains("'") || id.contains("--") || id.contains("UNION")) {
                return "Database error: " + sql; // VULNERABILITY: Error message disclosure
            }
            
        } catch (Exception e) {
            // VULNERABILITY 2: Information disclosure through error messages
            logger.error("Database error for user ID {}: {}", id, e.getMessage());
            return "Database error: " + e.getMessage();
        }
        
        // VULNERABILITY 3: Path traversal simulation
        if (id.contains("../") || id.contains("..\\")) {
            return "File system access: " + id;
        }
        
        // VULNERABILITY 4: No input validation
        if (id.length() > 1000) {
            return "Buffer overflow simulation with ID: " + id;
        }
        
        Optional<String> user = users.stream()
                .filter(u -> u.equalsIgnoreCase(id))
                .findFirst();
        
        if (user.isPresent()) {
            return "User: " + user.get();
        } else {
            // VULNERABILITY 5: Information disclosure
            return "User with ID " + id + " not found. Available users: " + users.toString();
        }
    }
    
    public String getAdminPanel() {
        logger.info("Admin panel accessed");
        
        // VULNERABILITY 6: No authentication/authorization
        // Always returns sensitive information
        return "ADMIN PANEL ACCESS GRANTED! Database password: admin123, API Keys: secret-key-123";
    }
    
    // VULNERABILITY 7: Debug endpoint that shouldn't be in production
    public String getDebugInfo() {
        return "Debug Info: Database URL: jdbc:mysql://localhost:3306/app, " +
               "Admin credentials: admin/password123, " +
               "Server path: /opt/application/";
    }
}

class NotFoundException extends RuntimeException {
    public NotFoundException(String message) {
        super(message);
    }
}

class UnauthorizedException extends RuntimeException {
    public UnauthorizedException(String message) {
        super(message);
    }
}