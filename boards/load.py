import sys
from pynq import Overlay

fname = sys.argv[1]
ol = Overlay(fname)
print("Overlay is loaded: ", ol.is_loaded)