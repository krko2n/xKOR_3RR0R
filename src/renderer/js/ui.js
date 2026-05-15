// @summary: Subscribes to backend stats events, updates graph data.
window.xkor.onBackend((data) => {
    if (data.type === "stats") {
        window.updateGraphs(data);
    }
});
