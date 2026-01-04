document.addEventListener('DOMContentLoaded', function() {
    const languageBtn = document.querySelector('.btn-secondary[aria-label="Choose languages"]');
    const infoBtn = document.querySelector('.btn-secondary[aria-label="Info"]');
    const languagePopup = document.getElementById('language-popup');
    const infoPopup = document.getElementById('info-popup');
    const closeBtns = document.querySelectorAll('.btn-close');

    if (languageBtn) {
        languageBtn.addEventListener('click', function() {
            languagePopup.classList.remove('hidden');
        });
    }

    if (infoBtn) {
        infoBtn.addEventListener('click', function() {
            infoPopup.classList.remove('hidden');
        });
    }

    closeBtns.forEach(function(btn) {
        btn.addEventListener('click', function() {
            if (languagePopup) languagePopup.classList.add('hidden');
            if (infoPopup) infoPopup.classList.add('hidden');
        });
    });

    [languagePopup, infoPopup].forEach(function(popup) {
        if (popup) {
            popup.addEventListener('click', function(e) {
                if (e.target === popup) {
                    popup.classList.add('hidden');
                }
            });
        }
    });
});