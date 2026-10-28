(() => {
  let libraryPromise = null;
  let recognitionBusy = false;

  function loadOcrLibrary() {
    if (globalThis.Tesseract) {
      return Promise.resolve(globalThis.Tesseract);
    }

    if (libraryPromise) {
      return libraryPromise;
    }

    libraryPromise = new Promise((resolve, reject) => {
      const script = document.createElement('script');

      script.src =
        'https://cdn.jsdelivr.net/npm/tesseract.js@6.0.1/dist/tesseract.min.js';

      script.onload = () => {
        if (globalThis.Tesseract) {
          resolve(globalThis.Tesseract);
        } else {
          script.remove();
          libraryPromise = null;
          reject(new Error('OCR library is unavailable.'));
        }
      };

      script.onerror = () => {
        script.remove();
        libraryPromise = null;
        reject(new Error('Unable to download the OCR library.'));
      };

      document.head.appendChild(script);
    });

    return libraryPromise;
  }

  globalThis.faithfulPantryReadLabel = async (bytes, mimeType) => {
    if (recognitionBusy) {
      throw new Error('Recognition is already running.');
    }

    if (!['image/jpeg', 'image/png'].includes(mimeType)) {
      throw new Error('Choose a JPG or PNG image.');
    }

    if (!bytes || bytes.byteLength === 0) {
      throw new Error('The image is empty.');
    }

    if (bytes.byteLength > 10 * 1024 * 1024) {
      throw new Error('Choose an image no larger than 10 MB.');
    }

    recognitionBusy = true;
    let worker = null;

    try {
      const tesseract = await loadOcrLibrary();
      const image = new Blob([bytes], { type: mimeType });

      worker = await tesseract.createWorker('eng', 1);

      const output = await worker.recognize(image);
      return output.data.text.trim();
    } finally {
      if (worker) {
        try {
          await worker.terminate();
        } catch (error) {
          console.warn('OCR cleanup failed:', error);
        }
      }

      recognitionBusy = false;
    }
  };
})();