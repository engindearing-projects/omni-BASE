//! TAK Server Certificate Enrollment (Mobile)
//!
//! Implements certificate enrollment for TAK servers that require username/password
//! authentication before issuing client certificates.

use anyhow::{Context, Result, anyhow};
use base64::{Engine, prelude::BASE64_STANDARD};
use reqwest::Client;
use serde::{Deserialize, Serialize};
use std::time::Duration;
use tracing::{info, warn, debug};

use crate::CertBundle;

/// Certificate enrollment client for TAK servers
pub struct EnrollmentClient {
    client: Client,
}

/// Enrollment request parameters
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EnrollmentRequest {
    /// TAK server base URL (e.g., https://tak-server.example.com:8443)
    pub server_url: String,
    /// Username for authentication
    pub username: String,
    /// Password for authentication
    pub password: String,
    /// Optional: Certificate validity period in days (default: 365)
    pub validity_days: Option<u32>,
    /// Optional: Common name for the certificate (defaults to username)
    pub common_name: Option<String>,
}

/// Enrollment response containing the issued certificate bundle
#[derive(Debug)]
pub struct EnrollmentResponse {
    /// Certificate bundle ready for use
    pub certificate_bundle: CertBundle,
    /// Server information
    pub server_info: EnrollmentServerInfo,
    /// Expiration date of the certificate (ISO 8601)
    pub expires_at: Option<String>,
}

/// Server information from enrollment
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EnrollmentServerInfo {
    /// Server hostname
    pub hostname: String,
    /// Server port for TAK connections
    pub port: Option<u16>,
    /// Server description (if provided)
    pub description: Option<String>,
}

/// TAK Server enrollment response format (JSON)
#[derive(Debug, Deserialize)]
#[serde(untagged)]
enum TakEnrollmentResponse {
    /// Standard TAK Server response
    Standard {
        #[serde(rename = "clientCert")]
        client_cert: String,
        #[serde(rename = "clientKey")]
        client_key: String,
        #[serde(rename = "caCert")]
        ca_cert: Option<String>,
        #[serde(rename = "serverHost")]
        server_host: Option<String>,
        #[serde(rename = "serverPort")]
        server_port: Option<u16>,
        #[serde(rename = "expiresAt")]
        expires_at: Option<String>,
    },
}

impl Default for EnrollmentClient {
    fn default() -> Self {
        Self::new()
    }
}

impl EnrollmentClient {
    /// Create a new enrollment client with default settings
    pub fn new() -> Self {
        Self::with_timeout(Duration::from_secs(30))
    }

    /// Create a new enrollment client with custom timeout
    pub fn with_timeout(timeout: Duration) -> Self {
        let client = Client::builder()
            .timeout(timeout)
            .danger_accept_invalid_certs(true) // For self-signed TAK server certs
            .build()
            .expect("Failed to create HTTP client");

        Self { client }
    }

    /// Enroll and obtain a certificate from a TAK server
    pub async fn enroll(&self, request: &EnrollmentRequest) -> Result<EnrollmentResponse> {
        info!(
            "Starting certificate enrollment for user '{}' on server '{}'",
            request.username, request.server_url
        );

        // Try standard TAK Server endpoints
        let endpoints = vec![
            format!("{}/Marti/api/tls/signClient", request.server_url),
            format!("{}/Marti/api/tls/enrollment", request.server_url),
            format!("{}/api/cert/enroll", request.server_url),
        ];

        let mut last_error = None;

        for endpoint in &endpoints {
            debug!("Trying enrollment endpoint: {}", endpoint);

            match self.try_enroll_endpoint(endpoint, request).await {
                Ok(response) => {
                    info!("Certificate enrollment successful via {}", endpoint);
                    return Ok(response);
                }
                Err(e) => {
                    warn!("Enrollment failed at {}: {}", endpoint, e);
                    last_error = Some(e);
                }
            }
        }

        Err(last_error.unwrap_or_else(|| anyhow!("All enrollment endpoints failed")))
    }

    /// Try enrollment at a specific endpoint
    async fn try_enroll_endpoint(
        &self,
        endpoint: &str,
        request: &EnrollmentRequest,
    ) -> Result<EnrollmentResponse> {
        // Prepare request body
        let mut body = serde_json::json!({
            "username": request.username,
            "password": request.password,
        });

        if let Some(days) = request.validity_days {
            body["validityDays"] = serde_json::json!(days);
        }

        if let Some(cn) = &request.common_name {
            body["commonName"] = serde_json::json!(cn);
        }

        // Send enrollment request
        let response = self
            .client
            .post(endpoint)
            .basic_auth(&request.username, Some(&request.password))
            .json(&body)
            .send()
            .await
            .context("Failed to send enrollment request")?;

        let status = response.status();

        if !status.is_success() {
            let error_text = response.text().await.unwrap_or_else(|_| String::from("Unknown error"));

            if status.as_u16() == 401 || status.as_u16() == 403 {
                return Err(anyhow!(
                    "Authentication failed: Invalid username or password ({})",
                    status
                ));
            }

            return Err(anyhow!(
                "Enrollment request failed with status {}: {}",
                status,
                error_text
            ));
        }

        // Parse response
        let tak_response: TakEnrollmentResponse = response
            .json()
            .await
            .context("Failed to parse enrollment response")?;

        // Convert to certificate bundle
        self.parse_enrollment_response(tak_response, &request.server_url)
    }

    /// Parse TAK enrollment response into certificate bundle
    fn parse_enrollment_response(
        &self,
        response: TakEnrollmentResponse,
        server_url: &str,
    ) -> Result<EnrollmentResponse> {
        match response {
            TakEnrollmentResponse::Standard {
                client_cert,
                client_key,
                ca_cert,
                server_host,
                server_port,
                expires_at,
            } => {
                info!("Parsing PEM certificate response");

                // Decode base64 if needed, or use as-is if already PEM
                let cert_pem = if client_cert.starts_with("-----BEGIN") {
                    client_cert
                } else {
                    String::from_utf8(
                        BASE64_STANDARD
                            .decode(&client_cert)
                            .context("Failed to decode client certificate")?,
                    )?
                };

                let key_pem = if client_key.starts_with("-----BEGIN") {
                    client_key
                } else {
                    String::from_utf8(
                        BASE64_STANDARD
                            .decode(&client_key)
                            .context("Failed to decode private key")?,
                    )?
                };

                let ca_pem = if let Some(ca) = ca_cert {
                    if ca.starts_with("-----BEGIN") {
                        Some(ca)
                    } else {
                        Some(String::from_utf8(
                            BASE64_STANDARD
                                .decode(&ca)
                                .context("Failed to decode CA certificate")?,
                        )?)
                    }
                } else {
                    None
                };

                let certificate_bundle = CertBundle::new(
                    Some(cert_pem),
                    Some(key_pem),
                    ca_pem,
                );

                let hostname = server_host.unwrap_or_else(|| {
                    // Extract hostname from server URL
                    server_url
                        .split("://")
                        .nth(1)
                        .and_then(|s| s.split(':').next())
                        .unwrap_or("unknown")
                        .to_string()
                });

                Ok(EnrollmentResponse {
                    certificate_bundle,
                    server_info: EnrollmentServerInfo {
                        hostname,
                        port: server_port,
                        description: None,
                    },
                    expires_at,
                })
            }
        }
    }

    /// Test connectivity to a TAK server's enrollment endpoint
    ///
    /// Returns `true` if the endpoint is reachable and responds
    pub async fn test_endpoint(&self, server_url: &str) -> bool {
        let endpoints = vec![
            format!("{}/Marti/api/tls/signClient", server_url),
            format!("{}/Marti/api/tls/enrollment", server_url),
            format!("{}/api/cert/enroll", server_url),
        ];

        for endpoint in endpoints {
            if let Ok(response) = self.client.get(&endpoint).send().await {
                // We expect 401 Unauthorized or similar, which means endpoint exists
                let status = response.status();
                if status.as_u16() == 401 || status.as_u16() == 405 || status.is_success() {
                    info!("Enrollment endpoint found: {}", endpoint);
                    return true;
                }
            }
        }

        false
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_enrollment_request_serialization() {
        let request = EnrollmentRequest {
            server_url: "https://tak-server.example.com:8443".to_string(),
            username: "testuser".to_string(),
            password: "testpass".to_string(),
            validity_days: Some(365),
            common_name: Some("Test User".to_string()),
        };

        let json = serde_json::to_string(&request).unwrap();
        let deserialized: EnrollmentRequest = serde_json::from_str(&json).unwrap();

        assert_eq!(request.server_url, deserialized.server_url);
        assert_eq!(request.username, deserialized.username);
        assert_eq!(request.validity_days, deserialized.validity_days);
    }

    #[tokio::test]
    async fn test_enrollment_client_creation() {
        let _client = EnrollmentClient::new();
        let _custom_client = EnrollmentClient::with_timeout(Duration::from_secs(60));
        // Both should create successfully without panicking
    }
}
