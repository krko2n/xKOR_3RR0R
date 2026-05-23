/**
 * BootCoordinator - Orchestrated boot sequence
 * Inspired by eDEX-UI's boot.js staged startup
 *
 * Coordinates boot animation with:
 * - Staged kernel log playback
 * - Sound synchronization
 * - Progressive module revelation
 * - Glitch effects and transitions
 *
 * Critical for immersive "system booting" feel.
 */

import eventBus from '../core/EventBus.js';

class BootCoordinator {
  constructor() {
    this.state = 'idle'; // idle, booting, complete
    this.currentPhase = 0;
    this.bootLines = [];
    this.bootContainer = null;
    this.progressBar = null;
  }

  /**
   * Initialize boot coordinator
   */
  async init() {
    console.log('[BootCoordinator] Initialized');

    // Subscribe to authentication
    eventBus.on('login.success', () => {
      this.startBootSequence();
    });
  }

  /**
   * Start boot sequence
   */
  async startBootSequence() {
    if (this.state === 'booting') {
      console.warn('[BootCoordinator] Already booting');
      return;
    }

    this.state = 'booting';
    this.currentPhase = 0;
    eventBus.emit('boot.start');

    console.log('[BootCoordinator] Starting boot sequence...');

    // Hide login screen
    const loginScreen = document.getElementById('login-screen');
    if (loginScreen) {
      loginScreen.style.display = 'none';
    }

    // Show boot screen
    const bootScreen = document.getElementById('boot-screen');
    if (bootScreen) {
      bootScreen.style.display = 'flex';
      this.bootContainer = bootScreen.querySelector('#boot-lines');
      this.progressBar = bootScreen.querySelector('#boot-progress');
    }

    // Generate boot lines
    this._generateBootLines();

    // Execute boot phases
    await this._phase1_KernelInit();
    await this._phase2_SystemServices();
    await this._phase3_HardwareInit();
    await this._phase4_NetworkStack();
    await this._phase5_UIInit();
    await this._phase6_Complete();

    this.state = 'complete';
    eventBus.emit('boot.complete');
  }

  /**
   * Generate realistic kernel boot lines
   */
  _generateBootLines() {
    this.bootLines = [
      '[    0.000000] Linux version 6.12.8-xkor-3rr0r (root@cyberdeck) (gcc version 14.2.1)',
      '[    0.000000] Command line: BOOT_IMAGE=/boot/vmlinuz-xkor root=UUID=deadbeef ro quiet splash',
      '[    0.000000] x86/fpu: Supporting XSAVE feature 0x001: \'x87 floating point registers\'',
      '[    0.000000] x86/fpu: Supporting XSAVE feature 0x002: \'SSE registers\'',
      '[    0.000000] x86/fpu: Supporting XSAVE feature 0x004: \'AVX registers\'',
      '[    0.012345] ACPI: Core revision 20240927',
      '[    0.045678] Freeing SMP alternatives memory: 40K',
      '[    0.067890] smpboot: CPU0: AMD Ryzen 9 7950X 16-Core Processor',
      '[    0.089012] Performance Events: Fam17h+ core perfctr',
      '[    0.123456] smp: Bringing up secondary CPUs ...',
      '[    0.156789] x86: Booting SMP configuration:',
      '[    0.178901] smpboot: Total of 32 processors activated',
      '[    0.201234] devtmpfs: initialized',
      '[    0.234567] clocksource: jiffies: mask: 0xffffffff max_cycles: 0xffffffff',
      '[    0.267890] NET: Registered PF_NETLINK/PF_ROUTE protocol family',
      '[    0.301234] thermal_sys: Registered thermal governor \'step_wise\'',
      '[    0.334567] cpuidle: using governor ladder',
      '[    0.367890] ACPI: bus type PCI registered',
      '[    0.401234] PCI: Using configuration type 1 for base access',
      '[    0.434567] kworker/u64:0 (6) used greatest stack depth: 13872 bytes left',
      '[    0.467890] HugeTLB: registered 1.00 GiB page size, pre-allocated 0 pages',
      '[    0.501234] HugeTLB: registered 2.00 MiB page size, pre-allocated 0 pages',
      '[    0.534567] ACPI: Added _OSI(Module Device)',
      '[    0.567890] ACPI: Added _OSI(Processor Device)',
      '[    0.601234] ACPI: Added _OSI(3.0 _SCP Extensions)',
      '[    0.634567] ACPI: 8 ACPI AML tables successfully acquired and loaded',
      '[    0.667890] ACPI: Interpreter enabled',
      '[    0.701234] ACPI: PM: (supports S0 S3 S4 S5)',
      '[    0.734567] ACPI: Using IOAPIC for interrupt routing',
      '[    0.767890] PCI: Using host bridge windows from ACPI',
      '[    0.801234] ACPI: Enabled 2 GPEs in block 00 to 1F',
      '[    0.834567] SCSI subsystem initialized',
      '[    0.867890] usbcore: registered new interface driver usbfs',
      '[    0.901234] usbcore: registered new interface driver hub',
      '[    0.934567] usbcore: registered new device driver usb',
      '[    0.967890] NetLabel: Initializing',
      '[    1.001234] NetLabel: domain hash size = 128',
      '[    1.034567] NetLabel: protocols = UNLABELED CIPSOv4 CALIPSO',
      '[    1.067890] random: crng init done',
      '[    1.101234] Key type asymmetric registered',
      '[    1.134567] Asymmetric key parser \'x509\' registered',
      '[    1.167890] Block layer SCSI generic (bsg) driver version 0.4',
      '[    1.201234] nvme nvme0: pci function 0000:01:00.0',
      '[    1.234567] nvme nvme0: 16/0/0 default/read/poll queues',
      '[    1.267890] nvme0n1: p1 p2 p3',
      '[    1.301234] EXT4-fs (nvme0n1p2): mounted filesystem with ordered data mode',
      '[    1.334567] systemd[1]: systemd 256.8 running in system mode',
      '[    1.367890] systemd[1]: Detected architecture x86-64',
      '[    1.401234] systemd[1]: Hostname set to <cyberdeck>',
      '[    1.434567] systemd[1]: Reached target System Initialization.',
      '[    1.467890] systemd[1]: Starting xKOR_3RR0R display manager...',
      '[    1.501234] xkor-login[782]: Initializing xKOR_3RR0R v2.0.0-beta.1',
      '[    1.534567] xkor-login[782]: Loading theme: cyberpunk',
      '[    1.567890] xkor-login[782]: Spawning UI renderer...',
      '[    1.601234] xkor-login[782]: Mounting UI modules...',
      '[    1.634567] xkor-login[782]: Terminal subsystem ready',
      '[    1.667890] xkor-login[782]: System monitor active',
      '[    1.701234] xkor-login[782]: Globe renderer initialized',
      '[    1.734567] xkor-login[782]: Audio subsystem ready',
      '[    1.767890] xkor-login[782]: All modules loaded',
      '[    1.801234] systemd[1]: Started xKOR_3RR0R display manager.',
      '[    1.834567] xkor-ui[823]: ACCESS GRANTED',
      ''
    ];
  }

  /**
   * Phase 1: Kernel initialization
   */
  async _phase1_KernelInit() {
    this.currentPhase = 1;
    eventBus.emit('boot.phase', { phase: 1, name: 'Kernel Init' });
    await this._playLines(0, 10, 30);
    this._updateProgress(16);
  }

  /**
   * Phase 2: System services
   */
  async _phase2_SystemServices() {
    this.currentPhase = 2;
    eventBus.emit('boot.phase', { phase: 2, name: 'System Services' });
    await this._playLines(10, 20, 25);
    this._updateProgress(33);
  }

  /**
   * Phase 3: Hardware initialization
   */
  async _phase3_HardwareInit() {
    this.currentPhase = 3;
    eventBus.emit('boot.phase', { phase: 3, name: 'Hardware Init' });
    await this._playLines(20, 35, 20);
    this._updateProgress(50);
  }

  /**
   * Phase 4: Network stack
   */
  async _phase4_NetworkStack() {
    this.currentPhase = 4;
    eventBus.emit('boot.phase', { phase: 4, name: 'Network Stack' });
    await this._playLines(35, 45, 20);
    this._updateProgress(66);
  }

  /**
   * Phase 5: UI initialization
   */
  async _phase5_UIInit() {
    this.currentPhase = 5;
    eventBus.emit('boot.phase', { phase: 5, name: 'UI Init' });
    await this._playLines(45, 60, 40);
    this._updateProgress(83);
    eventBus.emit('boot.phase.completed', { phase: 5 });
  }

  /**
   * Phase 6: Complete
   */
  async _phase6_Complete() {
    this.currentPhase = 6;
    eventBus.emit('boot.phase', { phase: 6, name: 'Complete' });
    await this._playLines(60, this.bootLines.length, 50);
    this._updateProgress(100);

    // Hold final screen
    await this._delay(500);

    // Glitch transition
    await this._glitchTransition();

    // Hide boot screen
    const bootScreen = document.getElementById('boot-screen');
    if (bootScreen) {
      bootScreen.style.display = 'none';
    }

    // Show app
    const app = document.getElementById('app');
    if (app) {
      app.style.display = 'flex';
    }
  }

  /**
   * Play boot lines
   * @param {number} start - Start index
   * @param {number} end - End index
   * @param {number} delay - Delay between lines (ms)
   */
  async _playLines(start, end, delay) {
    for (let i = start; i < end && i < this.bootLines.length; i++) {
      const line = this.bootLines[i];
      if (this.bootContainer) {
        const lineEl = document.createElement('div');
        lineEl.className = 'boot-line';
        lineEl.textContent = line;
        this.bootContainer.appendChild(lineEl);

        // Auto-scroll
        this.bootContainer.scrollTop = this.bootContainer.scrollHeight;
      }

      await this._delay(delay);
    }
  }

  /**
   * Update progress bar
   * @param {number} percent - Progress percentage
   */
  _updateProgress(percent) {
    if (this.progressBar) {
      this.progressBar.style.width = `${percent}%`;
    }
  }

  /**
   * Glitch transition effect
   */
  async _glitchTransition() {
    const bootScreen = document.getElementById('boot-screen');
    if (!bootScreen) return;

    bootScreen.classList.add('glitch-out');
    await this._delay(300);
    bootScreen.classList.remove('glitch-out');
  }

  /**
   * Delay helper
   * @param {number} ms - Milliseconds
   */
  _delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

// Create singleton
const bootCoordinator = new BootCoordinator();

if (typeof window !== 'undefined') {
  window.bootCoordinator = bootCoordinator;
}

export default bootCoordinator;
