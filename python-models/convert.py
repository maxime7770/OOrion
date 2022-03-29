import tensorflow as tf
import os
import coremltools as ct



model = "model_pattern"   # Name of the model to be converted ("model_pattern" or "model_clothes")
file = model + ".h5"
new_model = tf.keras.models.load_model(file)

if model == "model_pattern":
    class_labels = [0,1,2]
else:
    class_labels = [i for i in range(7)]

classifier_config = ct.ClassifierConfig(class_labels)
_input =ct.ImageType(scale = 1./255)
mlmodel = ct.convert(new_model, inputs=[_input], classifier_config=classifier_config)

mlmodel.save(model + ".mlmodel")
