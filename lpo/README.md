Learning to propose objects
===========================

This implements the learning and inference/proposal algorithm described in "Learning to Propose Objects, Krähenbühl and Koltun, CVPR 2015".

#### Dependencies:
 * c++11 compiler (gcc >= 4.7)
 * cmake
 * boost-python
 * python (2.7 or 3.1+ should both work)
 * numpy
 * libmatio (optional)
 * libpng, libjpeg
 * Eigen 3 (3.2.0 or newer)
 * OpenMP (optional but recommended)

#### Compilation:
 Go to the top level directory
```bash
mkdir build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release -DDATA_DIR=/path/to/datasets -DUSE_PYTHON=ON
make -j9
```
Here "-DUSE_PYTHON" specifies that the python wrapper should be built (highly recommended). You can use python 2.7 by specifying "-DUSE_PYTHON=2", any other argument will try to build a python 3 wrapper.

The flag "-DDATA_DIR=/path/to/datasets" is optional and can point to a directory containing the VOC2012, VOC2007 or COCO datset. Specify this path if you want to train or evaluate LPO on those dataset.

"/path/to/datasets" can be any directory containing subdirectories:
 * 'VOC2012/ImageSets'
 * 'VOC2012/SegmentationClass',
 * 'VOC2012/Annotations'
 * 'COCO/train2014'
 * 'COCO/val2014'
 * ...

and files:
 * 'COCO/instances_train2014.json'
 * 'COCO/instances_val2014.json'.

The coco files can be downloaded from http://mscoco.org/, the PASCAL VOC dataset http://pascallin.ecs.soton.ac.uk/challenges/VOC/voc2012/index.html .

The code should compile and run fine on both Linux and Mac OS, let me know if you have any difficulty or find a bug. For Windows you're on your own.

#### Experiments

The code to reproduce most results in the paper is included here. All experiments should be run from the `src` directory.

To generate the main comparison in table 3 run:
```bash
bash eval_all.sh
```

To analyze a model like table 2 run:
```bash
python analyze_model.py path/to/model
```

To do the bounding box evaluation call:
```bash
python eval_box.py path/to/output_file path/to/model1 path/to/model2 path/to/model3 path/to/model4
```
This will create a binary file measuring number of proposals vs best overlap per object. You can then use the `results/box.py` script to generate the bounding box evaluation and produce the plots. For your convenience we included the precomputed results of many prior methods on VOC 2012 in `results/box/*.dat`.

#### Citation

If you're using this code in a scientific publication please cite:
```
@inproceedings{kk-lpo-15,
  author    = {Philipp Kr{\"{a}}henb{\"{u}}hl and
               Vladlen Koltun},
  title     = {Learning to Propose Objects},
  booktitle = {CVPR},
  year      = {2015},
}
```

#### License
All my code is published under a BSD license, so feel free to reuse and/or share it. There are some dependencies which are under different licenses and/or patented. All those dependencies are located in the `external` directory.
