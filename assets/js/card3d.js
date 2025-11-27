import * as THREE from 'three';

/**
 * Renders a 3D card using Three.js
 * Supports mouse interaction for rotation and flip animation
 */
export function initCard3D(container) {
  const canvas = container.querySelector('canvas');
  if (!canvas) return;

  const cardContent = JSON.parse(container.dataset.cardContent || '{}');
  const front = cardContent.front || {};
  const back = cardContent.back || {};

  // Scene setup
  const scene = new THREE.Scene();
  const camera = new THREE.PerspectiveCamera(50, canvas.clientWidth / canvas.clientHeight, 0.1, 1000);
  camera.position.z = 3;

  const renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: true });
  renderer.setSize(canvas.clientWidth, canvas.clientHeight);
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));

  // Card geometry (credit card proportions ~85.6mm x 53.98mm)
  const cardWidth = 1.6;
  const cardHeight = 2.2;
  const cardDepth = 0.02;
  const cornerRadius = 0.08;

  // Create rounded rectangle shape
  const shape = new THREE.Shape();
  const x = -cardWidth / 2;
  const y = -cardHeight / 2;
  const w = cardWidth;
  const h = cardHeight;
  const r = cornerRadius;

  shape.moveTo(x + r, y);
  shape.lineTo(x + w - r, y);
  shape.quadraticCurveTo(x + w, y, x + w, y + r);
  shape.lineTo(x + w, y + h - r);
  shape.quadraticCurveTo(x + w, y + h, x + w - r, y + h);
  shape.lineTo(x + r, y + h);
  shape.quadraticCurveTo(x, y + h, x, y + h - r);
  shape.lineTo(x, y + r);
  shape.quadraticCurveTo(x, y, x + r, y);

  const extrudeSettings = {
    depth: cardDepth,
    bevelEnabled: true,
    bevelThickness: 0.005,
    bevelSize: 0.005,
    bevelSegments: 2
  };

  const geometry = new THREE.ExtrudeGeometry(shape, extrudeSettings);
  geometry.center();

  // Materials - grayscale theme
  const frontMaterial = new THREE.MeshStandardMaterial({
    color: 0xffffff,
    roughness: 0.3,
    metalness: 0.1
  });

  const backMaterial = new THREE.MeshStandardMaterial({
    color: 0x1e293b, // slate-800
    roughness: 0.4,
    metalness: 0.2
  });

  const edgeMaterial = new THREE.MeshStandardMaterial({
    color: 0x64748b, // slate-500
    roughness: 0.5,
    metalness: 0.3
  });

  const materials = [edgeMaterial, frontMaterial, backMaterial];

  // Apply materials to faces
  geometry.groups = [];
  geometry.addGroup(0, geometry.attributes.position.count, 0);

  const card = new THREE.Mesh(geometry, frontMaterial);
  scene.add(card);

  // Create text on front
  const frontCanvas = document.createElement('canvas');
  const frontCtx = frontCanvas.getContext('2d');
  frontCanvas.width = 512;
  frontCanvas.height = 704;

  // Draw front face
  frontCtx.fillStyle = '#ffffff';
  frontCtx.fillRect(0, 0, 512, 704);

  // Draw content
  frontCtx.fillStyle = '#0f172a'; // slate-900
  frontCtx.font = 'bold 48px system-ui, sans-serif';
  frontCtx.textAlign = 'center';

  const name = front.name || 'Public Card';
  frontCtx.fillText(name, 256, 300);

  if (front.title) {
    frontCtx.font = '32px system-ui, sans-serif';
    frontCtx.fillStyle = '#475569'; // slate-600
    frontCtx.fillText(front.title, 256, 360);
  }

  if (front.tagline) {
    frontCtx.font = '24px system-ui, sans-serif';
    frontCtx.fillStyle = '#94a3b8'; // slate-400
    const taglineWords = front.tagline.split(' ');
    let line = '';
    let yPos = 420;
    for (const word of taglineWords) {
      const testLine = line + word + ' ';
      if (frontCtx.measureText(testLine).width > 440) {
        frontCtx.fillText(line, 256, yPos);
        line = word + ' ';
        yPos += 32;
      } else {
        line = testLine;
      }
    }
    frontCtx.fillText(line, 256, yPos);
  }

  // Add "PUBLIC CARD" badge at bottom
  frontCtx.font = '18px system-ui, sans-serif';
  frontCtx.fillStyle = '#cbd5e1'; // slate-300
  frontCtx.fillText('PUBLIC CARD', 256, 650);

  const frontTexture = new THREE.CanvasTexture(frontCanvas);
  frontTexture.anisotropy = renderer.capabilities.getMaxAnisotropy();

  // Create back texture
  const backCanvas = document.createElement('canvas');
  const backCtx = backCanvas.getContext('2d');
  backCanvas.width = 512;
  backCanvas.height = 704;

  backCtx.fillStyle = '#1e293b'; // slate-800
  backCtx.fillRect(0, 0, 512, 704);

  // Draw back content
  backCtx.fillStyle = '#f1f5f9'; // slate-100
  backCtx.font = '24px system-ui, sans-serif';
  backCtx.textAlign = 'center';

  if (back.bio) {
    const bioWords = back.bio.split(' ');
    let line = '';
    let yPos = 200;
    for (const word of bioWords) {
      const testLine = line + word + ' ';
      if (backCtx.measureText(testLine).width > 440) {
        backCtx.fillText(line, 256, yPos);
        line = word + ' ';
        yPos += 36;
      } else {
        line = testLine;
      }
    }
    backCtx.fillText(line, 256, yPos);
  }

  // Hash/version indicator
  backCtx.font = '16px monospace';
  backCtx.fillStyle = '#64748b'; // slate-500
  backCtx.fillText('Content-addressable', 256, 620);
  backCtx.fillText('Ownable & Versionable', 256, 650);

  const backTexture = new THREE.CanvasTexture(backCanvas);
  backTexture.anisotropy = renderer.capabilities.getMaxAnisotropy();

  // Create separate front and back planes
  const frontPlane = new THREE.Mesh(
    new THREE.PlaneGeometry(cardWidth * 0.95, cardHeight * 0.95),
    new THREE.MeshBasicMaterial({ map: frontTexture, transparent: true })
  );
  frontPlane.position.z = cardDepth / 2 + 0.001;
  card.add(frontPlane);

  const backPlane = new THREE.Mesh(
    new THREE.PlaneGeometry(cardWidth * 0.95, cardHeight * 0.95),
    new THREE.MeshBasicMaterial({ map: backTexture, transparent: true })
  );
  backPlane.position.z = -cardDepth / 2 - 0.001;
  backPlane.rotation.y = Math.PI;
  card.add(backPlane);

  // Lighting
  const ambientLight = new THREE.AmbientLight(0xffffff, 0.6);
  scene.add(ambientLight);

  const directionalLight = new THREE.DirectionalLight(0xffffff, 0.8);
  directionalLight.position.set(2, 2, 5);
  scene.add(directionalLight);

  const backLight = new THREE.DirectionalLight(0xffffff, 0.3);
  backLight.position.set(-2, -2, -5);
  scene.add(backLight);

  // Mouse interaction
  let mouseX = 0;
  let mouseY = 0;
  let targetRotationX = 0;
  let targetRotationY = 0;
  let isFlipped = false;
  let flipProgress = 0;

  container.addEventListener('mousemove', (e) => {
    const rect = container.getBoundingClientRect();
    mouseX = ((e.clientX - rect.left) / rect.width) * 2 - 1;
    mouseY = -((e.clientY - rect.top) / rect.height) * 2 + 1;
  });

  container.addEventListener('mouseleave', () => {
    mouseX = 0;
    mouseY = 0;
  });

  container.addEventListener('click', () => {
    isFlipped = !isFlipped;
  });

  // Animation
  function animate() {
    requestAnimationFrame(animate);

    // Smooth rotation based on mouse position
    targetRotationY = isFlipped ? Math.PI : 0;
    targetRotationY += mouseX * 0.3;
    targetRotationX = mouseY * 0.2;

    card.rotation.x += (targetRotationX - card.rotation.x) * 0.08;
    card.rotation.y += (targetRotationY - card.rotation.y) * 0.08;

    // Subtle floating animation
    card.position.y = Math.sin(Date.now() * 0.001) * 0.02;

    renderer.render(scene, camera);
  }

  animate();

  // Handle resize
  const resizeObserver = new ResizeObserver(() => {
    const width = container.clientWidth;
    const height = container.clientHeight;
    camera.aspect = width / height;
    camera.updateProjectionMatrix();
    renderer.setSize(width, height);
  });

  resizeObserver.observe(container);

  return {
    destroy: () => {
      resizeObserver.disconnect();
      renderer.dispose();
    }
  };
}

// Auto-initialize on page load
document.addEventListener('DOMContentLoaded', () => {
  document.querySelectorAll('[data-card-content]').forEach(initCard3D);
});
