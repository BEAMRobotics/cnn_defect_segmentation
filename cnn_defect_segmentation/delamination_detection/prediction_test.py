from matplotlib import pyplot as plt
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
from deep_defect_functions import *

# load trained deeplab model
deeplab_model = load_model('saved_models/training_7.h5',
                           custom_objects={'relu6':relu6,
                                           'BilinearUpsampling':BilinearUpsampling,
                                           'perDelam':perDelam,
                                           'predDelam':predDelam,
                                           'realDelam':realDelam,
                                           'iou_loss':iou_loss})

# Set image to view prediction
# current format is (samples, height, width, channels) for input image sets
img = np.asarray(Image.open('normal_data/val/images/required/ir_000350.png'))
img_mask = np.asarray(Image.open('normal_data/val/masks/required/ir_000350.png'))

# rescale image pixels between -1 and 1
img_scale = customRescale(img)
plt.subplot(1,3,1)

### OPTIONAL - code to zero pad
#plt.subplot(1,2,2)
#plt.imshow(img_mask)
#plt.show()
# w, h, _ = img.shape
# ratio = 512. / np.max([w,h])
# resized = cv2.resize(img,(int(ratio*h),int(ratio*w)))
# mask_resized = cv2.resize(img_mask,(int(ratio*h),int(ratio*w)))
# # resized = customRescale(resized)
# # pad_x = int(512 - resized.shape[0])
# # resized2 = np.pad(resized,((0,pad_x),(0,0),(0,0)),mode='constant')
# resized2, pad_x = zeroPad(img, 512, True)
# resized2 = customRescale(resized2)
# mask_resized = zeroPad(np.expand_dims(img_mask, axis=2), 512, False)
# res = deeplab_model.predict(np.expand_dims(resized2,0))
# labels = np.argmax(res.squeeze(),-1)
### OPTIONAL - end

# calculate output scores from model
res = deeplab_model.predict(np.expand_dims(img_scale,0), batch_size=1)
# take the argmax to one hot encode
labels = np.argmax(res.squeeze(),-1)
print(labels.shape)
print(sum(sum(img_mask)))
print(sum(sum(labels)))
print(mIOU(img_mask,labels))

# Display image, mask and prediction
# display image
plt.imshow(img)
plt.axis('off')
plt.title('Original Image')
# plt.rcParams.update({'font.size': 30})
# display mask
plt.subplot(1,3,2)
plt.imshow(img_mask)
plt.axis('off')
plt.title('True Label (Image Mask)')
# display predictions
plt.subplot(1,3,3)
plt.imshow(labels)
plt.axis('off')
plt.title('Prediction')
plt.show()
