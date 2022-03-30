import tensorflow as tf
import keras
from tensorflow.keras.utils import to_categorical
from keras.preprocessing.image import ImageDataGenerator
from keras.layers import Conv2D,Dense,MaxPooling2D,Input,Flatten,Dropout
from keras.models import Sequential
import numpy as np
import cv2
import os
from model_pattern import model
import matplotlib.pyplot as plt 



# Use ImageDataGenerator to augment the data in real time during the training of the model
# For train set, data is transformed using various operations
# For validation set, the data is only rescaled to [0, 1]

train_datagen = ImageDataGenerator(rescale = 1./255, rotation_range = 350, shear_range = 30, horizontal_flip = True, vertical_flip = True, brightness_range = (0.75, 1.25), zoom_range = (0.8, 1), channel_shift_range = 50)
test_datagen = ImageDataGenerator(rescale = 1./255)


# Get the number of train and validation examples

train_size = sum([len(os.listdir('dataset_train_val/train/' + sub_folder)) for sub_folder in os.listdir('dataset_train_val/train') if sub_folder != '.DS_Store'])
val_size = sum([len(os.listdir('dataset_train_val/val/' + sub_folder)) for sub_folder in os.listdir('dataset_train_val/val') if sub_folder != '.DS_Store'])


# Define batch_size for train and validation sets, and the number of epochs

batch_size_train = 8
batch_size_val = 1
epochs = 5

# Build train and validation generators (to be passed into the model)

train_generator = train_datagen.flow_from_directory(
        'dataset_train_val/train',
        target_size = (128,128),
        batch_size = batch_size_train,
        class_mode = 'categorical',
        shuffle = True)

validation_generator = test_datagen.flow_from_directory(
        'dataset_train_val/val',
        target_size = (128,128),
        batch_size = batch_size_val,
        class_mode ='categorical',
        shuffle = True)


# train the model 

history = model.fit(
        train_generator,
        epochs = epochs,
        steps_per_epoch = train_size // batch_size_train,  # Number_of_samples / batch_size
        validation_data = validation_generator,
        verbose = True,
        validation_steps = val_size // batch_size_val # Number_of_samples / batch_size
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
    model.save("model_pattern.h5")
