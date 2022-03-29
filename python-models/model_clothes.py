import numpy as np
import tensorflow as tf
from keras.preprocessing.image import ImageDataGenerator
from keras.layers import Dense, MaxPooling2D, Conv2D, Input, Flatten, Dropout
from keras.models import Sequential


# Input shape of the images

shape=(128, 128, 3)


model=Sequential()
model.add(Input(shape=shape, name = 'input_6'))

# First block 

model.add(Conv2D(16, kernel_size=(3,3), activation="relu"))
model.add(MaxPooling2D((2,2)))

# Second block

model.add(Conv2D(32, kernel_size=(3,3), activation="relu"))
model.add(MaxPooling2D((2,2)))

# Third block

model.add(Conv2D(64, kernel_size=(3,3), activation="relu"))
model.add(MaxPooling2D((2,2)))

# Flatten and dense layers with dropout to reduce overfitting

model.add(Flatten())

model.add(Dense(64, activation='relu'))
model.add(Dropout(0.5))

model.add(Dense(32, activation='relu'))
model.add(Dropout(0.5))

model.add(Dense(7, activation='softmax'))

model.compile(optimizer = 'adam', loss = 'categorical_crossentropy', metrics = ['accuracy'])
model.summary()
 
