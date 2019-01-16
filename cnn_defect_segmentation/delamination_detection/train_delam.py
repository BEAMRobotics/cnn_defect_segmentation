from matplotlib import pyplot as plt
import cv2 # used for resize. if you dont have it, use anything else
import numpy as np
import keras
from keras import layers
from keras import optimizers
import keras.backend as K
from keras.preprocessing.image import ImageDataGenerator
import tensorflow as tf
from model import Deeplabv3
from PIL import Image
from deep_defect_functions import *
import sys
import os

# import keras Deeplabv3 model
deeplab_model = Deeplabv3(input_shape=(512,640,3),classes=2)

# setup directories for validation and training data
val_dir = 'normal_data/val'
train_dir = 'normal_data/train'
val_images = os.path.join(val_dir,'images')
val_masks = os.path.join(val_dir,'masks')
train_images = os.path.join(train_dir,'images')
train_masks = os.path.join(train_dir,'masks')

# unfreeze = False
# counter = 0
#
# for layer in deeplab_model.layers:
#     # keep track of layers
#     counter +=1
#     print(counter)
#     print(layer)
#
#     if unfreeze:
#         layer.trainable = True
#     else:
#         layer.trainable = False
#
#     if counter == 356:
#         unfreeze = True

# compile model loss function, optimizer algorithm, and set tracking metrics
deeplab_model.compile(loss='sparse_categorical_crossentropy',

                      optimizer=optimizers.SGD(lr=0.005,
                                               momentum=0.9,
                                               decay=0.005/200),
                      metrics=[iou_loss])

# OPTIONAL: Display summary of model architecture
deeplab_model.summary()

# create dict with augmentation arguements for image
data_gen_args_image = dict(horizontal_flip=True,
                           vertical_flip=True,
                           width_shift_range=0.2,
                           height_shift_range=0.2,
                           zoom_range=0.2,
                           rotation_range=45,
                           preprocessing_function=customRescale
                           )

# same augmentation arguements except preprocessing_function for mask
data_gen_args_mask = dict(horizontal_flip=True,
                          vertical_flip=True,
                          width_shift_range=0.2,
                          height_shift_range=0.2,
                          zoom_range=0.2,
                          rotation_range=45
                          )

# create instances for loading the training and validation data
train_image_datagen = ImageDataGenerator(**data_gen_args_image)
train_mask_datagen = ImageDataGenerator(**data_gen_args_mask)

val_image_datagen = ImageDataGenerator(preprocessing_function=customRescale)
val_mask_datagen = ImageDataGenerator()

# Provide the same seed and keyword arguments to the fit and flow methodstesting_delam
seed = 1000
batchSize = 4
target_height = 512
target_width = 640

train_image_generator = train_image_datagen.flow_from_directory(
    train_images,
    target_size=(target_height,target_width),
    batch_size=batchSize, # default is 32, but we only have 25 images
    class_mode=None,
    seed=seed)

train_mask_generator = train_mask_datagen.flow_from_directory(
    train_masks,
    batch_size=batchSize, # default is 32, but we only have 25 images
    target_size=(target_height,target_width),
    class_mode=None,
    color_mode='grayscale',
    seed=seed)

val_image_generator = val_image_datagen.flow_from_directory(
    val_images,
    target_size=(target_height,target_width),
    batch_size=2, # default is 32
    class_mode=None,
    seed=seed)

val_mask_generator = val_mask_datagen.flow_from_directory(
    val_masks,
    batch_size=2, # default is 32
    target_size=(target_height,target_width),
    class_mode=None,
    color_mode='grayscale',
    seed=seed)


# import matplotlib.pyplot as plt
# import matplotlib.image as mpimg
#
# from tensorflow.keras.preprocessing.image import array_to_img, img_to_array, load_img
#
# mask_dir = 'delam_data/val/masks/required'
# mask_dir_fnames = os.listdir(mask_dir)
#
# img_path = os.path.join(mask_dir, mask_dir_fnames[2])
# img = load_img(img_path, target_size=(512, 512))  # this is a PIL image
# x = img_to_array(img)
# print(x.shape)
# x = x.reshape((1,) + x.shape)  # Numpy array with shape (1, h, w, c)
#
# # The .flow() command below generates batches of randomly transformed images
# # It will loop indefinitely, so we need to `break` the loop at some point!
# i = 0
# for batch in train_mask_datagen.flow(x, batch_size=1):
#   plt.figure(i)
#   imgplot = plt.imshow(array_to_img(batch[0]))
#   plt.show()
#   i += 1
#   if i % 5 == 0:
#     break

# img = plt.imread('data/images/required/ir_000033.png')
# img_mask = plt.imread('data/masks/required/ir_000033_mask.png')
# plt.subplot(1,2,1)
# plt.imshow(img)
# plt.subplot(1,2,2)
# plt.imshow(img_mask)
# plt.show()

# img = Image.open('data/masks/required/ir_000020_mask.png')
# img2 = Image.open('data/images/required/ir_000020.png')
# print(np.array(img).shape)
# print(np.array(img2).shape)

# combine generators into one which yields image and masks
train_generator = zip(train_image_generator, train_mask_generator)
validation_generator = zip(val_image_generator, val_mask_generator)

# train the model using the loaded data
history = deeplab_model.fit_generator(
    train_generator,
    steps_per_epoch=100, # usually set equal to num samples / batch size
    epochs=50,
    validation_data=validation_generator,
    validation_steps=25,
    verbose=2)

# Ask user if he/she wishes to save the model
while True:
    saveFlag = str(input('Do you want to save the model? (y/n):'))
    #saveFlag = 'y'
    # check if user has entered einotationther a y or n
    if saveFlag.lower() == 'y' or saveFlag.lower() == 'n':
        break # exit the loop if the input is valid
    else:
        print('Please input only y or n') # get user to try again

# check if the user wants to save this model
if saveFlag.lower() == 'y':
    deeplab_model.save('testing_delam.h5') # save the model

# img = np.asarray(Image.open('delam_data/train/images/required/ir_000325.png'))
# img_mask = np.asarray(Image.open('delam_data/train/masks/required/ir_000325.png'))
# # current format is (samples, height, width, channels) for input image sets
# print(img.shape)
# img_scale = customRescale(img)
# plt.subplot(1,3,1)
# res = deeplab_model.predict(np.expand_dims(img_scale,0), batch_size=1)
# labels = np.argmax(res.squeeze(),-1)
# print(labels.shape)
# print(sum(sum(img_mask)))
# print(sum(sum(labels)))
# print(mIOU(img_mask,labels))
# plt.imshow(img)
# plt.subplot(1,3,2)
# plt.imshow(labels)
# plt.subplot(1,3,3)
# plt.imshow(img_mask)
# plt.show()

# Retrieve a list of accuracy results on training and test data
# sets for each training epoch
mIOU = history.history['iou_loss']
val_mIOU = history.history['val_iou_loss']

# Retrieve a list of list results on training and test data
# sets for each training epoch
loss = history.history['loss']
val_loss = history.history['val_loss']

# Get number of epochs
epochs = range(len(mIOU))

# Plot training and validation accuracy per epoch
plt.subplot(1,2,1)
plt.plot(epochs, mIOU, label='Train')
plt.plot(epochs, val_mIOU, label='Validation')
plt.title('Training and validation mIOU')
plt.ylabel('mIOU')
plt.xlabel('Epochs')
plt.legend()

# Plot training and validation loss per epoch
plt.subplot(1,2,2)
plt.plot(epochs, loss, label='Train')
plt.plot(epochs, val_loss, label='Validation')
plt.title('Training and validation loss')
plt.ylabel('Loss')
plt.xlabel('Epochs')
plt.legend()

plt.show()
