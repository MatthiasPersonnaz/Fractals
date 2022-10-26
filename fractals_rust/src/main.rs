use num_complex::Complex;
//use array2d::Array2D;
use image::{RgbImage, Rgb};
use std::time::{Duration, Instant};

fn main () {
    let c = Complex::new(-0.8, 0.156);

    let x_bounds: (f64, f64) = (-1.5, 1.5);
    let y_bounds: (f64, f64) = (-1.0, 1.0);

    let gridsize: u32 = 2048;
    let mut img = RgbImage::new(gridsize, gridsize);

    let max_iter: u8 = 80; // max number of iterations
    
    //let mut step_array = Array2D::filled_with(0, gridsize, gridsize);
    let start = Instant::now();


    for i in 0..gridsize-1 {
        for j in 0..gridsize-1 {
            let mut z = map_grid2comp(&x_bounds, &y_bounds, i as f64, j as f64, gridsize as f64);
            let mut iter: u8 = 0;
            while z.norm() < 2.0 && iter < max_iter {
                z = z*z + c;
                iter += 1;
            }
            //step_array[(i, j)] = iter;
            let brightening_factor = 1.5;
            img.put_pixel(i, j, Rgb([iter*brightening_factor as u8, iter*brightening_factor as u8, iter*brightening_factor as u8]));
        }
    }
    let duration = start.elapsed();
    println!("durée d'exécution du calcul: {:?} pour une grille {}x{}", duration, gridsize, gridsize);
    //println!("{:?}", step_array);
    img.save("julia.jpg").unwrap();
    
}

fn map_grid2comp(x_bounds: &(f64, f64), y_bounds: &(f64, f64), i: f64, j: f64, gridsize: f64) -> Complex::<f64> {
    Complex::new(x_bounds.0 + i *(x_bounds.1 - x_bounds.0) / gridsize,
                 y_bounds.0 + j *(y_bounds.1 - y_bounds.0) / gridsize)
}

