from matplotlib import pyplot as plt
import cv2 # used for resize. if you dont have it, use anything else
import numpy as np
import tensorflow as tf
from keras.models import load_model
from keras.preprocessing.image import ImageDataGenerator
from model import Deeplabv3
from model import relu6, BilinearUpsampling
import sys
import os
from PIL import Image
import keras
import keras.backend as K
from deep_defect_functions import *

# import keras deeplab trained model
deeplab_model = load_model('testing_delam.h5',
                           custom_objects={'relu6':relu6,
                                           'BilinearUpsampling':BilinearUpsampling,
                                           'perDelam':perDelam,
                                           'predDelam':predDelam,
                                           'realDelam':realDelam,
                                           'iou_loss':iou_loss})

# get directory
eval_dir = 'all_data/test'
eval_images = os.path.join(eval_dir,'images')
eval_masks = os.path.join(eval_dir,'masks')

# Set parameters
seed = 1000
batchSize = 4
target_height = 512
target_width = 640

# Prepare image data generator
image_datagen = ImageDataGenerator(preprocessing_function=customRescale)
mask_datagen = ImageDataGenerator()

# read images for evaluation
image_generator = image_datagen.flow_from_directory(
    eval_images,
    target_size=(target_height,target_width),
    batch_size=batchSize, # default is 32
    class_mode=None,
    seed=seed)

# read masks for evaluation
mask_generator = mask_datagen.flow_from_directory(
    eval_masks,
    batch_size=batchSize, # default is 32
    target_size=(target_height,target_width),
    class_mode=None,
    color_mode='grayscale',
    seed=seed)

# zip image and mask generator
eval_generator = zip(image_generator, mask_generator)

metrics = deeplab_model.evaluate_generator(
    eval_generator,
    steps=50,
    verbose=1
)

print(metrics)
