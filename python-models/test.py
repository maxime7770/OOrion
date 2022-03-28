import os


print(sum([len(os.listdir('dataset_pattern/' + sub_folder)) for sub_folder in os.listdir('dataset_pattern') if sub_folder != '.DS_Store']))