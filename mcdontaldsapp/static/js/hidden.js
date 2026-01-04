const pinInput = document.getElementById("pin");
const keys = document.querySelectorAll(".keypad .key");

keys.forEach(key => {
    key.addEventListener("click", () => {
        pinInput.value += key.textContent;
    });
});

function clearPin() {
    pinInput.value = "";
}

function checkPin() {
    const correctPin = "1234";
    if (pinInput.value === correctPin) {
        window.location.href = "/admin";

    } else {
        alert("Foute code");
        pinInput.value = "";
    }
}