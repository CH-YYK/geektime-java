# Homework2 JVM

## 题目 01- 请你用自己的语言向我介绍 Java 运行时数据区（内存区域）

### 堆、虚拟机栈、本地方法栈、方法区（永久代、元空间）、运行时常量池（字符串常量池）、直接内存

堆（heap）
堆是Java运行时用来存储object的内存空间，由各个线程共享，并让JVM通过GC管理该内存的申请及释放。堆的内存结构在不同版本的java中不完全一样，
但内存模型的总体概念是为了Java GC的内存管理而服务的。主要分为Eden, survivor1, survivor2, tenured。

虚拟机栈 （Java Virtual Machine Stack）
线程私有的，用来记录该线程中对Java方法的调用。栈的生命周期与线程的生命周期一致。每当一个方法被调用，就会
创建一个栈帧（stack frame）。栈帧中储存了“局部变量表”，“操作数栈”，“动态链接”和“方法返回地址”等。每个方法的调用
和执行，都对应着一个栈帧在虚拟机栈里从入栈到出栈的过程。

本地方法栈 （native method stack）
首先“本地方法”（native method）指的是由java调用的非Java的代码的接口。
> A native method is a Java method whose implementation is provided by non-java code
Java在某些时候依赖这类方法去与非Java环境进行交互，例如使用C函数与操作系统或硬件进行交互。

本地方法栈同样是线程私有的，用来记录该线程中，本地方法的调用信息的。由于该结构并不在JVM的规范之中，其生命周期由JVM产品开发者自行决定。
在Hotspot JVM中，本地方法栈和虚拟机栈是一起的。

方法区（method area）
用来存储jvm加载的class信息，常量，静态变量等。简言之就是Java类信息的Metadata。方法区的大小决定了Java可以导入的类的个数。在Jdk1.8以前，方法区是存在
perm generation中的，属于堆的一部分。所以在大项目的时候，当load的class足够多时，会面临跟堆抢空间的境地，容易触发OOM。在新版本中，Perm gen被
移出了Heap并存放在了Native Memory （Meta Space）中，不会那么容易得影响到堆。

运行时常量池（字符串常量池）
常量信息：比如class，field 等。

字符串常量池是Java优化内存管理的一种方式。在编译期时候，java会将所有的String literal给统一存进一个hashtable来保证指向同一个内存块，从而避免了
同样的数据被重复分配了内存。这也是Java中的string literal immutable的原因之一。

直接内存（off-heap memory）
这里的直接内存指的是堆外内存。整个JVM是运行在本地内存（native memory）上的，heap部分被JVM用来储存对象实例，off-heap部分被JVM用来做IO方面的优化，还有一部分Native Memory作为Meta space储存class的meta data。在之前Java的IO操作需要先将数据从disk读入堆中，在新版NIO下，Java可以直接操作堆外内存进行IO而避免了堆外和堆内的来回两次数据复制，从而达到更高的读写效率。存在的弊端是，由于off-heap不由JVM的GC负责管理，所以存在内存泄漏的风险，而且堆外内存的分配相对于堆内要花费较多的时间。

### 为什么堆内存要分年轻代和老年代？
年轻代 （Young）和老年代（old）
Java的GC遵循“分代收集理论”，该理论假设
1. 大部分对象是“临时”对象，在Young中被minorGC早早清理。
2. 若某些对象在多轮GC后仍被使用，那可以认为该对象非“临时”对象，过渡到Old中，由MajorGC统一处理。
主要目的还是为了高效利用内存，降低GC产生的STW的影响。比如在Young（Eden + Survivors）时侯，用高频且较短STW的
MinorGC去快速地清理掉一些内存占用不大的临时对象。用低频但等待时间更久的MajorGC去处理那些MinorGC短时间无法清理的非临时对象，
或内存占用非常大的对象。

## 题目 02- 描述一个 Java 对象的生命周期

### 解释一个对象的创建过程

1. 先检查常量池中是否有该类的信息。若无就先load class。
2. 分配内存空间并初始化为零
3. 写入必要信息：header信息（markwork：8bytes + pointer：4bytes）= 12bytes
4. 执行init方法。

### 对象的内存分配
根据不同GC使用不同的方式。例如Parnew和Serial会使用指针碰撞（有内存compaction） 而CMS会使用空闲内存列表（有内存碎片）。
   区别主要是因为，不同GC方式所产生的空内存块的分布不同。考虑到多线程问题，主要采用
   - CAS（compare and swap）+ retry。
   - TLAB（Thread local allocation buffer），为每一个线程预留内存空间。若预留空间不足，则采用上一个方法

每一个新对象会创建与Eden中，在每一次minorGC时候，该对象会被复制进一个survivor区（Eden和另一个survivor区会被统一清除）。
超过15次没有被minorGC的会被过渡到老年代。

若该对象占用空间超过Eden空余容量，（不考虑内存担保）而且在minorGC后Eden+survivor中仍放不下，则直接从老年代申请内存。

### 对象的销毁过程
对象由Java GC去自动执行销毁。GC会由GCRoots去搜索到需要被销毁的对象，通过执行该对象的finalize()。
每一个需要被清理的finalize对象需要被执行两次才会被最终回收。一共需要进行两次标记，只有两次标记后仍然未与GCRoots链接的
对象会被最终回收。

### 对象的两种访问方式
pointer vs handle (指针 vs 句柄)
pointer直接指向对象所在的Memory的地址来直接访问对象。handle则存储了指针信息从而间接访问对象。
单从访问角度，pointer的效率要高于handle。但是考虑到对象的Memory地址随着GC的执行会经常性变化，handle能
更稳定的访问对象。

### 内存担保

若新生代（Eden + Survivors）中的内存不足以容纳新对象而老年代中的内存充足，在特定条件（由不同GC决定）下，将新生代中现有的对象都复制到老生代，
从而为新对象腾出eden区。担保机制是Java在特定GC条件下，在内存分配方面制定的优化策略。

我认为担保机制的设立是JVM在分代收集理论下，在MinorGC中可能发生的无效复制，和MajorGC的多次触发两者中做的权衡。
1. 对于新的对象，依照假设，它大概率会很快被GC收集掉，而且在占用空间不大的情况下直接放入Old很不明智。
   相对来说Young中现存的对象们更不容易被GC。留在Eden中可能会导致接下来minorGC中很多无效的复制。
2. 但是直接无脑把Eden中的现有对象直接放入Old，容易导致高时间成本的MajorGC多次触发，对应用的性能是极大的影响。

## 题目 03- 垃圾收集算法有哪些？垃圾收集器有哪些？他们的特点是什么？

算法：
1. Mark-sweep（标记-清除算法）
   JVM最基本的GC算法，分为标记和清除两个步骤。标记步骤会找到所有需要被清除的对象，在清除步骤对他们统一进行回收。
   缺点：两个步骤都需要全局遍历，所以效率不高，而且会产生内存碎片（memory fragments），不利于大对象的再分配。

2. Copying（复制算法）
   在目前的内存模型下只能用于年轻代。
   基于Mark-sweep的效率优化版。内存预先被分为两部分，例如Eden + 其中一个survivor。执行minorGC时候，会先将Eden和其中一个survivor的object
   复制到另一个survivor中，然后对Eden和survivor统一执行内存清理。在时间上相对Mark-sweep要高效，但是在空间上会有一个survivor区作为保留区域
   不会被使用。

3. Mark-compact（标记-整理算法）
   用于解决标记-清除算法所导致的内存碎片问题，主要用于老年代对象。在清除内存方面步骤和Mark-sweep一致，但是在清除后会花额外的开销来清理掉内存碎片。

目前的商业JVM模式下，普遍采用“分代回收”（generational collection），即根据存活周期去对内存分区，
    - 对新生代采用复制算法
    - 对老年代采用标记-清除/整理算法。

收集器：
垃圾收集器，在执行模式上可以分为串行和并行。其中由于避免了线程上下文切换所造成的开销，串行在单核上效率优于并行。并行收集器的通过单位时间快速
执行来实现用户的STW影响最小，来实现throughput优先。

收集器在不同的generation会应用不同的算法，比如年轻代使用copying，老年代使用Mark-sweep或Mark-compact。
