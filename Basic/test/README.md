# How to Use GoogleTest

This directory contains test code using GoogleTest.

## Build and Test Execution Instructions

### 1. Build (Enable GTEST option)

```bash
cd /path/to/Basic
cmake -DGTEST=true -B build
cmake --build build
```

### 2. How to Run Tests

#### Method 1: Using ctest (Recommended)

```bash
cd build
ctest                      # Concise output
ctest --verbose            # Detailed output
ctest --output-on-failure  # Show details only on failure
```

#### Method 2: Run the test executable directly

```bash
./build/a.out.out
```

## Test Code Description

`test_main.cpp` contains the following tests:

- **BasicTest.Addition**: Addition test
- **BasicTest.Multiplication**: Multiplication test
- **StringTest.BasicStringOperations**: String operations test

## Expected Output

### When running ctest

```
Test project /path/to/Basic/build
    Start 1: a.out.out_tests
1/1 Test #1: a.out.out_tests ..................   Passed    0.01 sec

100% tests passed, 0 tests failed out of 1

Total Test time (real) =   0.01 sec
```

### When running directly

```
[==========] Running 3 tests from 2 test suites.
[----------] Global test environment set-up.
[----------] 2 tests from BasicTest
[ RUN      ] BasicTest.Addition
[       OK ] BasicTest.Addition (0 ms)
[ RUN      ] BasicTest.Multiplication
[       OK ] BasicTest.Multiplication (0 ms)
[----------] 2 tests from BasicTest (0 ms total)

[----------] 1 test from StringTest
[ RUN      ] StringTest.BasicStringOperations
[       OK ] StringTest.BasicStringOperations (0 ms)
[----------] 1 test from StringTest (0 ms total)

[----------] Global test environment tear-down
[==========] 3 tests from 2 test suites ran. (0 ms total)
[  PASSED  ] 3 tests.
```

## How to Add New Tests

Add a new test case to `test_main.cpp`:

```cpp
TEST(YourTestSuite, YourTestCase) {
    EXPECT_EQ(your_function(), expected_value);
}
```
