/**
 * app.js - Live interactive simulator controller for GNOME Quick Settings on KDE Plasma
 */

document.addEventListener('DOMContentLoaded', () => {
  // Elements
  const statusPillBtn = document.getElementById('statusPillBtn');
  const quickSettingsPanel = document.getElementById('quickSettingsPanel');
  const topClock = document.getElementById('topClock');
  const nightLightOverlay = document.getElementById('nightLightOverlay');
  const brightnessOverlay = document.getElementById('brightnessOverlay');

  // Sliders
  const volumeRange = document.getElementById('volumeRange');
  const volumeFill = document.getElementById('volumeFill');
  const volumeValText = document.getElementById('volumeValText');
  const muteToggleBtn = document.getElementById('muteToggleBtn');
  const trayVolumeIcon = document.getElementById('trayVolumeIcon');

  const brightnessRange = document.getElementById('brightnessRange');
  const brightnessFill = document.getElementById('brightnessFill');
  const brightnessValText = document.getElementById('brightnessValText');

  // Toggles
  const toggleWifi = document.getElementById('toggleWifi');
  const wifiSubtitle = document.getElementById('wifiSubtitle');
  const wifiChevronBtn = document.getElementById('wifiChevronBtn');
  const wifiDrawer = document.getElementById('wifiDrawer');
  const wifiBackBtn = document.getElementById('wifiBackBtn');
  const trayWifiIcon = document.getElementById('trayWifiIcon');

  const toggleBluetooth = document.getElementById('toggleBluetooth');
  const bluetoothSubtitle = document.getElementById('bluetoothSubtitle');
  const bluetoothChevronBtn = document.getElementById('bluetoothChevronBtn');
  const bluetoothDrawer = document.getElementById('bluetoothDrawer');
  const bluetoothBackBtn = document.getElementById('bluetoothBackBtn');

  const toggleDarkStyle = document.getElementById('toggleDarkStyle');
  const darkStyleSubtitle = document.getElementById('darkStyleSubtitle');

  const toggleNightLight = document.getElementById('toggleNightLight');
  const nightLightSubtitle = document.getElementById('nightLightSubtitle');

  const toggleAirplane = document.getElementById('toggleAirplane');
  const airplaneSubtitle = document.getElementById('airplaneSubtitle');

  const toggleDND = document.getElementById('toggleDND');
  const dndSubtitle = document.getElementById('dndSubtitle');

  const toggleHotspot = document.getElementById('toggleHotspot');
  const hotspotSubtitle = document.getElementById('hotspotSubtitle');

  const togglePowerSaver = document.getElementById('togglePowerSaver');
  const powerSaverSubtitle = document.getElementById('powerSaverSubtitle');

  // Media Player
  const playPauseBtn = document.getElementById('playPauseBtn');
  const prevTrackBtn = document.getElementById('prevTrackBtn');
  const nextTrackBtn = document.getElementById('nextTrackBtn');
  const mediaTitle = document.getElementById('mediaTitle');
  const mediaArtist = document.getElementById('mediaArtist');
  const mediaProgressFill = document.getElementById('mediaProgressFill');

  // 1. Clock
  function updateClock() {
    const now = new Date();
    const options = { weekday: 'short', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' };
    topClock.textContent = now.toLocaleDateString('en-US', options).replace(/,/g, '');
  }
  updateClock();
  setInterval(updateClock, 30000);

  // 2. Toggle Quick Settings Popout Panel
  let isPanelOpen = true;
  statusPillBtn.addEventListener('click', (e) => {
    e.stopPropagation();
    isPanelOpen = !isPanelOpen;
    if (isPanelOpen) {
      quickSettingsPanel.classList.remove('hidden');
      statusPillBtn.classList.add('active');
    } else {
      quickSettingsPanel.classList.add('hidden');
      statusPillBtn.classList.remove('active');
      closeDrawers();
    }
  });

  // Close panel on outside click
  document.addEventListener('click', (e) => {
    if (isPanelOpen && !quickSettingsPanel.contains(e.target) && !statusPillBtn.contains(e.target)) {
      isPanelOpen = false;
      quickSettingsPanel.classList.add('hidden');
      statusPillBtn.classList.remove('active');
      closeDrawers();
    }
  });

  function closeDrawers() {
    if (wifiDrawer) wifiDrawer.classList.add('hidden');
    if (bluetoothDrawer) bluetoothDrawer.classList.add('hidden');
  }

  // 3. Interactive Toggles (Curved Pill Capsules)

  // Wi-Fi
  toggleWifi.querySelector('.pill-main-click').addEventListener('click', () => {
    const active = toggleWifi.classList.toggle('active');
    wifiSubtitle.textContent = active ? 'Jainam_5G' : 'Off';
    trayWifiIcon.style.opacity = active ? '1' : '0.35';
    if (!active && !wifiDrawer.classList.contains('hidden')) {
      wifiDrawer.classList.add('hidden');
    }
  });

  wifiChevronBtn.addEventListener('click', (e) => {
    e.stopPropagation();
    closeDrawers();
    wifiDrawer.classList.remove('hidden');
  });

  wifiBackBtn.addEventListener('click', () => {
    wifiDrawer.classList.add('hidden');
  });

  // Bluetooth
  toggleBluetooth.querySelector('.pill-main-click').addEventListener('click', () => {
    const active = toggleBluetooth.classList.toggle('active');
    bluetoothSubtitle.textContent = active ? 'Sony WH-1000XM5' : 'Off';
    if (!active && !bluetoothDrawer.classList.contains('hidden')) {
      bluetoothDrawer.classList.add('hidden');
    }
  });

  bluetoothChevronBtn.addEventListener('click', (e) => {
    e.stopPropagation();
    closeDrawers();
    bluetoothDrawer.classList.remove('hidden');
  });

  bluetoothBackBtn.addEventListener('click', () => {
    bluetoothDrawer.classList.add('hidden');
  });

  // Dark Style
  toggleDarkStyle.addEventListener('click', () => {
    const active = toggleDarkStyle.classList.toggle('active');
    document.body.classList.toggle('theme-dark', active);
    document.body.classList.toggle('theme-light', !active);
    darkStyleSubtitle.textContent = active ? 'On' : 'Off';
  });

  // Night Light
  toggleNightLight.addEventListener('click', () => {
    const active = toggleNightLight.classList.toggle('active');
    nightLightSubtitle.textContent = active ? 'On' : 'Off';
    nightLightOverlay.classList.toggle('active', active);
  });

  // Airplane Mode
  toggleAirplane.addEventListener('click', () => {
    const active = toggleAirplane.classList.toggle('active');
    airplaneSubtitle.textContent = active ? 'On' : 'Off';
    if (active) {
      // Disables Wi-Fi & Bluetooth
      toggleWifi.classList.remove('active');
      wifiSubtitle.textContent = 'Off';
      trayWifiIcon.style.opacity = '0.35';

      toggleBluetooth.classList.remove('active');
      bluetoothSubtitle.textContent = 'Off';
      closeDrawers();
    }
  });

  // Do Not Disturb
  toggleDND.addEventListener('click', () => {
    const active = toggleDND.classList.toggle('active');
    dndSubtitle.textContent = active ? 'On' : 'Off';
  });

  // Hotspot
  toggleHotspot.addEventListener('click', () => {
    const active = toggleHotspot.classList.toggle('active');
    hotspotSubtitle.textContent = active ? 'Active' : 'Off';
  });

  // Power Saver
  let powerModeIndex = 0;
  const powerModes = ['Balanced', 'Power Saver', 'Performance'];
  togglePowerSaver.addEventListener('click', () => {
    powerModeIndex = (powerModeIndex + 1) % powerModes.length;
    const mode = powerModes[powerModeIndex];
    powerSaverSubtitle.textContent = mode;
    togglePowerSaver.classList.toggle('active', mode !== 'Balanced');
  });

  // 4. Sliders Logic

  // Volume
  let lastVolume = 72;
  function updateVolume(val) {
    val = Math.max(0, Math.min(100, parseInt(val, 10)));
    volumeRange.value = val;
    volumeFill.style.width = `${val}%`;
    volumeValText.textContent = `${val}%`;
    if (val === 0) {
      muteToggleBtn.textContent = '🔇';
      trayVolumeIcon.textContent = '🔇';
    } else if (val < 40) {
      muteToggleBtn.textContent = '🔉';
      trayVolumeIcon.textContent = '🔉';
    } else {
      muteToggleBtn.textContent = '🔊';
      trayVolumeIcon.textContent = '🔊';
    }
  }

  volumeRange.addEventListener('input', (e) => {
    updateVolume(e.target.value);
  });

  muteToggleBtn.addEventListener('click', () => {
    if (parseInt(volumeRange.value, 10) > 0) {
      lastVolume = parseInt(volumeRange.value, 10);
      updateVolume(0);
    } else {
      updateVolume(lastVolume || 72);
    }
  });

  // Brightness
  function updateBrightness(val) {
    val = Math.max(10, Math.min(100, parseInt(val, 10)));
    brightnessRange.value = val;
    brightnessFill.style.width = `${val}%`;
    brightnessValText.textContent = `${val}%`;

    // Apply dimmer overlay on preview
    const dimAlpha = (100 - val) * 0.007;
    brightnessOverlay.style.backgroundColor = `rgba(0, 0, 0, ${dimAlpha})`;
  }

  brightnessRange.addEventListener('input', (e) => {
    updateBrightness(e.target.value);
  });

  // 5. Media Player Mock
  const tracks = [
    { title: 'Midnight City', artist: "M83 — Hurry Up, We're Dreaming", art: '🌆' },
    { title: 'Resonance', artist: 'HOME — Odyssey', art: '🌌' },
    { title: 'Starboy', artist: 'The Weeknd ft. Daft Punk', art: '⚡' }
  ];
  let currentTrackIdx = 0;
  let isPlaying = true;
  let trackProgress = 44;
  let progressInterval = null;

  function loadTrack(idx) {
    const t = tracks[idx];
    mediaTitle.textContent = t.title;
    mediaArtist.textContent = t.artist;
    document.getElementById('mediaArt').textContent = t.art;
    trackProgress = 0;
    mediaProgressFill.style.width = '0%';
  }

  function startProgress() {
    if (progressInterval) clearInterval(progressInterval);
    progressInterval = setInterval(() => {
      if (isPlaying) {
        trackProgress = (trackProgress + 1) % 100;
        mediaProgressFill.style.width = `${trackProgress}%`;
      }
    }, 1000);
  }
  startProgress();

  playPauseBtn.addEventListener('click', () => {
    isPlaying = !isPlaying;
    playPauseBtn.textContent = isPlaying ? '⏸' : '▶';
  });

  nextTrackBtn.addEventListener('click', () => {
    currentTrackIdx = (currentTrackIdx + 1) % tracks.length;
    loadTrack(currentTrackIdx);
  });

  prevTrackBtn.addEventListener('click', () => {
    currentTrackIdx = (currentTrackIdx - 1 + tracks.length) % tracks.length;
    loadTrack(currentTrackIdx);
  });

  // 6. Action buttons
  document.getElementById('lockBtn').addEventListener('click', () => {
    alert('🔒 Screen Lock triggered (Simulates DBus call to org.freedesktop.ScreenSaver.Lock)');
  });

  document.getElementById('settingsBtn').addEventListener('click', () => {
    alert('⚙ Launch System Settings (Simulates kcmshell6 / systemsettings)');
  });

  document.getElementById('powerBtn').addEventListener('click', () => {
    alert('⏻ Power Menu opened (Simulates qdbus org.kde.Shutdown /Shutdown)');
  });
});
