let soundEnabled = localStorage.getItem('dg_sound') === 'true';

function playSound(type) {
    if (!soundEnabled) return;
    try {
        const ctx = new (window.AudioContext || window.webkitAudioContext)();
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.connect(gain);
        gain.connect(ctx.destination);
        const freqs = { success: 880, error: 220, badge: 660, click: 440 };
        osc.frequency.value = freqs[type] || 440;
        gain.gain.setValueAtTime(0.08, ctx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.15);
        osc.start(ctx.currentTime);
        osc.stop(ctx.currentTime + 0.15);
    } catch (_) { /* audio not available */ }
}

function showToast(message, type = 'info', duration = 4000) {
    const container = document.getElementById('toast-container');
    if (!container) return;
    const toast = document.createElement('div');
    toast.className = `toast toast-${type}`;
    const icons = { success: '✅', error: '❌', info: 'ℹ️', badge: '🎖️' };
    toast.innerHTML = `<span class="toast-icon">${icons[type] || icons.info}</span><span>${message}</span>`;
    container.appendChild(toast);
    requestAnimationFrame(() => toast.classList.add('show'));
    if (type === 'success' || type === 'badge') playSound(type);
    setTimeout(() => {
        toast.classList.remove('show');
        setTimeout(() => toast.remove(), 300);
    }, duration);
}

function initSoundToggle() {
    const btn = document.getElementById('sound-toggle');
    if (!btn) return;
    const update = () => { btn.textContent = soundEnabled ? '🔊' : '🔇'; };
    update();
    btn.addEventListener('click', () => {
        soundEnabled = !soundEnabled;
        localStorage.setItem('dg_sound', soundEnabled);
        update();
        if (soundEnabled) playSound('click');
    });
}

async function submitScore(gameType, score, details = '') {
    try {
        const resp = await fetch(window.DEVOPS_GAMES.apiScore, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                player_name: window.DEVOPS_GAMES.playerName,
                game_type: gameType,
                score: score,
                details: details
            })
        });
        const data = await resp.json();
        if (data.ok) {
            const bonus = data.daily_bonus ? ' (2× daily bonus!)' : '';
            showToast(`+${data.score} XP submitted!${bonus}`, 'success');
            if (data.new_badges?.length) {
                data.new_badges.forEach(b => {
                    setTimeout(() => showToast(`${b.icon} ${b.name} unlocked!`, 'badge', 5000), 400);
                });
            }
        }
        return data;
    } catch (e) {
        console.error('Score submit failed:', e);
        showToast('Failed to submit score', 'error');
        return { ok: false };
    }
}

function buildShareText(score, message, gameName) {
    const player = window.DEVOPS_GAMES.playerName;
    return `🎮 DevOps Games: ${player} scored ${score} XP in ${gameName || 'a game'} — "${message}"\n${window.location.origin}`;
}

async function copyShareText(text) {
    try {
        await navigator.clipboard.writeText(text);
        showToast('Score copied to clipboard!', 'success');
    } catch (_) {
        showToast('Copy failed — try manually', 'error');
    }
}

function showResult(container, score, message, badges = [], gameName = '') {
    const shareText = buildShareText(score, message, gameName);
    let badgeHtml = '';
    if (badges.length) {
        badgeHtml = '<div class="new-badges">' +
            badges.map(b => `<span class="new-badge animate-pop">${b.icon} ${b.name} unlocked!</span>`).join('') +
            '</div>';
    }
    container.innerHTML = `
        <div class="result-overlay animate-in">
            <h2>${message}</h2>
            <div class="final-score count-up">${score} XP</div>
            ${badgeHtml}
            <div class="result-actions">
                <a href="/" class="btn btn-primary">Back to Arcade</a>
                <button class="btn btn-ghost" onclick="location.reload()">Play Again</button>
                <button class="btn btn-ghost" id="share-btn">📋 Share Score</button>
            </div>
        </div>`;
    document.getElementById('share-btn')?.addEventListener('click', () => copyShareText(shareText));
    if (score > 0) playSound('success');
}

function normalizeText(text) {
    return text.replace(/\r\n/g, '\n').trim().replace(/\s+$/gm, '');
}

function isDailyChallenge() {
    const banner = document.querySelector('.daily-challenge');
    if (!banner) return false;
    const path = window.location.pathname;
    const dailyLink = banner.querySelector('a')?.getAttribute('href');
    return dailyLink && path === dailyLink;
}

document.addEventListener('DOMContentLoaded', initSoundToggle);
