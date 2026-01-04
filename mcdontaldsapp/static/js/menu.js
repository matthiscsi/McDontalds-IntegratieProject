let cart = [];
let cartTotal = 0;
const STORAGE_KEY = 'kiosk_cart';

const $  = (sel) => document.querySelector(sel);
const $$ = (sel) => document.querySelectorAll(sel);

function saveCart() {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(cart));
}

function loadCart() {
  try {
    const saved = JSON.parse(localStorage.getItem(STORAGE_KEY) || '[]');
    if (Array.isArray(saved)) {
      cart = saved.map(i => ({ name: i.name, price: Number(i.price) }));
      recalcTotal();
    }
  } catch { /* ignore */ }
}

function recalcTotal() {
  cartTotal = cart.reduce((sum, i) => sum + Number(i.price || 0), 0);
}

function addToCart(itemName, price) {
  const numPrice = parseFloat(String(price).replace(',', '.'));
  cart.push({ name: itemName, price: numPrice });
  recalcTotal();
  saveCart();
  updateCartDisplay();
  document.dispatchEvent(new CustomEvent('itemAdded'));
}

function showCategory(categoryName) {
  const categoryElement = document.querySelector(`[data-category="${categoryName}"]`);
  if (categoryElement) categoryElement.click();
}

function updateCartDisplay() {
  const cartSummary = $('#cart-summary');
  const checkoutBtn = $('#checkout-btn');

  const itemCount = cart.length;
  const totalFormatted = cartTotal.toFixed(2);

  if (cartSummary) cartSummary.textContent = `${itemCount} items • €${totalFormatted}`;

  if (checkoutBtn) {
    checkoutBtn.disabled = itemCount === 0;
    checkoutBtn.textContent = itemCount ? `Checkout €${totalFormatted}` : 'Checkout Total';
  }
}

window.addToCart = addToCart;
window.showCategory = showCategory;

document.addEventListener('DOMContentLoaded', () => {
  loadCart();
  updateCartDisplay();

  const categories = $$('.category-item');
  const sections   = $$('.menu-section');

  categories.forEach(category => {
    category.addEventListener('click', () => {
      categories.forEach(c => c.classList.remove('active'));
      category.classList.add('active');

      sections.forEach(section => {
        section.classList.remove('active');
        section.style.display = 'none';
      });

      const selected = category.getAttribute('data-category');
      const selectedSection = document.getElementById(selected);
      if (selectedSection) {
        selectedSection.classList.add('active');
        selectedSection.style.display = 'block';
      }
    });
  });

  const initialActive = $('.menu-section.active');
  if (initialActive) initialActive.style.display = 'block';

  const checkoutBtn = $('#checkout-btn');
  if (checkoutBtn) {
    checkoutBtn.addEventListener('click', () => {
      if (cart.length > 0) {
        saveCart();               
        window.location.href = '/checkout'; 
      }
    });
  }

  document.addEventListener('itemAdded', () => {
    const cartIcon = $('.cart-icon');
    if (!cartIcon) return;
    cartIcon.style.transform = 'scale(1.2)';
    setTimeout(() => { cartIcon.style.transform = 'scale(1)'; }, 200);
  });
});