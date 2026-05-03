const pam = require("authenticate-pam");

exports.authenticate = (user, pass) => {
    return new Promise((resolve) => {
        pam.authenticate(user, pass, (err) => {
            resolve(!err);
        });
    });
};
