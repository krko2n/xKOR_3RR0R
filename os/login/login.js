const readline = require("readline");
const pam = require("./pam");

console.clear();
console.log(`
 ███╗   ██╗ █████╗ ████████╗███████╗██████╗ 
 ████╗  ██║██╔══██╗╚══██╔══╝██╔════╝██╔══██╗
 ██╔██╗ ██║███████║   ██║   █████╗  ██████╔╝
 ██║╚██╗██║██╔══██║   ██║   ██╔══╝  ██╔══██╗
 ██║ ╚████║██║  ██║   ██║   ███████╗██║  ██║
 ╚═╝  ╚═══╝╚═╝  ╚═╝   ╚═╝   ╚══════╝╚═╝  ╚═╝
`);

console.log("xKOR_3RR0R Secure Login\n");

const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

rl.question("Username: ", (username) => {
    rl.stdoutMuted = true;
    rl.question("Password: ", async (password) => {
        rl.close();

        const ok = await pam.authenticate(username, password);
        if (!ok) {
            console.log("\nACCESS DENIED");
            process.exit(1);
        }

        console.log("\nACCESS GRANTED");
        console.log("Loading system...\n");

        require("child_process").execSync("/opt/xkor_3rr0r/os/loading/loading.sh", {stdio: "inherit"});
        require("child_process").execSync("startx /opt/xkor_3rr0r/os/xorg/xkor-session.sh", {stdio: "inherit"});
    });
});

rl._writeToOutput = function (stringToWrite) {
    if (rl.stdoutMuted) return;
    process.stdout.write(stringToWrite);
};
