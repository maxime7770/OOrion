import tensorflow as tf
import keras
from tensorflow.keras.utils import to_categorical
from keras.preprocessing.image import ImageDataGenerator
from keras.layers import Conv2D,Dense,MaxPooling2D,Input,Flatten,Dropout
from keras.models import Sequential
import numpy as np
import cv2
import os
from model_clothes import model
import matplotlib.pyplot as plt 



# Before executing this file, dataset_train_val folder must be present in python-models folder (see README.md)




# Data is rescaled to [0, 1]

train_datagen = ImageDataGenerator(rescale = 1./255)
test_datagen = ImageDataGenerator(rescale = 1./255)


# Get the number of train and validation examples

train_size = sum([len(os.listdir('dataset_clothes/train/' + sub_folder)) for sub_folder in os.listdir('dataset_clothes/train') if sub_folder != '.DS_Store'])
val_size = sum([len(os.listdir('dataset_clothes/validation/' + sub_folder)) for sub_folder in os.listdir('dataset_clothes/validation') if sub_folder != '.DS_Store'])


# Define batch_size for train and validation sets, and the number of epochs

batch_size_train = 32
batch_size_val = 1
epochs = 5


# Build train and validation generators (to be passed into the model)

train_generator = train_datagen.flow_from_directory(
        'dataset_clothes/train',
        target_size = (128, 128),
        batch_size = batch_size_train,
        class_mode = 'categorical', 
        shuffle = True)
validation_generator = test_datagen.flow_from_directory(
        'dataset_clothes/validation',
        target_size = (128, 128),
        batch_size = batch_size_val,
        class_mode = 'categorical', 
        shuffle = True)



# Train the model

history = model.fit(
        train_generator,
        epochs = epochs,
        steps_per_epoch = train_size / batch_size_train,  # Number_of_samples / batch_size
        validation_data = validation_generator,
        verbose = True,
        validation_steps = val_size / batch_size_val  # Number_of_samples / batch_size
)
    


def plot_loss():
    ''' plot the loss for the train and validation data from the history variable '''

    plt.plot(history.history['loss'])
    plt.plot(history.history['val_loss'])
    plt.title('model loss')
    plt.ylabel('loss')
    plt.xlabel('epoch')
    plt.legend(['train', 'val'], loc='upper left')
    plt.show()


if __name__ == '__main__':
    plot_loss()
    model.save("model_clothes.h5")
