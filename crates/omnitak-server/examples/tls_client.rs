//! TLS TAK client example
//!
//! Connects to TLS TAK server with client certificate and sends test CoT
//!
//! Usage:
//!   cargo run --example tls_client

use rustls::{Certificate, PrivateKey, RootCertStore};
use rustls_pemfile::{certs, pkcs8_private_keys};
use std::fs::File;
use std::io::BufReader;
use std::path::PathBuf;
use std::sync::Arc;
use std::time::Duration;
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::TcpStream;
use tokio_rustls::TlsConnector;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("TLS TAK Client - Testing secure connection");

    let certs_dir = PathBuf::from("omnitak-server/certs");

    // Load CA certificate
    println!("Loading CA certificate...");
    let ca_file = File::open(certs_dir.join("ca-cert.pem"))?;
    let mut ca_reader = BufReader::new(ca_file);
    let ca_certs: Vec<_> = certs(&mut ca_reader)?.into_iter().map(Certificate).collect();

    let mut root_store = RootCertStore::empty();
    for cert in ca_certs {
        root_store.add(&cert)?;
    }

    // Load client certificate
    println!("Loading client certificate...");
    let cert_file = File::open(certs_dir.join("client-cert.pem"))?;
    let mut cert_reader = BufReader::new(cert_file);
    let client_certs: Vec<_> = certs(&mut cert_reader)?.into_iter().map(Certificate).collect();

    // Load client private key
    println!("Loading client private key...");
    let key_file = File::open(certs_dir.join("client-key.pem"))?;
    let mut key_reader = BufReader::new(key_file);
    let client_key = PrivateKey(pkcs8_private_keys(&mut key_reader)?[0].clone());

    // Build TLS config
    let config = rustls::ClientConfig::builder()
        .with_safe_defaults()
        .with_root_certificates(root_store)
        .with_client_auth_cert(client_certs, client_key)?;

    let connector = TlsConnector::from(Arc::new(config));

    // Connect to server
    println!("Connecting to localhost:8090...");
    let stream = TcpStream::connect("127.0.0.1:8090").await?;
    let domain = rustls::ServerName::try_from("localhost")?;

    println!("Performing TLS handshake...");
    let mut tls_stream = connector.connect(domain, stream).await?;
    println!("✓ TLS connection established!");

    // Send test CoT message
    let cot_xml = r#"<?xml version="1.0" encoding="UTF-8"?>
<event version="2.0" uid="tls-test-client" type="a-f-G-E-S" time="2025-11-18T22:00:00Z" start="2025-11-18T22:00:00Z" stale="2025-11-18T22:05:00Z" how="m-g">
    <point lat="37.7749" lon="-122.4194" hae="0" ce="9999999" le="9999999"/>
    <detail>
        <contact callsign="TLS-TEST-CLIENT"/>
    </detail>
</event>"#;

    println!("Sending CoT message via TLS...");
    tls_stream.write_all(cot_xml.as_bytes()).await?;
    tls_stream.flush().await?;
    println!("✓ CoT sent!");

    // Wait for broadcasts
    println!("Listening for broadcasts...");

    let mut buffer = vec![0u8; 8192];
    tokio::select! {
        result = tls_stream.read(&mut buffer) => {
            match result {
                Ok(n) if n > 0 => {
                    let response = String::from_utf8_lossy(&buffer[..n]);
                    println!("✓ Received broadcast via TLS:\n{}", response);
                }
                Ok(_) => println!("Connection closed by server"),
                Err(e) => eprintln!("Error reading: {}", e),
            }
        }
        _ = tokio::time::sleep(Duration::from_secs(5)) => {
            println!("No broadcasts received in 5 seconds");
        }
    }

    println!("✅ TLS test complete!");
    Ok(())
}
