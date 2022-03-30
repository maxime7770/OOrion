# OOrion project


# Python Part


## Requirements

The needed packages are listed in the `requirements.txt` file. Use the following command line to install them:
```python
pip install requirements.txt
```

## Patterns Detection

This part explains the patterns detection process: how to load the dataset, the model and train the model.

### Load Data

- Download data from this link: https://drive.google.com/file/d/1EFYem4V9Lkckc23aNWzYV2HzKjALYyXr/view?usp=sharing
- Put the `dataset_pattern` folder in the `python-models` folder in the repository
- Here is the folder structure initially:
    ```
    dataset_pattern
    ├── striped_init
    ├── checkered_init
    └── dotted_init
    ```

- Execute the `create_train_val.py` file to create train/validation datasets from `dataset_pattern`(you can change the split rate in the file)

- A new folder is created: `dataset_train_val` with the following structure:
    ```
    dataset_train_val
    ├── train
    │   ├── striped_init
    │   ├── checkered_init
    │   └── dotted_init
    └── val
        ├── striped_init
        ├── checkered_init
        └── dotted_init
    ```

### Load, train and save the model

- The model's architecture and hyperparameters are defined in `model_pattern.py`: use it to change the architecture or adapat the hyperparameters

- Execute `train_pattern.py`: it will both load the model, train the model and save the model with the `.h5`format

### Convert the model to CoreML

- To be used in Swift, that model needs to be converted in `.mlmodel`. To do so, use `convert.py` by changing the model variable to "model_pattern.h5" 



## Clothes Recognition

This part explains the clothes recognition process: how to load the dataset, the model and train the model.

### Load Data

- Download data from this link: https://drive.google.com/file/d/1LCJO-QWwG0783i6vQ2BUWX8pZKFM6qOT/view?usp=sharing

- Put the `dataset_clothes` folder in the `python-models` folder in the repository

- Here is the folder structure:
    ```
    dataset_pattern
    ├── train
    │   ├── outwear
    │   ├── shorts
    │   ├── t-shirt
    │   ├── pants
    │   ├── dress
    │   ├── longsleeve
    │   └── skirt
    └── validation
        ├── outwear
        ├── shorts
        ├── t-shirt
        ├── pants
        ├── dress
        ├── longsleeve
        └── skirt
    ```
- It is already split so there is no need to use `create_train_val.py`

### Load, train and save the model

- The model's architecture and hyperparameters are defined in `model_clothes.py`: use it to change the architecture or adapat the hyperparameters

- Execute `train_clothes.py`: it will both load the model, train the model and save the model with the `.h5`format

### Convert the model to CoreML

- To be used in Swift, that model needs to be converted in `.mlmodel`. To do so, use `convert.py` by changing the model variable to "model_clothes.h5"




# Swift Part

## Folder Structure

- Here is a summary of the folder structure, only most important files are shown here.
    ```
    OOrion-Project-App
    ├── OOrion-Project-App
    │   ├── AppDelegate
    │   ├── ViewController
    │   ├── BoundingBoxView
    │   └── Constants
    ├── VideoCaptures
    │   ├── VideoCapture
    │   ├── VideoCameraType
    │   └── AVCaptureDevice+Extension
    ├── Detections
    │   ├── ColorDetection
    │   ├── PatternDetection
    │   └── TextDetection
    └── models
    ```

    - OOrion-Project-App subfolder contains main files needed to run the App
    - VideoCapture folder contains scripts needed to operate camera and won't be detailed
    - Detections folder contains most scripts relative to features we developped
    - models folder contains the YoloV5 mlmodel we use in Yolo Mode

## Changing models

### Yolo Model

To replace the Yolo model we use, you need to rename your model `yolov5.mlmodel` and copy it to the `models` folder.

### Pattern Model

To replace the PatternModel (for example with one trained as described in the Python part), yo need to first rename the model `PatternModel.mlmodel` and move the mlmodel file to the `models` folder.

## App Usage

The App consists of three modes, to change from one to another, just tap on the "Mode" button in the top left corner of the screen.

### Yolo Without Text Mode

This is the Mode in which the App starts. It recognizes objects thanks to YoloV5, and displays bounding boxes for the 3 objects for which it has the most confidence. It also displays the colors of the objects in question.

### Yolo With Text Mode

This mode uses Yolo to get the bounding box of the object with the most confidence. It then gets the object color and checks if text is on the object.

### No Object Mode

This mode doesn't detect objects, it displays a square in the middle of the screen, and checks for color, pattern and text in the image inside of this square.

## Scripts description

This part explains how the code is organised and split between the different swift scripts. It also describes the contents of each script and the main functions defined.

### View Controller

The View Controller can be considered as the main script of the code. It defines the main classes used in our program and the different extensions of the pre-existing ones. It also features the code linked to the display, the capture and the treatment of the image camera on screen and the selection and use of the different models. Lastly, it also calls functions back from other scripts in order to use the different functionalities of the program, such as the color, the text and the pattern detection.

- The main class of the script is defined at first and is called `ViewController`. It contains the main functino concerning the camera display, the model initialization, the brightness check and finally the display of all the Yolo Labels.

- The function `noObjectDetect` calls all the functions back in order to display the pattern, color and text detected in the mode with no object detection. It also instantiates the square of detection in the middle of the screen, which correspounds to the area of the image which is treated by the program.

- The last function contained in the main class is the `Mode` function. It creates the Change Mode button and cleans the screen everytime the user changes mode. 

- It contains extensions for the "String", "URL", "UIColor" and "UIImage" classes.

- The last function is the `Crop` function. It crops the image on screen in order to return only the square in the middle.

### BoundingBox View

The `BoundingBoxView.swift` script is responsible for drawing boundingBox of object detected with YoloV5.

- The function `draw` is responsible for drawing the bounding boxes and is called when observation is updated.
    - It is composed of two parts :
        - Mode 0 : For Yolo Without Text Mode : Displays 3 bounding boxes with color of objects
        - Mode 1 : For Yolo With Text : Displays 1 bounding box and updates "Label", "Color" and "Text"

- The `getLabels` function : responsible for returning labels, only used for Yolo With Text Mode

- The last two functions are responsible for helping drawing the bounding box, by respectively generating the rectangle corresponding and adding the label to the bounding box

### Constants

The `Constants.swift` scripts defines all the main constants used in the code. They were all grouped here in order to simplify tests and modifications. They are linked to the square size, thresholds for brightness, second and third color detection, and for the model detection. It also feature a french translation of the Yolo labels.

### ColorDetection

The `ColorDetection.swift` script describes all the function linked to the color detection feature. 

- The first two functions defined work together. "detectColor" returns an array of String of color names to display by calling the "getColorText" function. The last returns the most present color(s), based on the color frequencies object generated by the first function.

- In order to do this, the `getColorText` calls two other functions back. The `rgbToHsv.swift` converts the color from the RGB format to the HSV format, and the "colorConversion" function translates the HSV code to the french name of the closer color.

### PatternDetection

The `PatternDetection.swift` script describes all the functions linked to pattern detection featue.

- The Extension at the beginning of the script is used to convert UIImage to CVPixelBuffer, which is the type used as input for CoreML models
- The first function defined out of this extension runs the model and adds the key of the pattern found to listPatterns
- The next function, `getPattern` gives the most frequent pattern name of listPattern, we use this to improve results of PatternModel, by refreshing pattern every 10 images with the most frequent pattern from the last 10 frames
- The last function is a function we use to resize the image before giving it to the model

### TextDetection

The `TextDetection.swift` script describes all the function linked to the text detection feature. 

- The `DetectText.swift` function calls the following function (the handler) back in order to return the text present on the image. It generates a request from the image for the handler and displays on screen the String that it returns.

- The `handleDetectedText` function returns the text detected from the request. It is first recognized on the screen using the Vision framework, then each of the words goes through a word correction in order to try only to return words from the english / french dictionary. If a word does not appear in the dictionary and is far from any known words, it is still displayed as it is.












