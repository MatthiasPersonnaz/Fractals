use num_complex::Complex;
use ndarray::{arr1, arr2, Array, Array1, Array2, ArrayView1, ArrayBase};
use itertools_num::linspace;
use itertools;
use meshgrid;

fn main () {
    let c:Complex<f64> = Complex::new(0.343, 0.12);
    let x_min: f64   = -1.5;
    let x_max: f64   =  1.5;
    let y_min: f64   = -1.0;
    let y_max: f64   = 1.0;
    let x_bound_bundle: (f64, f64) = (x_min, x_max);
    let y_bound_bundle: (f64, f64) = (y_min, y_max);
    let n:usize      = 10; // grid size
    let n_i32:i32    = n as i32;
    let max_iter:i32 = 100; 
    

    let mut real_array = Array2::<f64>::zeros((n,n));
    let mut imag_array = Array2::<f64>::zeros((n,n));
    let mut step_array = Array2::<i32>::zeros((n,n));

    for &(i,j) in meshgrid::new(0..n_i32-1, 0..n_i32-1).iter() {
        let mut z = map_grid_comp_nb(&x_bound_bundle, &y_bound_bundle, i, j, n_i32);
        let mut n_step:i32 = 0;
        while z.norm() < 4.0 && n_step < max_iter {
            z = z*z + c;
            n_step = n_step + 1;
        }
        let zre = z.re.round(); let zim = z.im.round();

        step_array[(i as usize, j as usize)] = n_step;
        real_array[(i as usize, j as usize)] = zre;
        imag_array[(i as usize, j as usize)] = zim;
    }
    println!("{:?}", real_array);
    println!("{:?}", step_array);


    
}


fn print_type_of<T>(_: &T) {
    println!("{}", std::any::type_name::<T>());
}

fn map_grid_comp_nb(x:&(f64, f64), y:&(f64, f64), i:i32, j:i32, n:i32) -> Complex::<f64> {
    Complex::new(&x.0 + (i as f64)*(&x.1-&x.0)/(n as f64),
                        &y.0 + (j as f64)*(&y.1-&y.0)/(n as f64))
}

