# imports
import numpy as np
import png
import warnings

warnings.filterwarnings("ignore") # ignore RuntimeWarning

# constants
WIDTH = 4000
HEIGHT = 3000
NB_ITER = 80
FILENAME = 'mandelbrot_py.png'

# code
def belongs_to_set(c):
    z = 0+0j
    for _ in range(NB_ITER):
        if abs(z) > 2:
            return False
        z = z**2 + c
    return True


def main():
    xs = np.linspace(-2.05, 0.75, num=WIDTH)
    ys = np.flip(np.linspace(-1.25, 1.25, num=HEIGHT))  # draw top to bottom
    plane = np.zeros(shape=(WIDTH, HEIGHT), dtype=np.uint8)

    for j, y in enumerate(ys):
        for i, x in enumerate(xs):
            if belongs_to_set(x + y*1j):
                plane[i][j] = 1
            else:
                plane[i][j] = 0

    with open(FILENAME, 'wb') as f:
        w = png.Writer(WIDTH, HEIGHT, greyscale=True, bitdepth=1)
        w.write(f, plane.T)


if __name__ == '__main__':
    main()
