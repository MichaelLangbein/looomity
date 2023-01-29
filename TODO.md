#  TODOs


## Later

- Undo-button
	- Requires a state manager
	- Requires 'ongoing' states for gestures

- SCNView state
    - store all of SCNView's state in a global state-object
        - observations
        - opacity
        - currentOrientation
        - activeFace
        - interaction-states not required.
    - make the view easily recreate-able from that state
    - updates to opacity as well as adding and removing nodes can then be done by manipulating the state object, not by making `onRender` changes to the view.

- detect glsl-files. 
    - http://blog.simonrodriguez.fr/articles/2015/08/a_few_scntechnique_examples.html
    - https://github.com/sakrist/SCNTechniqueTest/blob/master/TechniqueTest/draw_normals/draw_normals.json

# Design

## Updates decided on later in the process

- All faces visible immediately
    - <= reason: global zoom is useless if you can only see boxes. need to see faces during global zoom
- Actions only work on active face
    - Or globally if no face selected

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
    
    
    
