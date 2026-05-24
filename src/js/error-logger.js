// xKOR_3RR0R - Frontend Error Logger
// Captures uncaught exceptions, promise rejections, and fatal errors
// Sends them to Rust backend for logging and git auto-commit

(function() {
  'use strict';

  const ERROR_LOG_CHANNEL = 'log-error';
  const CRASH_LOG_CHANNEL = 'log-crash';

  // Detect if running in Tauri
  function isTauriAvailable() {
    return typeof window.__TAURI__ !== 'undefined' && window.__TAURI__.core;
  }

  // Log error to Rust backend
  async function logToBackend(channel, data) {
    if (!isTauriAvailable()) {
      console.warn('[ErrorLogger] Tauri not available, logging to console only');
      return;
    }

    try {
      await window.__TAURI__.core.invoke('log_frontend_error', {
        channel,
        timestamp: new Date().toISOString(),
        ...data
      });
    } catch (err) {
      console.error('[ErrorLogger] Failed to send error to backend:', err);
    }
  }

  // Format stack trace
  function formatStack(error) {
    if (error && error.stack) {
      return error.stack;
    }
    return 'No stack trace available';
  }

  // Global error handler
  window.addEventListener('error', function(event) {
    const errorData = {
      type: 'uncaught_exception',
      message: event.message || 'Unknown error',
      filename: event.filename || 'unknown',
      line: event.lineno || 0,
      column: event.colno || 0,
      stack: formatStack(event.error),
      url: window.location.href
    };

    console.error('[xKOR] Uncaught Exception:', errorData);
    logToBackend(ERROR_LOG_CHANNEL, errorData);

    // Don't prevent default - let error still show in console
    return false;
  });

  // Unhandled promise rejection handler
  window.addEventListener('unhandledrejection', function(event) {
    const errorData = {
      type: 'unhandled_rejection',
      message: event.reason?.message || String(event.reason) || 'Unknown rejection',
      stack: formatStack(event.reason),
      url: window.location.href
    };

    console.error('[xKOR] Unhandled Promise Rejection:', errorData);
    logToBackend(ERROR_LOG_CHANNEL, errorData);

    // Don't prevent default
    return false;
  });

  // Manual crash reporter
  window.reportCrash = function(type, message, additionalData = {}) {
    const crashData = {
      type: type || 'manual_crash',
      message: message || 'No message provided',
      stack: new Error().stack,
      url: window.location.href,
      userAgent: navigator.userAgent,
      timestamp: new Date().toISOString(),
      ...additionalData
    };

    console.error('[xKOR] CRASH REPORTED:', crashData);
    logToBackend(CRASH_LOG_CHANNEL, crashData);
  };

  // Log fatal errors with auto-commit
  window.reportFatal = function(message, error) {
    const fatalData = {
      type: 'fatal_error',
      message: message,
      stack: formatStack(error),
      url: window.location.href,
      state: {
        currentTab: window.xkor?.currentTab,
        bootTime: window.xkor?.bootTime,
        ready: window.xkor?.ready
      }
    };

    console.error('[xKOR] FATAL ERROR:', fatalData);
    logToBackend(CRASH_LOG_CHANNEL, fatalData);

    // Show user-facing error
    alert('xKOR Fatal Error\n\n' + message + '\n\nError logged. Please restart the application.');
  };

  console.log('[xKOR] Error logger initialized');
})();
