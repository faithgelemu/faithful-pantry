"use strict";

importScripts(
  "https://www.gstatic.com/firebasejs/12.19.0/firebase-app-compat.js"
);

importScripts(
  "https://www.gstatic.com/firebasejs/12.19.0/firebase-messaging-compat.js"
);

firebase.initializeApp({
  apiKey: "AIzaSyCcb-f4FF-_ImIrsUz-IunWAYhpt94SB08",
  appId: "1:470078062338:web:ce117890bb7dec7ac78c1b",
  messagingSenderId: "470078062338",
  projectId: "faithful-pantry",
  authDomain: "faithful-pantry.firebaseapp.com",
  storageBucket: "faithful-pantry.firebasestorage.app"
});

// Firebase displays background messages containing a notification
// payload. Do not also call showNotification for those messages,
// because that could display the same notification twice.
firebase.messaging();