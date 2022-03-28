
#############

# Execute this file to create a new folder 'dataset_train_val' with 2 subfolders 'train' and 'val' that contain data from
# the different classes for pattern detection

# To be executed before train_pattern

#############


import splitfolders

splitfolders.ratio('dataset', output='dataset_train_val', seed=1337, ratio=(.8, 0.2)) 
