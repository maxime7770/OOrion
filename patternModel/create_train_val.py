
#############

# Execute this file to create a new folder 'dataset_train_val' with 2 folders 'train' and 'val' that contain data from
# the different classes

# Execute this file before training the model

#############


import splitfolders

splitfolders.ratio('dataset', output='dataset_train_val', seed=1337, ratio=(.8, 0.2)) 
