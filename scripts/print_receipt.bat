@echo off
chcp 65001 > nul
set PYTHONPATH=%~dp0
python -c "import sys; sys.path.insert(0, r'%~dp0'); exec(open(r'%~dp0print_receipt.py').read())" %*
