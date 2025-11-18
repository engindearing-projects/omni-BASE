//! TLS support for TAK server

use crate::error::{Result, ServerError};
use rustls::server::AllowAnyAuthenticatedClient;
use rustls::{Certificate, PrivateKey, RootCertStore, ServerConfig as RustlsConfig};
use rustls_pemfile::{certs, pkcs8_private_keys, rsa_private_keys};
use std::fs::File;
use std::io::BufReader;
use std::path::Path;
use std::sync::Arc;
use tokio_rustls::TlsAcceptor;

/// Load TLS server configuration from PEM files
pub fn load_tls_config(
    cert_path: &Path,
    key_path: &Path,
    ca_path: Option<&Path>,
    require_client_cert: bool,
) -> Result<TlsAcceptor> {
    // Load server certificate
    let cert_file = File::open(cert_path).map_err(|e| {
        ServerError::Certificate(format!("Failed to open cert file {}: {}", cert_path.display(), e))
    })?;
    let mut cert_reader = BufReader::new(cert_file);

    let certs: Vec<Certificate> = certs(&mut cert_reader)
        .map_err(|e| ServerError::Certificate(format!("Failed to parse certificates: {}", e)))?
        .into_iter()
        .map(Certificate)
        .collect();

    if certs.is_empty() {
        return Err(ServerError::Certificate("No certificates found in cert file".into()));
    }

    // Load private key
    let key_file = File::open(key_path).map_err(|e| {
        ServerError::Certificate(format!("Failed to open key file {}: {}", key_path.display(), e))
    })?;
    let mut key_reader = BufReader::new(key_file);

    // Try PKCS8 first, then RSA
    let keys = pkcs8_private_keys(&mut key_reader)
        .map_err(|e| ServerError::Certificate(format!("Failed to parse PKCS8 key: {}", e)))?;

    let key = if !keys.is_empty() {
        PrivateKey(keys[0].clone())
    } else {
        // Try RSA format
        let key_file = File::open(key_path)?;
        let mut key_reader = BufReader::new(key_file);
        let keys = rsa_private_keys(&mut key_reader)
            .map_err(|e| ServerError::Certificate(format!("Failed to parse RSA key: {}", e)))?;

        if keys.is_empty() {
            return Err(ServerError::Certificate("No private keys found in key file".into()));
        }
        PrivateKey(keys[0].clone())
    };

    // Build TLS config
    let mut config = if let Some(ca_path) = ca_path {
        if require_client_cert {
            // Load CA certificate for client verification
            let ca_file = File::open(ca_path).map_err(|e| {
                ServerError::Certificate(format!("Failed to open CA file {}: {}", ca_path.display(), e))
            })?;
            let mut ca_reader = BufReader::new(ca_file);

            let ca_certs: Vec<Certificate> = rustls_pemfile::certs(&mut ca_reader)
                .map_err(|e| ServerError::Certificate(format!("Failed to parse CA certificates: {}", e)))?
                .into_iter()
                .map(Certificate)
                .collect();

            if ca_certs.is_empty() {
                return Err(ServerError::Certificate("No CA certificates found".into()));
            }

            // Create root cert store
            let mut root_store = RootCertStore::empty();
            for cert in ca_certs {
                root_store.add(&cert).map_err(|e| {
                    ServerError::Certificate(format!("Failed to add CA cert to store: {}", e))
                })?;
            }

            // Use built-in verifier
            let verifier = AllowAnyAuthenticatedClient::new(root_store);

            RustlsConfig::builder()
                .with_safe_defaults()
                .with_client_cert_verifier(Arc::new(verifier))
                .with_single_cert(certs, key)
                .map_err(|e| ServerError::Tls(format!("Failed to build TLS config: {}", e)))?
        } else {
            // No client authentication required
            RustlsConfig::builder()
                .with_safe_defaults()
                .with_no_client_auth()
                .with_single_cert(certs, key)
                .map_err(|e| ServerError::Tls(format!("Failed to build TLS config: {}", e)))?
        }
    } else {
        // No client authentication
        RustlsConfig::builder()
            .with_safe_defaults()
            .with_no_client_auth()
            .with_single_cert(certs, key)
            .map_err(|e| ServerError::Tls(format!("Failed to build TLS config: {}", e)))?
    };

    // Set ALPN protocols (optional, for future HTTP/2 support)
    config.alpn_protocols = vec![b"h2".to_vec(), b"http/1.1".to_vec()];

    Ok(TlsAcceptor::from(Arc::new(config)))
}
