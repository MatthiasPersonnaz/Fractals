use num_complex::Complex;
use image::{RgbImage, Rgb};
use std::time::Instant;

fn main () {
    let c = Complex::new(-0.8, 0.156);

    let x_bounds: (f64, f64) = (-1.5, 1.5);
    let y_bounds: (f64, f64) = (-1.0, 1.0);

    let gridsize: u32 = 4000;
    
    let mut img = RgbImage::new(gridsize, gridsize);
    let brightening_factor: f64 = 1.5;

    let max_iter: u8 = 100; // max number of iterations
    
    let start = Instant::now();
    for i in 0..gridsize-1 {
        for j in 0..gridsize-1 {
            let mut z = map_grid2comp(&x_bounds, &y_bounds, i as f64, j as f64, gridsize as f64);
            let mut iter: u8 = 0;
            while z.norm() < 2.0 && iter < max_iter {
                z = z*z + c;
                iter += 1;
            }
            let grey: u8 = iter*brightening_factor as u8;
            img.put_pixel(i, j, Rgb([grey, grey, grey]));
        }
    }
    let duration: f64 = start.elapsed().as_secs_f64();
    println!("durée d'exécution du calcul: {duration:.3}s pour une grille {gridsize}x{gridsize}");

    img.save("julia.jpg").unwrap();
    
}

fn map_grid2comp(x_bounds: &(f64, f64), y_bounds: &(f64, f64), i: f64, j: f64, gridsize: f64) -> Complex::<f64> {
    Complex::new(x_bounds.0 + i *(x_bounds.1 - x_bounds.0) / gridsize,
                 y_bounds.0 + j *(y_bounds.1 - y_bounds.0) / gridsize)
}

