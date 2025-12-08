burgertuber
------------


three.js vtuber solution

There are 3 components:

* three.js frontend app
* openseeface udp <-> websocket bridge - phoenix backend
* (https://github.com/emilianavt/OpenSeeFace)[openseeface]

# Run frontend


```
npm install
npx vite
```

Open browser to localhost:5173

# Run phoenix backend

```
cd osf_bridge
mix deps.get
mix phx.server
```

# Get and run openseeface

Follow instructions on the (https://github.com/emilianavt/OpenSeeFace?tab=readme-ov-file#usage)[OpenSeeFace repo]
https://github.com/emilianavt/OpenSeeFace?tab=readme-ov-file#usage

My app expects it to run on port 12000 but this can be changed in the code.

I have a small bash script to run OpenSeeFace tracker with my options for my webcam and port:
```bash
#!/bin/bash

source env/bin/activate
python facetracker.py -c 0 -W 640 -H 480 --discard-after 0 --scan-every 0 --no-3d-adapt 1 --max-feature-updates 900 --port 12000
```

Then you should see the model moving in the browser according to the movements captured by the webcam.


# TODO
- [ ] support eye blinking blendshapes
- [ ] add twitch redeem reactions (throw a cube at the character etc)
