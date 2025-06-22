int test(int cond1, int x, int cond2, int y)
{
    int a = cond1 ? 5 * x : x + 1;
    int b = cond2 ? 3 * y : y - 1;
    return a + b;
}
