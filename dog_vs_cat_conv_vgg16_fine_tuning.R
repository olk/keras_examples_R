# MIT License
# 
# Copyright (c) 2017 François Chollet
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

library(keras)

# use pretrained VGG16 model
conv_base <- application_vgg16(weights="imagenet", # from which to initialize the weights
                               include_top=FALSE, # do not include the dense connected classifier on top of the network
                               input_shape=c(150, 150, 3)) # shape of the image tensor the will be feed to the network

unfreeze_weights(conv_base, from = "block3_conv1")

# build model; densly connected classifier
model <- keras_model_sequential() %>%
    conv_base %>%
    layer_flatten() %>%
    layer_dense(units=256, activation="relu") %>%
    layer_dense(units=1, activation="sigmoid")


base_dir <- "~/Downloads/cats_and_dogs_small"
train_dir <- file.path(base_dir, "train")
validation_dir <- file.path(base_dir, "validation")
test_dir <- file.path(base_dir, "test")

# data augmentation generates more training data from existing training samples
# by augmenting samples via a number of random transformations
# -> the model does NOT see the exact sampe picture twice
# `imange_data_generator()` converts image files on disk into batches of preprocessed tensors
train_datagen <- image_data_generator(rescale=1/255, # rescale images to range [0,1]
                                      rotation_range=40, # andomly rotate image; range [[0°,180°]
                                      width_shift_range=0.2, # randomly translate image horizontal
                                      height_shift_range=0.2, # randomly translate image vertically
                                      shear_range=0.2, # randomly apply hear transformations
                                      zoom_range=0.2, # randomly toom into image
                                      horizontal_flip=TRUE,# strategy for filling in newly created pixels
                                      fill_mode="nearest")
test_datagen <- image_data_generator(rescale=1/255)

train_generator <- flow_images_from_directory(train_dir, # target directory
                                              train_datagen, # data generator
                                              target_size=c(150, 150), # resize all images to 150x150
                                              batch_size=20,
                                              class_mode="binary") # binary_crossentropy loss function requires binary labels
validation_generator <- flow_images_from_directory(validation_dir,
                                                   test_datagen,
                                                   target_size=c(150, 150),
                                                   batch_size=20,
                                                   class_mode="binary")

model %>% compile(optimizer=optimizer_rmsprop(lr=1e-5),
                  loss="binary_crossentropy",
                  metrics=c("accuracy"))

history <- model %>% fit_generator(train_generator,
                                   steps_per_epoch=100,
                                   epochs=100,
                                   validation_data=validation_generator,
                                   validation_steps=50)

plot(history)
