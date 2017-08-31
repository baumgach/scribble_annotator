# Scribble Annotator

This is a MATLAB UI created to reannotate MRI images with 'scribbles'
in order to use the [ACDC Dataset](https://www.creatis.insa-lyon.fr/Challenge/acdc/databases.html)
with a weakly supervised CNN

Author: Basil Mustafa ([email](mailto:bm490@cam.ac.uk))

# Usage
The main script is ```freehand_scribble.m```, which takes in an image, 
ground truth and current scribble as inputs and provides a UI to annotate them.

```scribble_hdf5.m``` and ```scribble_niifti.m```  are examples which interface
with the scribble annotator - these will likely have to be heavily modified/
rewritten to match your data structure.

## Future Work
* Currently have to input an array of zeros if there is no _current scribble_ - 
should adjust ```freehand_scribble.m``` to automatically use blank array of size
matching the ground truth if there is no input given