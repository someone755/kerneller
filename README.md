# kernel installer


Inspired by AnyKernel, this tool allows Xperia kernels to be flashed to any ROM, regardless of the ramdisk used. This dramatically increases compatibility while decreasing size.

But, unlike AnyKernel, this kernel installer allows for the SELinux setting to be set at **the time of install**, based on the user's choice. For kernel developers this means only one zip has to be uploaded, instead of both a permissive and an enforcing variant. This also reduces user confusion, storage usage, and server load.

Although thoroughly tested on the Z3 and Z3C using TWRP, the tool still requires some testing on other devices and recoveries. Pull requests are appreciated.

I'll leave the packing up to you. Though you're more than welcome to use the mkbootimg_tools branch to easily pack things up.
