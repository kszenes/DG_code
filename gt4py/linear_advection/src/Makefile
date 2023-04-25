.PHONY: all numpy cpu gpu
all: numpy

numpy:
	python main.py -n 20 -p 1 -rk 1 -b numpy

cpu:
	python main.py -n 20 -p 1 -rk 1 -b gt:cpu_ifirst

gpu:
	python main.py -n 20 -p 1 -rk 1 -b gt:gpu