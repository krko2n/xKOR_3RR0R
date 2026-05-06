document.querySelectorAll(".tab").forEach(tab => {
    tab.onclick = () => {
        document.querySelectorAll(".tab").forEach(t => t.classList.remove("active"));
        tab.classList.add("active");

        const id = tab.dataset.tab;

        document.querySelectorAll(".terminal").forEach(t => t.style.display = "none");
        document.getElementById("web-panel").style.display = "none";

        if (id === "web") {
            document.getElementById("web-panel").style.display = "block";
        } else {
            document.getElementById(id).style.display = "block";
        }
    };
});
