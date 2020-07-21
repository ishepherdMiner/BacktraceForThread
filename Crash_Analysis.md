# iOS崩溃采集与分析



思维导图



## 流程

* 采集
* 生成 && 上报
* 分析



## 采集





## 生成 && 上报



### 崩溃日志



#### 头部

```
Incident Identifier: B6FD1E8E-B39F-430B-ADDE-FC3A45ED368C
CrashReporter Key: f04e68ec62d3c66057628c9ba9839e30d55937dc
Hardware Model: iPad6,8
Process: TheElements [303]
Path: /private/var/containers/Bundle/Application/888C1FA2-3666-4AE2-9E8E-62E2F787DEC1/TheElements.app/TheElements
Identifier: com.example.apple-samplecode.TheElements
Version: 1.12
Code Type: ARM-64 (Native)
Role: Foreground
Parent Process: launchd [1]
Coalition: com.example.apple-samplecode.TheElements [402]
 
Date/Time: 2016-08-22 10:43:07.5806 -0700
Launch Time: 2016-08-22 10:43:01.0293 -0700
OS Version: iPhone OS 10.0 (14A5345a)
Report Version: 104
```



| 符号                | 说明                             |
| ------------------- | -------------------------------- |
| Incident Idnetifier | 崩溃日志唯一标志符               |
| CrashReporter Key   |                                  |
| Hardware Model      | 设备类型                         |
| Process             | 进程名                           |
| Path                | 可执行文件路径                   |
| Identifier          | 包名                             |
| Version             | 版本                             |
| Code Type           | CPU架构                          |
| Parent Process      | 当前进程的父进程,一般都是launchd |



#### 异常信息

```
Exception Type: EXC_BAD_ACCESS (SIGSEGV)
Exception Subtype: KERN_INVALID_ADDRESS at 0x0000000000000000
Termination Signal: Segmentation fault: 11
Termination Reason: Namespace SIGNAL, Code 0xb
```



| 符号               | 说明       |
| ------------------ | ---------- |
| Exception Type     | 异常类型   |
| Exception Subtype  | 异常子类型 |
| Termination Signal | 终止信号   |
| Termination Reason | 终止原因   |





#### 调用栈



##### 函数调用

###### 栈帧

每一次函数的调用,都会在调用栈(call stack)上维护一个独立的栈帧(stack frame).每个独立的栈帧一般包括:

* 函数的返回地址和参数
* 临时变量: 包括函数的非静态局部变量以及编译器自动生成的其他临时变量
* 函数调用的上下文 栈是从高地址向低地址延伸



![15932996806231.jpg](https://i.loli.net/2020/06/28/f57E6oSgrFw3UAQ.jpg)



###### 过程

* 参数入栈:从右到左依次入栈,
* 返回地址(LR)入栈:将当前代码区调用指令的下一条指令地址压入栈中，供函数返回时继续执行
* 代码跳转:处理器将代码区跳转到被调用函数的入口处
* 栈底(FP)入栈,调整SP重新指向栈顶地址
* FP = SP,更新FP寄存器,作为被调函数的栈底地址
* 返回地址保存到X0寄存器
* 调整SP指针,回收局部变量空间
* 将上一个栈底恢复到FP寄存器中
* 从栈中取出返回地址(LR),并跳转到该位置



##### 寄存器

###### ARM64

x0~x30是64位的通用整形寄存器,其中x0~x7常用来存放函数参数，更多的参数由堆栈传递，x0一般用做函数返回值，当返回值超过8个字节会保存在x0和x1中。

| 寄存器        | 含义                                     |
| ------------- | ---------------------------------------- |
| W0-W30/X0-X30 | 32/64位通用寄存器                        |
| WZR/XZR       | 32/64零寄存器                            |
| WSP/SP        | 32/64栈顶寄存器,指向函数分配栈空间的栈顶 |
| FP            | X29,指向函数分配栈空间的栈底             |
| LR            | X30,存储函数的返回地址                   |
| PC            | 当前指令地址                             |



###### 数据结构

```objc
_STRUCT_ARM_THREAD_STATE64
{
	__uint64_t __x[29]; /* General purpose registers x0-x28 */
	__uint64_t __fp;    /* Frame pointer x29 */
	__uint64_t __lr;    /* Link register x30 */
	__uint64_t __sp;    /* Stack pointer x31 */
	__uint64_t __pc;    /* Program counter */
	__uint32_t __cpsr;  /* Current program status register */
	__uint32_t __pad;   /* Same size for 32-bit or 64-bit clients */
};
```



##### 二进制





## 分析



## TODO清单



## 参考

1. [Parameters in general-purpose registers](https://developer.arm.com/docs/den0024/latest/the-abi-for-arm-64-bit-architecture/register-use-in-the-aarch64-procedure-call-standard/parameters-in-general-purpose-registers)