import React from 'react';
import { createRoot } from 'react-dom/client';
import App from './App.jsx';
import './styles.css';

createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
);

if ('serviceWorker' in navigator && import.meta.env.PROD) {
  window.addEventListener('load', () => {
    // The worker ships from public/, so it resolves against the page, not this bundle.
    navigator.serviceWorker.register(new URL('sw.js', window.location.href).href, { scope: './' }).catch(() => {
      // An unregistered service worker costs offline support and nothing else; the app still runs.
    });
  });
}
