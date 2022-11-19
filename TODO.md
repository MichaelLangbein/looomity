#  TODOs


- Camera and image fixed; user-guestures only move currently selected head-model
- Provide new model with named landmarks
- Compare new model's landmarks with face-detection landmarks
- Allow rotation


# Design

## Actions

- Select image
        - zoom image            <---- pinch,         when no face is selected
        - place face            <---- tap
        - select face           <---- tap on rect
                - move face     <---- pinch         while face is selected
                - remove face
        - unselect face         <---- tap background 
        - hide all faces        <---- hide/show icon
    
## Implementation

- placing face: 
    tap on point in image
        detect faces
        chose rect closest to tap - if none found, place exatly on tap-location
        place head-model
        optional, later: gradient-descent to optimize placement
                        also then: display numeric fit to landmarks (eyes to far apart, nose too short, ...)


## UI-Elements

- Select (other) image
- Show/hide models
- Save
