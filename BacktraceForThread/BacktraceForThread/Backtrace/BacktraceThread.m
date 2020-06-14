//
//  BacktraceThread.m
//  BacktraceForThread
//
//  Created by Shepherd on 2020/6/14.
//  Copyright © 2020 Shepherd. All rights reserved.
//

#import "BacktraceThread.h"
#import <mach/task.h>
#import <mach/mach_init.h>
#import <mach/mach_port.h>
#import <mach/task_info.h>
#import <mach/thread_act.h>
#import <mach/vm_map.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#import <mach-o/nlist.h>
#import <mach-o/getsect.h>
#import <string.h>


// 栈帧结构体：
typedef struct QiStackFrameEntry {
    const struct QiStackFrameEntry *const previous; //!< 上一个栈帧
    const uintptr_t return_address;                  //!< 当前栈帧的地址
} QiStackFrameEntry;

#if defined(__arm64__)
    #define BS_THREAD_STATE_COUNT ARM_THREAD_STATE64_COUNT
    #define BS_THREAD_STATE ARM_THREAD_STATE64
    #define BS_FRAME_POINTER __fp
    #define BS_STACK_POINTER __sp
    #define BS_INSTRUCTION_ADDRESS __pc
#elif defined(__arm__)
    #define BS_THREAD_STATE_COUNT ARM_THREAD_STATE_COUNT
    #define BS_THREAD_STATE ARM_THREAD_STATE
    #define BS_FRAME_POINTER __r[7]
    #define BS_STACK_POINTER __sp
    #define BS_INSTRUCTION_ADDRESS __pc
#endif

#ifdef __LP64__
typedef struct mach_header_64 mach_header_t;
typedef struct segment_command_64 segment_command_t;
typedef struct section_64 section_t;
typedef struct nlist_64 nlist_t;
#define LC_SEGMENT_ARCH_DEPENDENT LC_SEGMENT_64
#else /* __LP64__ */
typedef struct mach_header mach_header_t;
typedef struct segment_command segment_command_t;
typedef struct section section_t;
typedef struct nlist nlist_t;
#define LC_SEGMENT_ARCH_DEPENDENT LC_SEGMENT
#endif /* __LP64__ */

@implementation BacktraceThread

+ (NSString *)backtraceString {
    thread_act_t thread = mach_task_self();
    thread_array_t act_list;
    mach_msg_type_number_t act_listCnt;
    task_threads(thread, &act_list, &act_listCnt);
    for (int i = 0; i < act_listCnt; ++i) {
        // thread_suspend(act_list[i]);
        NSLog(@"%d",act_list[i]);
        _STRUCT_MCONTEXT machineContext;
        mach_msg_type_number_t state_count = BS_THREAD_STATE_COUNT;
        kern_return_t kr = thread_get_state(act_list[i], BS_THREAD_STATE, (thread_state_t)&machineContext.__ss, &state_count);
        if (kr == KERN_SUCCESS) {
            // 找出所有的函数调用地址
            QiStackFrameEntry frame = {0};
            uintptr_t backtraceBuffer[50];
            const uintptr_t framePtr = bs_mach_framePointer(&machineContext);
            bs_mach_memcpy((void *)framePtr, &frame, sizeof(frame));
            for(int i = 0; i < 50; i++) {
                backtraceBuffer[i] = frame.return_address;
                if(backtraceBuffer[i] == 0 ||
                   frame.previous == 0 ||
                   bs_mach_memcpy(frame.previous, &frame, sizeof(frame)) != KERN_SUCCESS) {
                    break;
                }
                // NSLog(@"%d",i);
                
                Dl_info info;
                if(ksdl_dladdr(backtraceBuffer[i], &info)) {
                    NSLog(@"%s %p %p %s",info.dli_fname,info.dli_fbase,info.dli_saddr,info.dli_sname);
                }
            }
        }
    }
    
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        thread = mach_task_self();
//        thread_array_t act_list;
//        mach_msg_type_number_t act_listCnt;
//        task_threads(thread, &act_list, &act_listCnt);
//        for (int i = 0; i < act_listCnt; ++i) {
//            NSLog(@"%u",act_list[i]);
//        }
//        thread_suspend(thread);
//        NSLog(@"%@",[NSThread currentThread]);
//    });
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//       // 获取线程的state
//        _STRUCT_MCONTEXT machineContext;
//        mach_msg_type_number_t state_count = BS_THREAD_STATE_COUNT;
//        kern_return_t kr = thread_get_state(thread, BS_THREAD_STATE, (thread_state_t)&machineContext.__ss, &state_count);
//        if (kr == KERN_SUCCESS) {
//            // 找出所有的函数调用地址
//            QiStackFrameEntry frame = {0};
//            uintptr_t backtraceBuffer[50];
//            const uintptr_t framePtr = bs_mach_framePointer(&machineContext);
//            bs_mach_memcpy((void *)framePtr, &frame, sizeof(frame));
//            for(int i = 0; i < 50; i++) {
//                backtraceBuffer[i] = frame.return_address;
//                if(backtraceBuffer[i] == 0 ||
//                   frame.previous == 0 ||
//                   bs_mach_memcpy(frame.previous, &frame, sizeof(frame)) != KERN_SUCCESS) {
//                    NSLog(@"%d+++",i);
//                    break;
//                }
//                NSLog(@"%d",i);
//
//                Dl_info info;
//                if(ksdl_dladdr(backtraceBuffer[i], &info)) {
//                    NSLog(@"%s",info.dli_fname);
//                }
//
//            }
//        }
//
//        thread_resume(thread);
//        NSLog(@"%@",[NSThread currentThread]);
//    });
    
    return @"";
}

//static inline bool getThreadList(KSMachineContext* context)
//{
//    const task_t thisTask = mach_task_self();
//    kern_return_t kr;
//    thread_act_array_t threads;
//    mach_msg_type_number_t actualThreadCount;
//
//    if((kr = task_threads(thisTask, &threads, &actualThreadCount)) != KERN_SUCCESS)
//    {
//        KSLOG_ERROR("task_threads: %s", mach_error_string(kr));
//        return false;
//    }
//    int threadCount = (int)actualThreadCount;
//    int maxThreadCount = sizeof(context->allThreads) / sizeof(context->allThreads[0]);
//    if(threadCount > maxThreadCount)
//    {
//        threadCount = maxThreadCount;
//    }
//    for(int i = 0; i < threadCount; i++)
//    {
//        context->allThreads[i] = threads[i];
//    }
//    context->threadCount = threadCount;
//
//    for(mach_msg_type_number_t i = 0; i < actualThreadCount; i++)
//    {
//        mach_port_deallocate(thisTask, context->allThreads[i]);
//    }
//    vm_deallocate(thisTask, (vm_address_t)threads, sizeof(thread_t) * actualThreadCount);
//
//    return true;
//}

/** Get the segment base address of the specified image.
 *
 * This is required for any symtab command offsets.
 *
 * @param idx The image index.
 * @return The image's base address, or 0 if none was found.
 */
static uintptr_t segmentBaseOfImageIndex(const uint32_t idx)
{
    const struct mach_header* header = _dyld_get_image_header(idx);
    
    // Look for a segment command and return the file image address.
    uintptr_t cmdPtr = firstCmdAfterHeader(header);
    if(cmdPtr == 0)
    {
        return 0;
    }
    for(uint32_t i = 0;i < header->ncmds; i++)
    {
        const struct load_command* loadCmd = (struct load_command*)cmdPtr;
        if(loadCmd->cmd == LC_SEGMENT)
        {
            const struct segment_command* segmentCmd = (struct segment_command*)cmdPtr;
            if(strcmp(segmentCmd->segname, SEG_LINKEDIT) == 0)
            {
                return segmentCmd->vmaddr - segmentCmd->fileoff;
            }
        }
        else if(loadCmd->cmd == LC_SEGMENT_64)
        {
            const struct segment_command_64* segmentCmd = (struct segment_command_64*)cmdPtr;
            if(strcmp(segmentCmd->segname, SEG_LINKEDIT) == 0)
            {
                return (uintptr_t)(segmentCmd->vmaddr - segmentCmd->fileoff);
            }
        }
        cmdPtr += loadCmd->cmdsize;
    }
    
    return 0;
}

/** Get the address of the first command following a header (which will be of
 * type struct load_command).
 *
 * @param header The header to get commands for.
 *
 * @return The address of the first command, or NULL if none was found (which
 *         should not happen unless the header or image is corrupt).
 */
static uintptr_t firstCmdAfterHeader(const struct mach_header* const header)
{
    switch(header->magic)
    {
        case MH_MAGIC:
        case MH_CIGAM:
            return (uintptr_t)(header + 1);
        case MH_MAGIC_64:
        case MH_CIGAM_64:
            return (uintptr_t)(((struct mach_header_64*)header) + 1);
        default:
            // Header is corrupt
            return 0;
    }
}

bool ksdl_dladdr(const uintptr_t address, Dl_info* const info)
{
    info->dli_fname = NULL;
    info->dli_fbase = NULL;
    info->dli_sname = NULL;
    info->dli_saddr = NULL;

    const uint32_t idx = imageIndexContainingAddress(address);
    if(idx == UINT_MAX)
    {
        return false;
    }
    const struct mach_header* header = _dyld_get_image_header(idx);
    const uintptr_t imageVMAddrSlide = (uintptr_t)_dyld_get_image_vmaddr_slide(idx);
    const uintptr_t addressWithSlide = address - imageVMAddrSlide;
    const uintptr_t segmentBase = segmentBaseOfImageIndex(idx) + imageVMAddrSlide;
    if(segmentBase == 0)
    {
        return false;
    }

    info->dli_fname = _dyld_get_image_name(idx);
    info->dli_fbase = (void*)header;

    // Find symbol tables and get whichever symbol is closest to the address.
    const nlist_t* bestMatch = NULL;
    uintptr_t bestDistance = ULONG_MAX;
    uintptr_t cmdPtr = firstCmdAfterHeader(header);
    if(cmdPtr == 0)
    {
        return false;
    }
    for(uint32_t iCmd = 0; iCmd < header->ncmds; iCmd++)
    {
        const struct load_command* loadCmd = (struct load_command*)cmdPtr;
        if(loadCmd->cmd == LC_SYMTAB)
        {
            const struct symtab_command* symtabCmd = (struct symtab_command*)cmdPtr;
            const nlist_t* symbolTable = (nlist_t*)(segmentBase + symtabCmd->symoff);
            const uintptr_t stringTable = segmentBase + symtabCmd->stroff;

            for(uint32_t iSym = 0; iSym < symtabCmd->nsyms; iSym++)
            {
                // If n_value is 0, the symbol refers to an external object.
                if(symbolTable[iSym].n_value != 0)
                {
                    uintptr_t symbolBase = symbolTable[iSym].n_value;
                    uintptr_t currentDistance = addressWithSlide - symbolBase;
                    if((addressWithSlide >= symbolBase) &&
                       (currentDistance <= bestDistance))
                    {
                        bestMatch = symbolTable + iSym;
                        bestDistance = currentDistance;
                    }
                }
            }
            if(bestMatch != NULL)
            {
                info->dli_saddr = (void*)(bestMatch->n_value + imageVMAddrSlide);
                if(bestMatch->n_desc == 16)
                {
                    // This image has been stripped. The name is meaningless, and
                    // almost certainly resolves to "_mh_execute_header"
                    info->dli_sname = NULL;
                }
                else
                {
                    info->dli_sname = (char*)((intptr_t)stringTable + (intptr_t)bestMatch->n_un.n_strx);
                    if(*info->dli_sname == '_')
                    {
                        info->dli_sname++;
                    }
                }
                break;
            }
        }
        cmdPtr += loadCmd->cmdsize;
    }
    
    return true;
}

// 找出address所对应的image编号
uint32_t imageIndexContainingAddress(const uintptr_t address) {
    const uint32_t imageCount = _dyld_image_count(); // dyld中image的个数
    const struct mach_header *header = 0;
    
    for (uint32_t i = 0; i < imageCount; i++) {
        header = _dyld_get_image_header(i);
        if (header != NULL) {
            // 在提供的address范围内，寻找segment command
            uintptr_t addressWSlide = address - (uintptr_t)_dyld_get_image_vmaddr_slide(i); //!< ASLR
            uintptr_t cmdPointer = 0; // qi_firstCmdAfterHeader(header);
            if (header->magic == MH_MAGIC) {
                cmdPointer = ((uint64_t)((struct mach_header*)header) + sizeof(struct mach_header));
            } else {
                cmdPointer = ((uint64_t)header + sizeof(struct mach_header_64));
            }
            if (cmdPointer == 0) {
                continue;
            }
            for (uint32_t iCmd = 0; iCmd < header->ncmds; iCmd++) {
                const struct load_command *loadCmd = (struct load_command*)cmdPointer;
                if (loadCmd->cmd == LC_SEGMENT) {
                    const struct segment_command *segCmd = (struct segment_command*)cmdPointer;
                    if (addressWSlide >= segCmd->vmaddr && addressWSlide < segCmd->vmaddr + segCmd->vmsize) {
                        // 命中!
                        return i;
                    }
                }
                else if (loadCmd->cmd == LC_SEGMENT_64) {
                    const struct segment_command_64 *segCmd = (struct segment_command_64*)cmdPointer;
                    if (addressWSlide >= segCmd->vmaddr && addressWSlide < segCmd->vmaddr + segCmd->vmsize) {
                        // 命中!
                        return i;
                    }
                }
                cmdPointer += loadCmd->cmdsize;
            }
        }
    }
    
    return UINT_MAX; // 没找到就返回UINT_MAX
}

kern_return_t bs_mach_memcpy(const void *const src, void *const dst, const size_t numBytes){
    vm_size_t bytesCopied = 0;
    return vm_read_overwrite(mach_task_self(), (vm_address_t)src, (vm_size_t)numBytes, (vm_address_t)dst, &bytesCopied);
}

uintptr_t bs_mach_framePointer(mcontext_t const machineContext){
    return machineContext->__ss.__fp;
}

/*!
 @brief 将machineContext从thread中提取出来
 @param thread 当前线程
 @param machineContext 所要赋值的machineContext
 @return 是否获取成功
 */
+ (BOOL)qi_fillThreadStateFrom:(thread_t) thread intoMachineContext:(_STRUCT_MCONTEXT *)machineContext {
    mach_msg_type_number_t state_count = BS_THREAD_STATE_COUNT;
    kern_return_t kr = thread_get_state(thread, BS_THREAD_STATE, (thread_state_t)&machineContext->__ss, &state_count);
    return kr == KERN_SUCCESS;
}

@end
