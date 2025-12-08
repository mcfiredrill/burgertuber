import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { OrbitControls } from "three/addons/controls/OrbitControls.js";
import { Socket } from 'phoenix';
import { CSS2DRenderer, CSS2DObject } from 'three/addons/renderers/CSS2DRenderer.js';

//utils
function deg2Rad(degrees) {
  //return degrees * (Math.PI / 180);
  return THREE.MathUtils.degToRad(degrees);
}

function rad2Deg(r){
  return THREE.MathUtils.radToDeg(r);
}

const scene = new THREE.Scene();
scene.background = new THREE.Color(0xedfff2);

//lights
const ambient = new THREE.AmbientLight(0x222222, 4);
scene.add(ambient);

const light = new THREE.DirectionalLight(0xffffff, 0.5);
light.position.set(0, 0, 6);
scene.add(light);

const light2 = new THREE.DirectionalLight(0xffffff);
light2.position.set(120, 130, -130);
scene.add(light2);


const camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 1000);
camera.position.set(4, 1, 6);

const geometry = new THREE.BoxGeometry(1, 1, 1);
const material = new THREE.MeshBasicMaterial({color: 0x00ff00});
const cube = new THREE.Mesh(geometry, material);

scene.add(cube);

const loader = new GLTFLoader();
let burgerModel;

// bones
let headBone;

loader.load('./public/hamburger_salaryman_rigged.glb', (gltf) => {
  burgerModel = gltf.scene;
  scene.add(burgerModel);

  burgerModel.traverse((child) => {
    if(child.name === 'head') {
      headBone = child;
    }
  });
  console.log('headBone: ', headBone.quaternion);

  renderer.setAnimationLoop(animate);
 }, undefined, function (error) {
   console.error(error);
});

// axes helpers
const trackerHelper = new THREE.AxesHelper(5);
trackerHelper.setColors(
  new THREE.Color(0xff8080), // X
  new THREE.Color(0x80ff80), // Y
  new THREE.Color(0x8080ff)  // Z
);
scene.add(trackerHelper);
labelAxes(trackerHelper, "trackerHelper");

const correctedHelper = new THREE.AxesHelper(5);
scene.add(correctedHelper);
labelAxes(correctedHelper, "correctedHelper");

const normalAxes = new THREE.AxesHelper(30);
scene.add(normalAxes);
labelAxes(normalAxes, "normalAxes");

// webgl renderer
const renderer = new THREE.WebGLRenderer();
renderer.setSize(window.innerWidth, window.innerHeight);
document.body.appendChild(renderer.domElement);

// Add CSS2DRenderer
const labelRenderer = new CSS2DRenderer();
labelRenderer.setSize(window.innerWidth, window.innerHeight);
labelRenderer.domElement.style.position = 'absolute';
labelRenderer.domElement.style.top = '0';
labelRenderer.domElement.style.pointerEvents = 'none';
document.body.appendChild(labelRenderer.domElement);

// controls
const controls = new OrbitControls(camera, renderer.domElement);
controls.update();
//controls.autoRotate = true;
//


// align OSF coordinates to three.js
const correction = new THREE.Quaternion()
  .setFromEuler(
    new THREE.Euler(
      deg2Rad(180), 0, deg2Rad(-90)
      // correct orientation, but pitch/yaw is reversed
      //deg2Rad(180), 0, deg2Rad(-90)
      //-Math.PI, 0, -Math.PI / 2
    )
  );

// // another quat we use to swap pitch/yaw
const swapQuat = new THREE.Quaternion()
  .setFromEuler(
    new THREE.Euler(0, 0, deg2Rad(90))
  );

let targetQuat = new THREE.Quaternion();
let currentQuat = new THREE.Quaternion();

const slerpFactor = 0.20;

// quaternion from OSF
let trackerQuaternion;

function labelAxes(helper, helperName, axisLength = 5) {
  const makeLabel = (text) => {
    const div = document.createElement('div');
    div.textContent = text;
    div.style.color = "white";
    div.style.fontSize = "13px";
    div.style.fontWeight = "bold";
    div.style.padding = "2px 4px";
    div.style.background = "rgba(0,0,0,0.6)";
    div.style.borderRadius = "3px";
    div.style.whiteSpace = "nowrap";
    div.style.textShadow = "1px 1px 3px black";
    return new CSS2DObject(div);
  };

  const xLabel = makeLabel(`${helperName} X`);
  xLabel.position.set(axisLength, 0, 0);

  const yLabel = makeLabel(`${helperName} Y`);
  yLabel.position.set(0, axisLength, 0);

  const zLabel = makeLabel(`${helperName} Z`);
  zLabel.position.set(0, 0, axisLength);

  helper.add(xLabel, yLabel, zLabel);
}

function showQuats(trackerQuat) {
  // place helpers at headBone world position
  const pos = new THREE.Vector3();
  headBone.getWorldPosition(pos);
  trackerHelper.position.copy(pos);
  correctedHelper.position.copy(pos);

  // tracker orientation (as raw from OSF)
  trackerHelper.setRotationFromQuaternion(trackerQuat);

  // corrected orientation
  const corr = new THREE.Quaternion().copy(correction).multiply(trackerQuat).normalize();
  correctedHelper.setRotationFromQuaternion(corr);
}

const animate = () => {
  cube.rotation.x += 0.01;
  cube.rotation.y += 0.01;
  cube.rotation.z += 0.01;

  //currentQuat.copy(targetQuat);
  currentQuat.slerp(targetQuat, slerpFactor);
  headBone.quaternion.copy(currentQuat);
  //
    //
    //
  if(trackerQuaternion) {
    showQuats(trackerQuaternion);
  }
  controls.update();
  renderer.render(scene, camera);
  labelRenderer.render(scene, camera);
}

let socket = new Socket("http://localhost:4000/socket")
socket.connect()

let channel = socket.channel("osf", {});
channel.join()
  .receive("ok", () => console.log("Joined OSF channel"))
  .receive("error", () => console.log("Failed to join OSF channel"))

channel.on("packet", (data) => {
  //console.log("Received openseeface packet: ", data);
  trackerQuaternion = new THREE.Quaternion(data.quaternion.x, data.quaternion.y, data.quaternion.z, data.quaternion.w);

  // const swappedTracker = new THREE.Quaternion().copy(trackerQuaternion)
  //   .multiply(swapQuat)  // swaps the axes in the tracker space
  //   .normalize();

  // const corrected = new THREE.Quaternion().copy(correction).multiply(trackerQuaternion).normalize();

  // const eOsf = new THREE.Euler().setFromQuaternion(trackerQuaternion, 'XYZ');
  // const eCorr = new THREE.Euler().setFromQuaternion(corrected, 'XYZ');
  // console.log("OSF Euler XYZ: ", rad2Deg(eOsf.x), rad2Deg(eOsf.y), rad2Deg(eOsf.z));
  // console.log("Corrected Euler XYZ: ", rad2Deg(eCorr.x), rad2Deg(eCorr.y), rad2Deg(eCorr.z));
  // targetQuat.copy(correction)
  //   .multiply(trackerQuaternion)
  //   //.multiply(swapQuat)
  //   .normalize();
  targetQuat.copy(trackerQuaternion).multiply(correction).normalize();
});
