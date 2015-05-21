#!/bin/bash

find lib/ -iname "*.h" | xargs python3 add_bsd.py
find matlab/ -iname "*.cpp" | xargs python3 add_bsd.py
find matlab/ -iname "*.m" | xargs python3 add_bsd.py
find lib/ -iname "*.cpp" | xargs python3 add_bsd.py
find src/ -iname "*.py" | xargs python3 add_bsd.py
