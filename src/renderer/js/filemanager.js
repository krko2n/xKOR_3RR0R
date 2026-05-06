/* ============================================================
   FILE MANAGER — xKOR_3RR0R
   - Click navigation
   - Context menu (rename, delete, copy, paste)
   - Drag & drop
   - Backend FS API integration
   ============================================================ */

let fmPath = ".";
let fmSelected = null;
let fmClipboard = null;

const fm = document.getElementById("filemanager");

/* ============================================================
   LOAD DIRECTORY
   ============================================================ */

async function loadDir(path = ".") {
    fmPath = path;

    const res = await fetch(`http://localhost:3001/fs/list?path=${path}`);
    const items = await res.json();

    fm.innerHTML = "";

    items.forEach(i => {
        const div = document.createElement("div");
        div.className = "fm-item";
        div.innerText = i.type === "dir" ? `[${i.name}]` : i.name;

        div.dataset.name = i.name;
        div.dataset.type = i.type;

        // Click to open
        div.onclick = () => {
            fmSelected = div;
            document.querySelectorAll(".fm-item").forEach(x => x.classList.remove("selected"));
            div.classList.add("selected");

            if (i.type === "dir") {
                loadDir(path + "/" + i.name);
            }
        };

        // Right-click context menu
        div.oncontextmenu = (e) => {
            e.preventDefault();
            fmSelected = div;
            showContextMenu(e.pageX, e.pageY);
        };

        // Drag start
        div.draggable = true;
        div.ondragstart = (e) => {
            fmClipboard = {
                type: "copy",
                path: `${fmPath}/${i.name}`
            };
        };

        fm.appendChild(div);
    });
}

loadDir();

/* ============================================================
   CONTEXT MENU
   ============================================================ */

const ctx = document.createElement("div");
ctx.id = "fm-context";
ctx.innerHTML = `
    <div id="fm-open">Open</div>
    <div id="fm-rename">Rename</div>
    <div id="fm-delete">Delete</div>
    <div id="fm-copy">Copy</div>
    <div id="fm-paste">Paste</div>
`;
document.body.appendChild(ctx);

function showContextMenu(x, y) {
    ctx.style.left = x + "px";
    ctx.style.top = y + "px";
    ctx.style.display = "block";
}

document.addEventListener("click", () => {
    ctx.style.display = "none";
});

/* ============================================================
   CONTEXT MENU ACTIONS
   ============================================================ */

document.getElementById("fm-open").onclick = () => {
    if (!fmSelected) return;
    const name = fmSelected.dataset.name;
    const type = fmSelected.dataset.type;

    if (type === "dir") loadDir(fmPath + "/" + name);
    else openFile(fmPath + "/" + name);
};

document.getElementById("fm-rename").onclick = async () => {
    if (!fmSelected) return;

    const oldName = fmSelected.dataset.name;
    const newName = prompt("New name:", oldName);
    if (!newName) return;

    await fetch("http://localhost:3001/fs/rename", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
            oldPath: `${fmPath}/${oldName}`,
            newPath: `${fmPath}/${newName}`
        })
    });

    loadDir(fmPath);
};

document.getElementById("fm-delete").onclick = async () => {
    if (!fmSelected) return;

    const name = fmSelected.dataset.name;
    const ok = confirm(`Delete ${name}?`);
    if (!ok) return;

    await fetch("http://localhost:3001/fs/delete", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ path: `${fmPath}/${name}` })
    });

    loadDir(fmPath);
};

document.getElementById("fm-copy").onclick = () => {
    if (!fmSelected) return;

    fmClipboard = {
        type: "copy",
        path: `${fmPath}/${fmSelected.dataset.name}`
    };
};

document.getElementById("fm-paste").onclick = async () => {
    if (!fmClipboard) return;

    const name = fmClipboard.path.split("/").pop();
    const newPath = `${fmPath}/${name}`;

    const content = await fetch(`http://localhost:3001/fs/read?path=${fmClipboard.path}`)
        .then(r => r.json());

    if (content.error) return;

    await fetch("http://localhost:3001/fs/write", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
            path: newPath,
            content: content.content
        })
    });

    loadDir(fmPath);
};

/* ============================================================
   OPEN FILE (DISPLAY IN TERMINAL)
   ============================================================ */

async function openFile(path) {
    const res = await fetch(`http://localhost:3001/fs/read?path=${path}`);
    const data = await res.json();

    if (data.error) return;

    // Send file content to terminal
    window.sendToTerminal(`cat "${path}"\r`);
}
