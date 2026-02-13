#include <iostream>

int main() {
  std::cout << "Hello, World!" << std::endl;
  std::cout << "Information from CMake:" << std::endl;
  #if defined(PROJECT_NAME) && defined(PROJECT_VERSION)
  std::cout << "Project Name is " << PROJECT_NAME << " and Project Version is "
            << PROJECT_VERSION << std::endl;
  #endif
  // Compiler version check
#if defined(__clang__)
  std::cout << "Compiler: Clang" << std::endl;
  std::cout << "Version: " << __clang_major__ << "." << __clang_minor__ << "."
            << __clang_patchlevel__ << std::endl;
#elif defined(__GNUC__)
  std::cout << "Compiler: GCC" << std::endl;
  std::cout << "Version: " << __GNUC__ << "." << __GNUC_MINOR__ << "."
            << __GNUC_PATCHLEVEL__ << std::endl;
#else
  std::cout << "Unknown compiler" << std::endl;
#endif
    // std::cout << "__cplusplus = " << __cplusplus << std::endl;

#if __cplusplus == 199711L
    std::cout << "C++98/03\n";
#elif __cplusplus == 201103L
    std::cout << "C++11\n";
#elif __cplusplus == 201402L
    std::cout << "C++14\n";
#elif __cplusplus == 201703L
    std::cout << "C++17\n";
#elif __cplusplus == 202002L
    std::cout << "C++20\n";
#else
    std::cout << "Newer C++ version or unknown\n";
#endif

// Display compilation mode
#ifdef _DEBUG
  std::cout << "Debug mode (_DEBUG is defined)" << std::endl;
#elif defined(NDEBUG)
  std::cout << "Release mode (NDEBUG is defined)" << std::endl;
#else
  std::cout << "Debug mode (NDEBUG is not defined)" << std::endl;
#endif

  // Display bit sizes of fundamental types
  std::cout << "Size of char *: " << sizeof(char *) * 8 << " bits" << std::endl;
  std::cout << "Size of int: " << sizeof(int) * 8 << " bits" << std::endl;
  std::cout << "Size of long: " << sizeof(long) * 8 << " bits" << std::endl;
  std::cout << "Size of float: " << sizeof(float) * 8 << " bits" << std::endl;
  std::cout << "Size of double: " << sizeof(double) * 8 << " bits" << std::endl;

  std::cout << "\ntarget_compile_definitions:"
            << "\nProject Name: " << PROJECT_NAME
            << "\nProject Version: " << PROJECT_VERSION
            << "\nONE_ = " << ONE_
            << "\nTWO = " << TWO_
            << "\nTHREE = " << THREE_ << std::endl;

  std::cout << "\nset_source_files_properties:\nmain.cpp PROPERTIES \n"
            << "MAIN_FILE_=\"" << MAIN_FILE_ << "\" \n"
            << "MSG1=\"" << MSG1 << "\" \n"
            << "MSG2=\"" << MSG2 << "\" \n"
            << std::endl;

  return 0;
}
