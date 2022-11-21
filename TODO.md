#  TODOs


- Camera and image fixed; user-guestures only move currently selected head-model
- Provide new model with named landmarks
- Compare new model's landmarks with face-detection landmarks
- Allow rotation



# Design

## Actions

- Select image
        - zoom image            <---- pinch,         when no face is selected
        - place face            <---- tap on rect
        - select face           <---- tap on rect or face
                - move face     <---- pinch          while face is selected
                - remove face   <----
        - unselect face         <---- tap background 
        - hide all faces        <---- hide/show icon
    

Visibility:
    face-model must remain visible when user zooms image
    other faces may become darker when user has one selected
    
    
    

## Implementation

- immediately after loading image:
    detect faces
    show subtle rects as an orientation where users may tap

- placing face: 
    tap on point in image
        chose rect closest to tap - if none found, place exactly on tap-location
        place head-model
        optional, later: gradient-descent to optimize placement
                        also then: display numeric fit to landmarks (eyes to far apart, nose too short, ...)


- selecting face:
    when tapping a rect of a face-model that has previously been removed, place a new one
    selection happens through either tap on rect or on face-model


- state-mgmt
    neccessary state:
        selectedFace
        detectedFaces
        modelPositions
    actions:
        MarkerView.rectTapped
        SceneView.faceTapped
        ...
        

## UI-Elements

Buttons:
    - Select (other) image
    - Show/hide models
    - Save


## Graphics

- rectangles
    - simple gray, semi-transparent
    - pop-animation on creation
    - light-up animation on selection

- face-model
    - white outlines
    - pop-animation on creation
    - light-up animation on selection
    

