window.xkor.onBackend((data) => {
    if (data.type === "stats") {
        window.updateGraphs(data);
    }
});
