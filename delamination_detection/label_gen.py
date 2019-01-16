from matplotlib import pyplot as plt
import matplotlib.cm as cm
import cv2 # used for resize. if you dont have it, use anything else
import numpy as np
import tensorflow as tf
from keras.models import load_model
from keras.preprocessing.image import ImageDataGenerator
from model import Deeplabv3
from model import relu6, BilinearUpsampling
import sys
from PIL import Image
import keras
import keras.backend as K
import glob
import os
import ntpath
from deep_defect_functions import *

# load deeplab v3 model in keras
deeplab_model = load_model('saved_models/training_scan4_2.h5',
                           custom_objects={'relu6':relu6,
                                           'BilinearUpsampling':BilinearUpsampling,
                                           'perDelam':perDelam,
                                           'predDelam':predDelam,
                                           'realDelam':realDelam,
                                           'iou_loss':iou_loss})

# set filepath of images to generate output predictions
script_path = os.getcwd()
img_dir = 'scan4_removed2/val/images/required'
full_img_dir = os.path.join(script_path,img_dir)

# iterate over images in filepath and save predictions into a directory
for filename in glob.glob(os.path.join(full_img_dir,'*.png')):
    save_name = ntpath.basename(filename)
    prediction_dir = os.path.join(script_path,'predictions',save_name)
    img = np.asarray(Image.open(filename))
    img_scale = customRescale(img)
    res = deeplab_model.predict(np.expand_dims(img_scale,0), batch_size=1)
    labels = np.argmax(res.squeeze(),-1)
    plt.imsave(prediction_dir, labels, cmap=cm.gray)
