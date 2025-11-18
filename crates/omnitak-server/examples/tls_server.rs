//! TLS TAK server example
//!
//! Starts a TAK server with TLS on port 8089, requiring client certificates
//!
//! Usage:
//!   # First generate certificates:
//!   ./scripts/generate_certs.sh
//!
//!   # Then run the TLS server:
//!   cargo run --example tls_server

use omnitak_server::{ServerConfig, TakServer, config::TlsConfig};
use std::path::PathBuf;
use tracing::info;
use tracing_subscriber::{fmt, prelude::*, EnvFilter};

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // Initialize logging
    tracing_subscriber::registry()
        .with(fmt::layer())
        .with(
            EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| EnvFilter::new("info,omnitak_server=debug")),
        )
        .init();

    info!("OmniTAK TLS Server - Secure TAK Server with Client Certificates");

    // Configure TLS
    let certs_dir = PathBuf::from("omnitak-server/certs");

    let tls_config = TlsConfig {
        cert_path: certs_dir.join("server-cert.pem"),
        key_path: certs_dir.join("server-key.pem"),
        ca_path: Some(certs_dir.join("ca-cert.pem")),
        require_client_cert: true,
    };

    // Create server configuration
    let config = ServerConfig {
        bind_address: "0.0.0.0".parse().unwrap(),
        tcp_port: 0, // Disable TCP
        tls_port: 8090,
        tls: Some(tls_config),
        debug: true,
        max_clients: 1000,
        client_timeout_secs: 300,
        marti_port: 0,
        data_package_dir: None,
    };

    info!("Starting TLS server on port {}", config.tls_port);
    info!("Client certificates REQUIRED");
    info!("Debug logging enabled - all CoT messages will be logged");
    info!("Press Ctrl+C to stop");

    // Create and start server
    let mut server = TakServer::new(config)?;
    server.start().await?;

    // Wait for Ctrl+C
    tokio::signal::ctrl_c().await?;

    info!("Shutting down...");
    server.stop().await?;

    // Print final statistics
    let stats = server.stats();
    info!("Final statistics:");
    info!("  Total messages routed: {}", stats.total_messages);
    info!("  Clients connected at shutdown: {}", stats.client_count);

    Ok(())
}
