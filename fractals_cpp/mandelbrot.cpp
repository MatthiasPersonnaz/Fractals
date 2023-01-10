#include <complex>
#include <vector>
#include <string>
#include <iostream>
#include <fstream>
#include <cstdio>
#include <iomanip>
#include <cmath>
#include <chrono>


using std::endl, std::cout, std::vector;

int main(int argc, char ** argv)
{
    int n = atoi(argv[1]); // last argument after filename of executable
    const int gridSize = int(pow(2,n+9));
    std::cout << "Grid of size " << gridSize << endl;
    
    vector<vector<std::complex<double>>> complex_grid(gridSize, vector<std::complex<double>>(gridSize));
    vector<vector<bool>>                 results_grid(gridSize, vector<bool>(gridSize, false));



    double xmin = -2.;
    double xmax =   .5;
    double ymin = -1.25;
    double ymax =  1.25;
    int itermax = 30;


    double gsze = double(gridSize - 1);
    double spanx = (xmax - xmin)/gsze;
    double spany = (ymax - ymin)/gsze;

    std::cout << "Grid parameters:" << endl;
    std::cout << gridSize << "×" << gridSize << " pixels" << endl;
    std::cout << "x_min = " << xmin << endl;
    std::cout << "x_max = " << xmax << endl;
    std::cout << "y_min = " << ymin << endl;
    std::cout << "y_max = " << ymax << endl;
    std::cout << "Δx = " << spanx << endl;
    std::cout << "Δy = " << spany << endl;

    std::complex<double> c(.32, .411);

    std::cout << "Starting computing pixels convergence..." << endl;
    auto start_time = std::chrono::high_resolution_clock::now();
    for (int i = 0; i < gridSize; i++)
    {
        for (int j = 0; j < gridSize; j++)
        {
            std::complex<double> z(xmin + spanx*double(i), ymin + spany*double(j));
            int iter = 0;
            while (std::norm(z) <=4 and iter < itermax)
            {
                z = z * z + c;
                iter++;
            }
            complex_grid[i][j] = z;
            
            if (std::norm(z) <= 4)
            {
                results_grid[i][j] = true;
            }
        }
    }
    auto stop_time = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> duration = stop_time - start_time;

    std::cout << "Computed " << gridSize*gridSize << " pixels in " << duration.count() << " seconds i.e. " << gridSize*gridSize/duration.count() << " Mpx/s" << endl;

    std::string filename = "./image.pbm";


    std::ofstream ostrm(filename);
    ostrm << "P5 " << gridSize << " " << gridSize << " 255" << std::endl;
    for (auto i = 0; i < gridSize; i++)
    {
        for (auto j = 0; j < gridSize; j++)
        {
            if (results_grid[i][j])
            {
                ostrm.put(255);
            }
            else
            {
                ostrm.put(0);
            }
        }
    }
    ostrm.close();

    // std::cout << "Grid value at indices" << complex_grid[342][435] << endl;

    return 0;
};
