# Offline support

A custom service worker caches selected application files so the interface can launch offline. It does not cache Firebase records or external OCR resources, so authentication, cloud data access, editing and OCR are not guaranteed to work without a connection.

## Recorded checks

- Chrome loaded the interface after an offline refresh.
- The service worker registered and activated in Chrome.
- The installed iPhone app opened offline and its tabs remained usable.
- Saved groceries and budget information appeared again after reconnecting.

## Updating to a new release

When a new service worker is installed, it waits for existing controlled app windows to close before activating. To check a new release:

1. Close all app tabs and windows.
2. Reopen the app while online.
3. Allow the update to activate.

Release updates were checked in Chrome using worker activation and the updated page's release marker.

The offline asset list (`sw-assets.js`) must be regenerated after every release build. See [`deployment.md`](deployment.md).
