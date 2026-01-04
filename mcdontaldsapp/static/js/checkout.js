const STORAGE_KEY = 'kiosk_cart';

let cart = [];
let selectedOrderType = 'dinein';
let selectedPaymentMethod = 'card';

function loadCart() {
    try {
        const saved = JSON.parse(localStorage.getItem(STORAGE_KEY) || '[]');
        if (Array.isArray(saved)) {
            cart = saved.map(i => ({ 
                name: i.name, 
                price: Number(i.price) 
            }));
        }
    } catch (e) {
        console.error('Error loading cart:', e);
        cart = [];
    }
}

function saveCart() {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(cart));
}

document.addEventListener('DOMContentLoaded', function() {
    loadCart();
    renderCartItems();
    updateOrderSummary();
    setupEventListeners();

    const savedType = localStorage.getItem('orderType');
    if (savedType) {
        selectedOrderType = savedType;
        document.querySelectorAll('.order-type-option').forEach(opt => {
            opt.classList.remove('selected');
            if (opt.dataset.type === savedType) {
                opt.classList.add('selected');
            }
        });
    }
    if (savedType) {
        selectedOrderType = savedType;
        document.querySelectorAll('.order-type-option').forEach(opt => {
            if (opt.dataset.type === savedType) {
                opt.classList.add('selected');
            } else {
                opt.style.display = "none";
            }
        });
    }
});

function setupEventListeners() {
    document.querySelectorAll('.order-type-option').forEach(option => {
        option.addEventListener('click', function() {
            document.querySelectorAll('.order-type-option').forEach(o => o.classList.remove('selected'));
            this.classList.add('selected');
            selectedOrderType = this.dataset.type;
        });
    });

    document.querySelectorAll('.payment-option').forEach(option => {
        option.addEventListener('click', function() {
            document.querySelectorAll('.payment-option').forEach(o => o.classList.remove('selected'));
            this.classList.add('selected');
            selectedPaymentMethod = this.dataset.method;
        });
    });

    document.getElementById('place-order').addEventListener('click', placeOrder);
}

function renderCartItems() {
    const cartItemsList = document.getElementById('cart-items-list');
    const emptyCart = document.getElementById('empty-cart');
    
    if (cart.length === 0) {
        cartItemsList.innerHTML = '';
        emptyCart.style.display = 'block';
        return;
    }

    emptyCart.style.display = 'none';
    
    const groupedItems = {};
    cart.forEach(item => {
        const key = `${item.name}-${item.price}`;
        if (groupedItems[key]) {
            groupedItems[key].count++;
        } else {
            groupedItems[key] = { ...item, count: 1 };
        }
    });

    cartItemsList.innerHTML = Object.values(groupedItems).map((item) => `
        <div class="cart-item">
            <div class="cart-item-header">
                <h3>${item.name}</h3>
                <div class="cart-item-price">€${(item.price * item.count).toFixed(2).replace('.', ',')}</div>
            </div>
            <div class="cart-item-controls">
                <button onclick="decreaseItem('${item.name}', ${item.price})">-</button>
                <span>${item.count}</span>
                <button onclick="increaseItem('${item.name}', ${item.price})">+</button>
            </div>
        </div>
    `).join('');
}

function increaseItem(itemName, itemPrice) {
    cart.push({ name: itemName, price: itemPrice });
    saveCart();
    renderCartItems();
    updateOrderSummary();
}

function decreaseItem(itemName, itemPrice) {
    const index = cart.findIndex(item => item.name === itemName && item.price === itemPrice);
    if (index > -1) {
        cart.splice(index, 1);
        saveCart();
        renderCartItems();
        updateOrderSummary();
    }
}

function updateOrderSummary() {
    const subtotal = cart.reduce((sum, item) => sum + Number(item.price), 0);
    const tax = subtotal * 0.09;
    const total = subtotal + tax;

    document.getElementById('subtotal').textContent = `€${subtotal.toFixed(2).replace('.', ',')}`;
    document.getElementById('tax').textContent = `€${tax.toFixed(2).replace('.', ',')}`;
    document.getElementById('total').textContent = `€${total.toFixed(2).replace('.', ',')}`;

    const checkoutBtn = document.getElementById('place-order');
    if (cart.length > 0) {
        checkoutBtn.disabled = false;
        checkoutBtn.textContent = `Place Order €${total.toFixed(2).replace('.', ',')}`;
    } else {
        checkoutBtn.disabled = true;
        checkoutBtn.textContent = 'Bestelling Plaatsen';
    }
}

async function placeOrder() {
    if (cart.length === 0) return;

    const subtotal = cart.reduce((sum, item) => sum + Number(item.price), 0);
    const tax = subtotal * 0.06;
    const total = subtotal + tax;

    try {
        const response = await fetch("/api/place-order", {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                items: cart,
                total: total.toFixed(2)
            })
        });

        const data = await response.json();

        if (data.success) {
            document.getElementById("order-number").textContent = data.order_number;
            const modal = document.getElementById("success-modal");
            modal.classList.add("show");

            cart = [];
            saveCart();
        } else {
            alert("Bestelling mislukt, probeer opnieuw.");
        }
    } catch (err) {
        console.error("Error placing order:", err);
        alert("Er ging iets mis met je bestelling.");
    }
}

document.getElementById('success-modal').addEventListener('click', function(e) {
    if (e.target === this) {
        window.location.href = '/';
    }
});