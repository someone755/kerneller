# kernel installer


Inspired by AnyKernel, this tool allows Xperia kernels to be flashed to any ROM, regardless of the ramdisk used. This dramatically increases compatibility while decreasing size.

But, unlike AnyKernel, this kernel installer allows for the SELinux setting to be set at **the time of install**, based on the user's choice. For kernel developers this means only one zip has to be uploaded, instead of both a permissive and an enforcing variant. This also reduces user confusion, storage usage, and server load.

Although thoroughly tested on the Z3 and Z3C using TWRP, the tool still requires some testing on other devices and recoveries. As of this README's last commit, Cyanogen Recovery on the Z3C refuses to use keycheck as intended, therefore only enforcing images can be made from it.

This branch also features a simple 'pack' script that packs and signs the whole thing for you, making development that much easier.

Pull requests are, of course, appreciated.
