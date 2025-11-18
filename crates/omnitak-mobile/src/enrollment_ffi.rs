//! Certificate Enrollment FFI
//!
//! C-compatible FFI functions for TAK server certificate enrollment

use std::ffi::CStr;
use std::os::raw::{c_char, c_int};
use std::ptr;
use std::sync::Arc;
use parking_lot::Mutex;

use omnitak_cert::enrollment::{EnrollmentClient, EnrollmentRequest};

lazy_static::lazy_static! {
    static ref ENROLLMENT_CLIENT: Arc<Mutex<Option<Arc<EnrollmentClient>>>> = Arc::new(Mutex::new(None));
    static ref LAST_ENROLLMENT_RESULT: Arc<Mutex<Option<EnrollmentResult>>> = Arc::new(Mutex::new(None));
}

/// Result of enrollment operation
#[derive(Debug, Clone)]
struct EnrollmentResult {
    /// Client certificate PEM
    pub cert_pem: String,
    /// Client private key PEM
    pub key_pem: String,
    /// CA certificate PEM (optional)
    pub ca_pem: Option<String>,
    /// Server hostname
    pub server_host: String,
    /// Server port
    pub server_port: u16,
}

/// Initialize enrollment client
///
/// Must be called before any enrollment operations.
///
/// # Returns
/// 0 on success, -1 on error
#[no_mangle]
pub extern "C" fn omnitak_enrollment_init() -> c_int {
    let mut client = ENROLLMENT_CLIENT.lock();
    if client.is_none() {
        *client = Some(Arc::new(EnrollmentClient::new()));
        0
    } else {
        0 // Already initialized
    }
}

/// Enroll with a TAK server using username/password
///
/// This function is asynchronous and returns immediately.
/// The result can be retrieved using `omnitak_enrollment_get_result`.
///
/// # Parameters
/// - `server_url`: Null-terminated C string with server URL (e.g., "https://tak-server.example.com:8443")
/// - `username`: Null-terminated C string with username
/// - `password`: Null-terminated C string with password
/// - `validity_days`: Certificate validity in days (0 for default 365)
///
/// # Returns
/// 0 if enrollment started successfully, -1 on error
///
/// # Safety
/// All string pointers must be valid null-terminated C strings
#[no_mangle]
pub unsafe extern "C" fn omnitak_enroll(
    server_url: *const c_char,
    username: *const c_char,
    password: *const c_char,
    validity_days: u32,
) -> c_int {
    if server_url.is_null() || username.is_null() || password.is_null() {
        eprintln!("omnitak_enroll: null parameter");
        return -1;
    }

    let server_url_str = match CStr::from_ptr(server_url).to_str() {
        Ok(s) => s.to_string(),
        Err(e) => {
            eprintln!("omnitak_enroll: invalid server_url: {}", e);
            return -1;
        }
    };

    let username_str = match CStr::from_ptr(username).to_str() {
        Ok(s) => s.to_string(),
        Err(e) => {
            eprintln!("omnitak_enroll: invalid username: {}", e);
            return -1;
        }
    };

    let password_str = match CStr::from_ptr(password).to_str() {
        Ok(s) => s.to_string(),
        Err(e) => {
            eprintln!("omnitak_enroll: invalid password: {}", e);
            return -1;
        }
    };

    let client = {
        let client_lock = ENROLLMENT_CLIENT.lock();
        match client_lock.as_ref() {
            Some(c) => Arc::clone(c),
            None => {
                eprintln!("omnitak_enroll: enrollment client not initialized");
                return -1;
            }
        }
    };

    // Create enrollment request
    let request = EnrollmentRequest {
        server_url: server_url_str,
        username: username_str,
        password: password_str,
        validity_days: if validity_days == 0 {
            None
        } else {
            Some(validity_days)
        },
        common_name: None,
    };

    // Perform enrollment in background
    let result_store = Arc::clone(&LAST_ENROLLMENT_RESULT);
    std::thread::spawn(move || {
        let runtime = match tokio::runtime::Runtime::new() {
            Ok(r) => r,
            Err(e) => {
                eprintln!("Failed to create tokio runtime: {}", e);
                return;
            }
        };

        runtime.block_on(async {
            match client.enroll(&request).await {
                Ok(response) => {
                    let bundle = response.certificate_bundle;
                    let result = EnrollmentResult {
                        cert_pem: bundle.cert_pem.unwrap_or_default(),
                        key_pem: bundle.key_pem.unwrap_or_default(),
                        ca_pem: bundle.ca_pem,
                        server_host: response.server_info.hostname,
                        server_port: response.server_info.port.unwrap_or(8089),
                    };

                    let mut last_result = result_store.lock();
                    *last_result = Some(result);

                    println!("Enrollment successful");
                }
                Err(e) => {
                    eprintln!("Enrollment failed: {}", e);
                    let mut last_result = result_store.lock();
                    *last_result = None;
                }
            }
        });
    });

    0 // Started successfully
}

/// Get the result of the last enrollment operation
///
/// # Parameters
/// - `cert_pem_out`: Buffer to store certificate PEM (or null to skip)
/// - `cert_pem_len`: Length of cert_pem_out buffer
/// - `key_pem_out`: Buffer to store private key PEM (or null to skip)
/// - `key_pem_len`: Length of key_pem_out buffer
/// - `ca_pem_out`: Buffer to store CA certificate PEM (or null to skip)
/// - `ca_pem_len`: Length of ca_pem_out buffer
/// - `server_host_out`: Buffer to store server hostname (or null to skip)
/// - `server_host_len`: Length of server_host_out buffer
/// - `server_port_out`: Pointer to store server port (or null to skip)
///
/// # Returns
/// 1 if enrollment succeeded and result is available
/// 0 if enrollment is still in progress
/// -1 if enrollment failed or no enrollment was started
///
/// # Safety
/// All buffer pointers must be valid or null
/// Buffer lengths must match actual buffer sizes
#[no_mangle]
pub unsafe extern "C" fn omnitak_enrollment_get_result(
    cert_pem_out: *mut c_char,
    cert_pem_len: usize,
    key_pem_out: *mut c_char,
    key_pem_len: usize,
    ca_pem_out: *mut c_char,
    ca_pem_len: usize,
    server_host_out: *mut c_char,
    server_host_len: usize,
    server_port_out: *mut u16,
) -> c_int {
    let result_lock = LAST_ENROLLMENT_RESULT.lock();

    match result_lock.as_ref() {
        Some(result) => {
            // Copy certificate PEM
            if !cert_pem_out.is_null() && cert_pem_len > 0 {
                let bytes = result.cert_pem.as_bytes();
                let copy_len = bytes.len().min(cert_pem_len - 1);
                ptr::copy_nonoverlapping(bytes.as_ptr(), cert_pem_out as *mut u8, copy_len);
                *cert_pem_out.add(copy_len) = 0; // Null terminate
            }

            // Copy key PEM
            if !key_pem_out.is_null() && key_pem_len > 0 {
                let bytes = result.key_pem.as_bytes();
                let copy_len = bytes.len().min(key_pem_len - 1);
                ptr::copy_nonoverlapping(bytes.as_ptr(), key_pem_out as *mut u8, copy_len);
                *key_pem_out.add(copy_len) = 0; // Null terminate
            }

            // Copy CA PEM if available
            if !ca_pem_out.is_null() && ca_pem_len > 0 {
                if let Some(ca) = &result.ca_pem {
                    let bytes = ca.as_bytes();
                    let copy_len = bytes.len().min(ca_pem_len - 1);
                    ptr::copy_nonoverlapping(bytes.as_ptr(), ca_pem_out as *mut u8, copy_len);
                    *ca_pem_out.add(copy_len) = 0; // Null terminate
                } else {
                    *ca_pem_out = 0; // Empty string
                }
            }

            // Copy server host
            if !server_host_out.is_null() && server_host_len > 0 {
                let bytes = result.server_host.as_bytes();
                let copy_len = bytes.len().min(server_host_len - 1);
                ptr::copy_nonoverlapping(bytes.as_ptr(), server_host_out as *mut u8, copy_len);
                *server_host_out.add(copy_len) = 0; // Null terminate
            }

            // Copy server port
            if !server_port_out.is_null() {
                *server_port_out = result.server_port;
            }

            1 // Success
        }
        None => -1, // Failed or not started
    }
}

/// Clear the last enrollment result
#[no_mangle]
pub extern "C" fn omnitak_enrollment_clear_result() {
    let mut result = LAST_ENROLLMENT_RESULT.lock();
    *result = None;
}
