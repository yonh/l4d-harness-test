/**
 * {AGENT} — L4D Rooftop entrypoint (skeleton).
 * Replace this placeholder with the full gameplay from TASK.md.
 * Module split (ES modules) is required; see TASK.md §4.6 and §6.1 (A3-A8).
 */
import * as THREE from 'three';
import { PointerLockControls } from 'three/addons/controls/PointerLockControls.js';

const scene = new THREE.Scene();
scene.background = new THREE.Color(0x0b1220);
scene.fog = new THREE.FogExp2(0x0b1220, 0.008);

const camera = new THREE.PerspectiveCamera(70, innerWidth / innerHeight, 0.1, 200);
camera.position.set(0, 1.7, 5);

const renderer = new THREE.WebGLRenderer({ antialias: true, canvas: document.querySelector('#app') });
renderer.setSize(innerWidth, innerHeight);
renderer.setPixelRatio(Math.min(devicePixelRatio, 2));

// Lights — moonlight + accent points
scene.add(new THREE.AmbientLight(0x334466, 0.6));
const moon = new THREE.DirectionalLight(0x8fb3ff, 1.2);
moon.position.set(6, 10, 4);
scene.add(moon);

// Placeholder rooftop floor (replace with ${AGENT}_rooftop.glb from Blender)
const floor = new THREE.Mesh(
  new THREE.BoxGeometry(40, 0.2, 40),
  new THREE.MeshStandardMaterial({ color: 0x334050 })
);
floor.position.y = -0.1;
scene.add(floor);

// Pointer lock + FPS controls skeleton
const controls = new PointerLockControls(camera, document.body);
const centerMsg = document.querySelector('#center-msg');
centerMsg.textContent = '点击开始 / Click to start';

function engage() {
  controls.lock();
}
document.addEventListener('click', engage);
controls.addEventListener('lock', () => { centerMsg.textContent = ''; });
controls.addEventListener('unlock', () => { centerMsg.textContent = '已暂停 / Paused'; });

// Minimal render loop
renderer.setAnimationLoop(() => {
  renderer.render(scene, camera);
});
window.addEventListener('resize', () => {
  camera.aspect = innerWidth / innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(innerWidth, innerHeight);
});
