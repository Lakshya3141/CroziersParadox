#include <iostream>
#include "Population.hpp"
#include <iomanip> // For std::setprecision
#include <sstream> // For std::ostringstream

int main(int argc, char* argv[]) {
  // Prints parameters values
  try {
    std::string file_name = (argc > 2) ? argv[1] : "config.ini";
    std::cout << "Global Parameters:" << std::endl;
    std::cout << "max_gtime_evolution = " << max_gtime_evolution << std::endl;
    std::cout << "Pop removal time = " << dRemovalTime << std::endl;
    std::cout << "Food restock time = " << dTickTime << std::endl;
    std::cout << "Pop recording time = " << dOutputTime << std::endl;
    std::cout << "Fraction dead nests rec =" << dFracDeadNest << std::endl;
    std::cout << "End Simulation for inds =" << dFracLastIndRecord << std::endl;
    std::cout << "[dInitIntercept, dInitSlope] = [" << dInitIntercept << " , " << dInitSlope << "]" << std::endl;
    std::cout << "Coevolving = " << bIsCoevolve << std::endl;
    std::cout << "Reading from config file: " << file_name << "\n";
    std::ifstream test_file(file_name.c_str());
    if (!test_file.is_open()) {
      throw std::runtime_error("can't find config file");
    }
    test_file.close();

    // create output folder if doesnt exist
    std::string folderName = "output_sim";
    if (!fs::exists(folderName)) {
      if (fs::create_directory(folderName)) {
        std::cout << "Folder '" << folderName << "' created successfully.\n";
      } else {
        std::cerr << "Error: Failed to create folder '" << folderName << "'.\n";
        return 1; // Return error code
      }
    } else {
      std::cout << "Folder '" << folderName << "' already exists.\n";
    }

    params sim_par_in(file_name);
    sim_par_in.print_string_vals();
    exportParametersToCSV(sim_par_in);

    auto start = std::chrono::high_resolution_clock::now();
    
    Population myPop(sim_par_in);
    myPop.initialise_pop();

    std::cout << std::fixed;
    std::cout << std::setprecision(2);
    myPop.simulate(myPop.p.param_names_to_record);

    auto end = std::chrono::high_resolution_clock::now();
    auto diff = end - start;
    std::cout << std::endl;
    std::cout << "Initial population simulation took " << std::chrono::duration<double>(diff).count() << " seconds" << std::endl;
    return 0;
  }
  catch (const std::exception& err) {
    std::cerr << err.what() << '\n';
  }
  catch (const char* err) {
    std::cerr << err << '\n';
  }
  catch (...) {
    std::cerr << "unknown exception\n";
  }
  std::cerr << "bailing out.\n";

  return -1;
}