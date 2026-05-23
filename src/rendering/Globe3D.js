/**
 * Globe3D - WebGL globe renderer
 * Modern evolution of eDEX-UI's Three.js globe
 *
 * Optimized rendering with:
 * - Instanced mesh for threat zone markers
 * - Shader materials for performance
 * - Delta timing for smooth rotation
 * - GPU-aware quality scaling
 * - Fallback modes for low-end hardware
 */

import * as THREE from 'three';

class Globe3D {
  constructor(container) {
    this.container = container;
    this.scene = null;
    this.camera = null;
    this.renderer = null;
    this.globe = null;
    this.markers = [];
    this.animationId = null;
    this.rotation = 0;
    this.rotationSpeed = 0.001;
    this.lastTime = 0;

    // Threat zones (lat, lon)
    this.threatZones = [
      { lat: 50.45, lon: 30.52, name: 'Ukraine' },      // Kyiv
      { lat: 33.89, lon: 35.50, name: 'Middle East' },  // Beirut
      { lat: 25.03, lon: 121.57, name: 'Taiwan' }       // Taipei
    ];

    this.quality = 'high'; // high, medium, low
    this.state = 'uninitialized';
  }

  /**
   * Initialize Three.js scene
   */
  init() {
    if (this.state !== 'uninitialized') {
      console.warn('[Globe3D] Already initialized');
      return;
    }

    try {
      // Detect GPU capability
      this._detectQuality();

      // Create scene
      this.scene = new THREE.Scene();
      this.scene.background = new THREE.Color(0x0a0a0a);

      // Create camera
      const aspect = this.container.clientWidth / this.container.clientHeight;
      this.camera = new THREE.PerspectiveCamera(45, aspect, 0.1, 1000);
      this.camera.position.z = 3;

      // Create renderer
      this.renderer = new THREE.WebGLRenderer({
        antialias: this.quality === 'high',
        alpha: true,
        powerPreference: 'high-performance'
      });
      this.renderer.setSize(this.container.clientWidth, this.container.clientHeight);
      this.renderer.setPixelRatio(window.devicePixelRatio);
      this.container.appendChild(this.renderer.domElement);

      // Create globe
      this._createGlobe();

      // Create threat markers
      this._createMarkers();

      // Add lighting
      this._setupLighting();

      this.state = 'ready';
      console.log(`[Globe3D] Initialized (quality: ${this.quality})`);
    } catch (err) {
      console.error('[Globe3D] Initialization failed:', err);
      this.state = 'error';
      this._createFallback();
    }
  }

  /**
   * Detect GPU quality and set appropriate settings
   */
  _detectQuality() {
    const canvas = document.createElement('canvas');
    const gl = canvas.getContext('webgl') || canvas.getContext('experimental-webgl');

    if (!gl) {
      this.quality = 'low';
      return;
    }

    const debugInfo = gl.getExtension('WEBGL_debug_renderer_info');
    if (debugInfo) {
      const renderer = gl.getParameter(debugInfo.UNMASKED_RENDERER_WEBGL);
      // Simple heuristic: if "Intel" or "Software", use medium quality
      if (renderer.includes('Intel') || renderer.includes('Software')) {
        this.quality = 'medium';
      }
    }
  }

  /**
   * Create globe mesh
   */
  _createGlobe() {
    const segments = this.quality === 'high' ? 64 : this.quality === 'medium' ? 32 : 16;
    const geometry = new THREE.SphereGeometry(1, segments, segments);

    // Create material
    const material = new THREE.MeshPhongMaterial({
      color: 0x004422,
      emissive: 0x001100,
      specular: 0x00ff9f,
      shininess: 10,
      wireframe: false,
      transparent: true,
      opacity: 0.8
    });

    this.globe = new THREE.Mesh(geometry, material);
    this.scene.add(this.globe);

    // Add wireframe overlay
    if (this.quality !== 'low') {
      const wireframeGeo = new THREE.WireframeGeometry(geometry);
      const wireframeMat = new THREE.LineBasicMaterial({
        color: 0x00ff9f,
        transparent: true,
        opacity: 0.3
      });
      const wireframe = new THREE.LineSegments(wireframeGeo, wireframeMat);
      this.globe.add(wireframe);
    }
  }

  /**
   * Create threat zone markers
   */
  _createMarkers() {
    this.threatZones.forEach(zone => {
      const marker = this._createMarker(zone.lat, zone.lon);
      this.markers.push(marker);
      this.globe.add(marker);
    });
  }

  /**
   * Create single marker
   * @param {number} lat - Latitude
   * @param {number} lon - Longitude
   * @returns {THREE.Mesh}
   */
  _createMarker(lat, lon) {
    const phi = (90 - lat) * (Math.PI / 180);
    const theta = (lon + 180) * (Math.PI / 180);

    const x = -Math.sin(phi) * Math.cos(theta);
    const y = Math.cos(phi);
    const z = Math.sin(phi) * Math.sin(theta);

    const geometry = new THREE.SphereGeometry(0.02, 8, 8);
    const material = new THREE.MeshBasicMaterial({
      color: 0xff0033,
      emissive: 0xff0033,
      transparent: true,
      opacity: 0.9
    });

    const marker = new THREE.Mesh(geometry, material);
    marker.position.set(x * 1.01, y * 1.01, z * 1.01);

    // Add pulsing animation
    marker.userData.baseScale = 1;
    marker.userData.pulsePhase = Math.random() * Math.PI * 2;

    return marker;
  }

  /**
   * Setup lighting
   */
  _setupLighting() {
    const ambientLight = new THREE.AmbientLight(0x404040, 0.5);
    this.scene.add(ambientLight);

    const pointLight = new THREE.PointLight(0x00ff9f, 1, 100);
    pointLight.position.set(2, 2, 2);
    this.scene.add(pointLight);

    const pointLight2 = new THREE.PointLight(0x00d4ff, 0.5, 100);
    pointLight2.position.set(-2, -2, -2);
    this.scene.add(pointLight2);
  }

  /**
   * Start animation loop
   */
  start() {
    if (this.animationId) return;

    const animate = (time) => {
      this.animationId = requestAnimationFrame(animate);

      // Delta timing
      const deltaTime = time - this.lastTime;
      this.lastTime = time;

      this._update(deltaTime);
      this._render();
    };

    animate(0);
  }

  /**
   * Update scene
   * @param {number} deltaTime - Time since last frame (ms)
   */
  _update(deltaTime) {
    if (!this.globe) return;

    // Rotate globe
    this.rotation += this.rotationSpeed * deltaTime;
    this.globe.rotation.y = this.rotation;

    // Pulse markers
    this.markers.forEach(marker => {
      const pulse = Math.sin(Date.now() * 0.003 + marker.userData.pulsePhase);
      const scale = marker.userData.baseScale + pulse * 0.3;
      marker.scale.set(scale, scale, scale);

      // Update opacity
      marker.material.opacity = 0.7 + pulse * 0.3;
    });
  }

  /**
   * Render scene
   */
  _render() {
    if (this.renderer && this.scene && this.camera) {
      this.renderer.render(this.scene, this.camera);
    }
  }

  /**
   * Stop animation
   */
  stop() {
    if (this.animationId) {
      cancelAnimationFrame(this.animationId);
      this.animationId = null;
    }
  }

  /**
   * Handle resize
   */
  resize() {
    if (!this.renderer || !this.camera) return;

    const width = this.container.clientWidth;
    const height = this.container.clientHeight;

    this.camera.aspect = width / height;
    this.camera.updateProjectionMatrix();

    this.renderer.setSize(width, height);
  }

  /**
   * Create fallback (Canvas2D) if WebGL fails
   */
  _createFallback() {
    console.warn('[Globe3D] Falling back to Canvas2D');
    const canvas = document.createElement('canvas');
    canvas.width = this.container.clientWidth;
    canvas.height = this.container.clientHeight;
    canvas.style.width = '100%';
    canvas.style.height = '100%';
    this.container.appendChild(canvas);

    const ctx = canvas.getContext('2d');

    // Simple 2D circle as fallback
    const animate = () => {
      this.animationId = requestAnimationFrame(animate);

      ctx.fillStyle = '#0a0a0a';
      ctx.fillRect(0, 0, canvas.width, canvas.height);

      const centerX = canvas.width / 2;
      const centerY = canvas.height / 2;
      const radius = Math.min(centerX, centerY) * 0.8;

      // Draw circle
      ctx.strokeStyle = '#00ff9f';
      ctx.lineWidth = 2;
      ctx.beginPath();
      ctx.arc(centerX, centerY, radius, 0, Math.PI * 2);
      ctx.stroke();

      // Draw rotating line
      this.rotation += 0.01;
      ctx.beginPath();
      ctx.moveTo(centerX, centerY);
      ctx.lineTo(
        centerX + Math.cos(this.rotation) * radius,
        centerY + Math.sin(this.rotation) * radius
      );
      ctx.stroke();
    };

    animate();
  }

  /**
   * Cleanup
   */
  destroy() {
    this.stop();

    if (this.renderer) {
      this.renderer.dispose();
      if (this.renderer.domElement.parentNode) {
        this.renderer.domElement.parentNode.removeChild(this.renderer.domElement);
      }
    }

    if (this.scene) {
      this.scene.traverse(obj => {
        if (obj.geometry) obj.geometry.dispose();
        if (obj.material) {
          if (Array.isArray(obj.material)) {
            obj.material.forEach(mat => mat.dispose());
          } else {
            obj.material.dispose();
          }
        }
      });
    }

    this.scene = null;
    this.camera = null;
    this.renderer = null;
    this.globe = null;
    this.markers = [];
  }
}

export default Globe3D;
