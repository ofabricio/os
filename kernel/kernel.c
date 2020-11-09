void dummy_test_entrypoint()
{
    return;
}

int main()
{
    long *video_memory = (long *)0xB8000;
    *video_memory = 0x5050505050505050;
    return 0;
}
