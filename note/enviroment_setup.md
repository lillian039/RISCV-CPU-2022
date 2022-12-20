1. 换源：https://mirrors.sjtug.sjtu.edu.cn/docs/ubuntu （可以下tar就不用换)

2. 下载toolchain：https://jbox.sjtu.edu.cn/l/d1mbTU

3. 解压： [(144条消息) Linux解压缩tar.zst类型文件_Imagine Miracle的博客-CSDN博客_tar.zst](https://blog.csdn.net/qq_36393978/article/details/118221951)

    `tar -I zstd -xvf filename.tar.zst`，这个下载完解压完看下 riscv/bin 目录下该有的可执行文件有没有，建议文件放在wsl下

4. 个性化修改 Makefile build_test.sh

   修改build_test.sh`/10.1.0/`，给它权限 `chmod u+x build_test.sh` 

   然后就可以跑了 `./build_test.sh array_test1`

5. 修改Makefile 的命令位置，不然有bug

   `test_sim: build_sim build_sim_test run_sim`

   删去 `.vh`

