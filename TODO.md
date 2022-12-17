#  TODOs


- Gestures
    - pinch
        - on face: zoom
        - on background: zoom both image and 3d

Gestures overall

|           | tap    | pinch  | pan    | 2-finger-pan |
|-----------|--------|--------|--------|--------------|
|face       | select | zoom   | rotate | translate    |
|background | select | zoom   | -      | -            |

- Better face-placement
    - also get face-landmarks
    - gradient-descent position and scale until best match


## Later
- detect glsl-files. 
    - http://blog.simonrodriguez.fr/articles/2015/08/a_few_scntechnique_examples.html
    - https://github.com/sakrist/SCNTechniqueTest/blob/master/TechniqueTest/draw_normals/draw_normals.json

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

- immediately after loading image: ....................................... done
    detect faces ......................................................... done
    show subtle rects as an orientation where users may tap .............. done

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
    - Select (other) image .......... done
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
    

