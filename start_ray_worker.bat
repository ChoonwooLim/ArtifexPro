@echo off
echo =====================================
echo Starting Ray Worker on Windows
echo =====================================

REM Python 및 Ray 설치 확인
pip install -q ray[default] torch

REM Ray Worker 시작 (Windows GPU)
ray stop
ray start --address=192.168.219.150:6379 --num-gpus=1

echo.
echo Ray Worker connected to cluster!
echo Check dashboard at: http://192.168.219.150:8265
pause