# OOrion project


# Python Part



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