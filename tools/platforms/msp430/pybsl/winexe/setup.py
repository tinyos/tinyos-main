# setup.py
from distutils.core import setup
import glob, sys, py2exe, os

sys.argv.append("sdist")
sys.argv.append("py2exe")

setup(
    name='pybsl',
    version='0.5',
    options = {"py2exe":
        {
            'dist_dir': 'bin',
            'excludes': ['javax.comm'],
        }
    },
    console = ["tos-bsl"],
    zipfile = "lib/shared-bsl.zip",
)

if os.path.exists('bin/bsl.exe'):
    if os.path.exists('bin/msp430-bsl.exe'):
        os.remove('bin/msp430-bsl.exe')
    os.rename('bin/bsl.exe', 'bin/msp430-bsl.exe')
