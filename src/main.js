// @summary: Electron entry point. Creates fullscreen BrowserWindow, starts backend.
const { app, BrowserWindow } = require("electron");
const path = require("path");

let mainWindow;

function createWindow() {
    mainWindow = new BrowserWindow({
        width: 1920,
        height: 1080,
        fullscreen: true,
        frame: false,
        backgroundColor: "#000000",
        webPreferences: {
            preload: path.join(__dirname, "preload.js"),
            nodeIntegration: false,
            contextIsolation: true,
            devTools: true
        }
    });

    mainWindow.loadFile(path.join(__dirname, "renderer/index.html"));
}

app.whenReady().then(() => {
    // Start backend FIRST
    try {
        const backend = require("../backend/server");
        backend.on("ready", () => {
            console.log("[MAIN] Backend ready");
        });
    } catch (err) {
        console.error("[MAIN] Backend failed:", err.message);
    }

    createWindow();
});
