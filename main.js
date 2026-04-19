import * as THREE from 'three';
import * as CANNON from 'cannon-es'
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { OrbitControls } from "three/addons/controls/OrbitControls.js";
import { Socket } from 'phoenix';
import { CSS2DRenderer, CSS2DObject } from 'three/addons/renderers/CSS2DRenderer.js';

// Setup our physics world
const world = new CANNON.World({
  gravity: new CANNON.Vec3(0, -9.82, 0), // m/s²
})

// Create a sphere body
const radius = 1 // m
const sphereBody = new CANNON.Body({
  mass: 5, // kg
  shape: new CANNON.Sphere(radius),
})
sphereBody.position.set(10, 10, 0) // m
sphereBody.velocity.x = -5;
world.addBody(sphereBody)

// Create a static plane for the ground
const groundBody = new CANNON.Body({
  type: CANNON.Body.STATIC, // can also be achieved by setting the mass to 0
  shape: new CANNON.Plane(),
})
groundBody.quaternion.setFromEuler(-Math.PI / 2, 0, 0) // make it face up
world.addBody(groundBody)

// burger's static body
const burgerBody = new CANNON.Body({
  mass: 1,
  shape: new CANNON.Sphere(2),
})
world.addBody(burgerBody);

const DEBUG = false;

const ENABLE_FACE_TRACKING = false;

//utils
function deg2Rad(degrees) {
  //return degrees * (Math.PI / 180);
  return THREE.MathUtils.degToRad(degrees);
}

function rad2Deg(r){
  return THREE.MathUtils.radToDeg(r);
}

const scene = new THREE.Scene();
scene.background = new THREE.Color(0x00ff00);

//lights
const ambient = new THREE.AmbientLight(0x222222, 4);
scene.add(ambient);

const light = new THREE.DirectionalLight(0xffffff, 3);
light.position.set(0, 0, 6);
scene.add(light);

const light2 = new THREE.DirectionalLight(0xffffff);
light2.position.set(120, 130, -130);
scene.add(light2);


const camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 1000);
camera.position.set(4, 1, 6);

const loader = new GLTFLoader();
let burgerModel;
let goodBeverageModel;

// bones
let headBone;
let morphDict;
let morphInfluences;

const geometry = new THREE.SphereGeometry(1)
const material = new THREE.MeshNormalMaterial()
const sphereMesh = new THREE.Mesh(geometry, material)
//scene.add(sphereMesh)

loader.load('/hamburger_salaryman_rigged_w_shape_keys.glb', (gltf) => {
  burgerModel = gltf.scene;
  scene.add(burgerModel);

  let mesh;
  burgerModel.traverse((child) => {
    if(child.name === 'head') {
      headBone = child;
    }
    if(child.isMesh && child.name === "Plane002_1") {
      console.log('found mesh: ', child);
      mesh = child;
    }
  });
  console.log(mesh);
  morphDict = mesh.morphTargetDictionary;
  morphInfluences = mesh.morphTargetInfluences;
  console.log('burgerModel.morphTargetDictionary: ', morphDict);
  console.log('burgerModel.morphTargetInfluences: ', morphInfluences);
  console.log('headBone: ', headBone.quaternion);

  renderer.setAnimationLoop(animate);

 }, undefined, function (error) {
   console.error(error);
});

loader.load('/good_beverage.glb', (gltf) => {
  goodBeverageModel = gltf.scene;
  goodBeverageModel.scale.multiplyScalar( .2 );
  scene.add(goodBeverageModel);
 }, undefined, function (error) {
   console.error(error);
});

// visualize axes for debugging
const labelRenderer = new CSS2DRenderer();
const trackerHelper = new THREE.AxesHelper(5);
const correctedHelper = new THREE.AxesHelper(5);
const normalAxes = new THREE.AxesHelper(30);

if(DEBUG) {
  // axes helpers
  trackerHelper.setColors(
    new THREE.Color(0xff8080), // X
    new THREE.Color(0x80ff80), // Y
    new THREE.Color(0x8080ff)  // Z
  );
  scene.add(trackerHelper);
  labelAxes(trackerHelper, "trackerHelper");

  scene.add(correctedHelper);
  labelAxes(correctedHelper, "correctedHelper");

  scene.add(normalAxes);
  labelAxes(normalAxes, "normalAxes");

  // Add CSS2DRenderer
  labelRenderer.setSize(window.innerWidth, window.innerHeight);
  labelRenderer.domElement.style.position = 'absolute';
  labelRenderer.domElement.style.top = '0';
  labelRenderer.domElement.style.pointerEvents = 'none';
  document.body.appendChild(labelRenderer.domElement);
}

// webgl renderer
const renderer = new THREE.WebGLRenderer();
renderer.setSize(window.innerWidth, window.innerHeight);
document.body.appendChild(renderer.domElement);

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

let leftEyeOpen = 1.0;
let rightEyeOpen = 1.0;

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

  if(DEBUG) {
    trackerHelper.position.copy(pos);
    correctedHelper.position.copy(pos);

    // tracker orientation (as raw from OSF)
    trackerHelper.setRotationFromQuaternion(trackerQuat);

    // corrected orientation
    const corr = new THREE.Quaternion().copy(correction).multiply(trackerQuat).normalize();
    correctedHelper.setRotationFromQuaternion(corr);
  }
}

function throwGoodBeverage() {
  // Create a sphere body
  const radius = 1 // m
  const sphereBody = new CANNON.Body({
    mass: 5, // kg
    shape: new CANNON.Sphere(radius),
  })

  // TODO rand range position and velocity
  sphereBody.position.set(10, 10, 0)
  sphereBody.velocity.x = -5;
  world.addBody(sphereBody)

  let newGoodBeverageModel = goodBeverageModel.clone();
  scene.add(newGoodBeverageModel);
  // need array of models + physics bodies
}

const animate = () => {
  currentQuat.slerp(targetQuat, slerpFactor);
  headBone.quaternion.copy(currentQuat);

  if(DEBUG) {
    if(trackerQuaternion) {
      showQuats(trackerQuaternion);
    }
    labelRenderer.render(scene, camera);
  }

  if(morphInfluences) {
    morphInfluences[morphDict["l eye"]] = THREE.MathUtils.clamp((1.0 - leftEyeOpen) / (1.0 - 0.65), 0, 1);
    morphInfluences[morphDict["r eye"]] = THREE.MathUtils.clamp((1.0 - rightEyeOpen) / (1.0 - 0.65), 0, 1);

    //console.log("morphInfluences: ", morphInfluences);
  }

  world.fixedStep();

  // sync physics to our meshes
  sphereMesh.position.copy(burgerBody.position);
  sphereMesh.quaternion.copy(burgerBody.quaternion);
  //

  if(goodBeverageModel) {
    goodBeverageModel.position.copy(sphereBody.position);
    goodBeverageModel.quaternion.copy(sphereBody.quaternion);
  }
  // TODO loop over thrown objects

  burgerBody.position.copy(burgerModel.position);

  // the sphere y position shows the sphere falling
  //console.log(`Sphere y position: ${sphereBody.position.y}`)

  controls.update();
  renderer.render(scene, camera);
}

if(ENABLE_FACE_TRACKING) {
  let socket = new Socket("http://localhost:4000/socket")
  socket.connect()

  let channel = socket.channel("osf", {});
  channel.join()
    .receive("ok", () => console.log("Joined OSF channel"))
    .receive("error", () => console.log("Failed to join OSF channel"))

  channel.on("good_beverage", (data) => {
    // throw good beverage
    throwGoodBeverage();
  });

  channel.on("packet", (data) => {
    if(DEBUG) {
      console.log("Received openseeface packet: ", data.rightEyeOpen);
      console.log("Received openseeface packet: ", data.leftEyeOpen);
    }

    rightEyeOpen = data.rightEyeOpen;
    leftEyeOpen = data.leftEyeOpen;

    trackerQuaternion = new THREE.Quaternion(data.quaternion.x, data.quaternion.y, data.quaternion.z, data.quaternion.w);

    targetQuat.copy(trackerQuaternion).multiply(correction).normalize();
  });
}
