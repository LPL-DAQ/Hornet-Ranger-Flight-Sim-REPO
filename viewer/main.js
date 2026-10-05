// USC LPL Ranger Visualization V0.1
// Written on 10/4/26 

import * as THREE from 'https://cdn.jsdelivr.net/npm/three@0.180.0/+esm';
import { OrbitControls } from 'https://cdn.jsdelivr.net/npm/three@0.180.0/examples/jsm/controls/OrbitControls.js/+esm';
import URDFLoader from 'https://cdn.jsdelivr.net/npm/urdf-loader@0.12.6/+esm';

const scene = new THREE.Scene();
const camera = new THREE.PerspectiveCamera(60, innerWidth / innerHeight, 0.1, 1e4);
const renderer = new THREE.WebGLRenderer({ antialias: true });
const controls = new OrbitControls(camera, renderer.domElement);
const grid = new THREE.GridHelper(100, 100);

scene.background = new THREE.Color(0x000000);
camera.position.set(8, 6, 8);
renderer.setSize(innerWidth, innerHeight);
document.body.appendChild(renderer.domElement);

controls.enableDamping = true;
grid.position.y = -2;

scene.add(new THREE.HemisphereLight(0xffffff, 0x444444, 3));
scene.add(grid);

// landing pad
// TODO: pad and reference grid are at -2 y. should be origin. 
const PAD_SIZE = 6; // m
const pad = new THREE.Mesh(
  new THREE.PlaneGeometry(PAD_SIZE, PAD_SIZE).rotateX(-Math.PI / 2),
  new THREE.MeshBasicMaterial({ color: 0x555555, transparent: true, opacity: 0.5, side: THREE.DoubleSide, depthWrite: false })
);
pad.position.y = -2; 
scene.add(pad);
new THREE.TextureLoader().load('http://127.0.0.1:8080/pad.png', tex => {
  tex.colorSpace = THREE.SRGBColorSpace;
  pad.material.setValues({ map: tex, color: 0xffffff, opacity: 1 });
  pad.material.needsUpdate = true;
});

// change of basis from MATLAB inertial to three.js world: X -> Y (up), Y -> Z, Z -> X
const E2T = new THREE.Matrix4().set( // earth2threejs
  0, 0, 1, 0,
  1, 0, 0, 0,
  0, 1, 0, 0,
  0, 0, 0, 1
);
const qE2T = new THREE.Quaternion().setFromRotationMatrix(E2T);
const qEB = new THREE.Quaternion();

// Group in Simulink body coordinates
const body = new THREE.Group();
body.quaternion.copy(qE2T);
body.add(new THREE.AxesHelper(3));
scene.add(body);
body.position.y = 0
let rocket;

const CG = 1.88; // m, base_link inertial origin z in ranger.urdf (this is a rough guess)

new URDFLoader().load('ranger.urdf', r => {
  rocket = r;
  rocket.rotation.y = Math.PI / 2;
  rocket.position.x = -CG;
  body.add(rocket);
});


// state panel
await ImGui.default();
ImGui.CreateContext();
ImGui_Impl.Init(renderer.getContext());
let state = {};
const HISTORY = 600; // 10s @ 60hz logging
const position = [[], [], []];

new EventSource('/telemetry').onmessage = e => {
  state = JSON.parse(e.data);
  state.position_e.forEach((v, i) => {
    position[i].push(v);
    if (position[i].length > HISTORY) position[i].shift();
  });
  const { position_e: [x, y, z], quaternion_eb: [w, qx, qy, qz], gimbal: [dy, dz] } = state;

  body.position.set(z, x, y);

  // Simulink q maps body -> Earth convention already matches
  qEB.set(qx, qy, qz, w).normalize();
  body.quaternion.copy(qE2T).multiply(qEB);

  // engine axis matches u = [cos(dz)cos(dy); sin(dz)cos(dy); -sin(dy)] (see TVC block from Andrew)
  rocket?.setJointValue('tvc_y', dy);
  rocket?.setJointValue('tvc_x', -dz);
};

function animate(time) {
  requestAnimationFrame(animate);

  ImGui_Impl.NewFrame(time);
  ImGui.NewFrame();
  ImGui.Begin('State', null, ImGui.WindowFlags.AlwaysAutoResize);
  for (const [k, v] of Object.entries(state))
    ImGui.Text(k.padEnd(14) + [v].flat().map(n => (n ?? NaN).toFixed(3).padStart(9)).join(''));
  ImGui.Separator();
  ['x (up)', 'y', 'z'].forEach((axis, i) =>
    ImGui.PlotLines(`position ${axis}`, position[i], position[i].length, 0, position[i].at(-1)?.toFixed(3), undefined, undefined, new ImGui.Vec2(300, 50)));
  ImGui.End();
  ImGui.Render();

  controls.enabled = !ImGui.GetIO().WantCaptureMouse; // drag != orbit
  controls.target.copy(body.position);
  controls.update();
  renderer.render(scene, camera);
  ImGui_Impl.RenderDrawData(ImGui.GetDrawData());
  renderer.resetState();
}
requestAnimationFrame(animate);

addEventListener('resize', () => {
  camera.aspect = innerWidth / innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(innerWidth, innerHeight);
});