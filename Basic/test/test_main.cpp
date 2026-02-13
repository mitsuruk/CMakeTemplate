// License: MIT License
#include <gtest/gtest.h>
#include <gmock/gmock.h>

// Define simple functions for testing
int add(int a, int b) {
    return a + b;
}

int multiply(int a, int b) {
    return a * b;
}

// Basic test cases
TEST(BasicTest, Addition) {
    EXPECT_EQ(add(2, 3), 5);
    EXPECT_EQ(add(-1, 1), 0);
    EXPECT_EQ(add(0, 0), 0);
}

TEST(BasicTest, Multiplication) {
    EXPECT_EQ(multiply(2, 3), 6);
    EXPECT_EQ(multiply(-2, 3), -6);
    EXPECT_EQ(multiply(0, 100), 0);
}

// String test
TEST(StringTest, BasicStringOperations) {
    std::string str = "Hello, World!";
    EXPECT_EQ(str.length(), 13);
    EXPECT_TRUE(str.find("World") != std::string::npos);
}

// GoogleTest main function
int main(int argc, char **argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
