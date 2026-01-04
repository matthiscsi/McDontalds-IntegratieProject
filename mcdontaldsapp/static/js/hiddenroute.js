document.addEventListener("DOMContentLoaded", () => {
    let bigMacClicks = 0;
    const secretBigMac = document.getElementById("secret-bigmac");

    if (secretBigMac) {
        secretBigMac.addEventListener("click", function () {
            bigMacClicks++;

            if (bigMacClicks === 5) {
                window.location.href = "/hidden";
            }
        });
    }

    let colaClicks = 0;
    const secretCola = document.getElementById("secret-cola");

    if (secretCola) {
        secretCola.addEventListener("click", function () {
            colaClicks++;

            if (colaClicks === 5) {
                window.location.href = "/";
            }
        });
    }
});