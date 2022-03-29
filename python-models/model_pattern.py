import tensorflow as tf
import keras
from tensorflow.keras.utils import to_categorical
from keras.preprocessing.image import ImageDataGenerator
from keras.layers import Conv2D,Dense,MaxPooling2D,Input,Flatten,Dropout
from keras.models import Sequential
import numpy as np
import cv2
import os


# Input shape of the images

shape=(128, 128, 3)


model=Sequential()
model.add(Input(shape=shape))

# First block

model.add(Conv2D(16, kernel_size=(3,3), activation="relu"))
model.add(Conv2D(16, kernel_size=(3,3), activation="relu"))
model.add(MaxPooling2D((2,2)))

# Second block

model.add(Conv2D(32, kernel_size=(3,3), activation="relu"))
model.add(Conv2D(32, kernel_size=(3,3), activation="relu"))
model.add(MaxPooling2D((2,2)))

# Third block

model.add(Conv2D(32, kernel_size=(3,3), activation="relu"))
model.add(Conv2D(32, kernel_size=(3,3), activation="relu"))
model.add(MaxPooling2D((2,2)))

# Flatten and dense layers

model.add(Flatten())

model.add(Dense(64, activation='relu'))
model.add(Dense(3, activation='sigmoid'))    # Sigmoid activation for multi-labels classification

model.compile(optimizer = 'adam', loss = 'binary_crossentropy', metrics = ['accuracy'])
model.summary()