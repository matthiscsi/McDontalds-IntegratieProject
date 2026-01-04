document.getElementById('leaderboardBtn').addEventListener('click', async () => {
    const modal = document.getElementById('leaderboardModal');
    const content = document.getElementById('leaderboardContent');
    
    modal.style.display = 'flex';
    
    try {
        const response = await fetch('/api/leaderboard');
        const data = await response.json();
        
        if (data.length === 0) {
            content.innerHTML = '<p style="text-align: center; color: #7f8c8d;">Nog geen scores beschikbaar</p>';
        } else {
            let html = '<table>';
            html += '<thead><tr>';
            html += '<th>#</th>';
            html += '<th>Naam</th>';
            html += '<th>Score</th>';
            html += '<th>Datum</th>';
            html += '</tr></thead><tbody>';
            
            data.forEach((entry, index) => {
                html += '<tr>';
                html += `<td>${index + 1}</td>`;
                html += `<td>${entry.player_name}</td>`;
                html += `<td>${entry.score}</td>`;
                html += `<td>${entry.date}</td>`;
                html += '</tr>';
            });
            
            html += '</tbody></table>';
            content.innerHTML = html;
        }
    } catch (error) {
        content.innerHTML = '<p style="color: red; text-align: center;">Error loading leaderboard</p>';
        console.error('Error:', error);
    }
});

document.getElementById('closeModal').addEventListener('click', () => {
    document.getElementById('leaderboardModal').style.display = 'none';
});

document.getElementById('leaderboardModal').addEventListener('click', (e) => {
    if (e.target.id === 'leaderboardModal') {
        document.getElementById('leaderboardModal').style.display = 'none';
    }
});