### verilog 编译运行

```
iverilog -o example example_tb.v
./example
```

### verilog 数据类型

- **wire 线网**

  tips from tutor：

  1. `wire` 可简单地理解为电线，连接的过程中可以夹杂逻辑门（对数据进行运算）。
  2. 因此 `wire` **只能用 `assign` 赋值**，并且**只能被赋值一次**（因为电线不可能随意变动）。
  3. 因此对 `wire` 的声明与赋值无关乎被写在 `module` 中的什么位置（因为是连接好的电线）。

- **reg 寄存器**

  tips from tutor：

  1. `reg` 具有储存数据的功能，不同于 `wire`。
  2. 在 `@always(*)` 中**只使用阻塞赋值 `=` 给 reg 赋值**，这等价于 wire 用 assign 赋值。
  3. 在 `@always(posedge clk)` 中只使用非阻塞赋值 `<=` 给 reg 赋值，所有赋值操作是并行的，等价于只会使用上一周期的数据进行赋值。

- **向量 位宽大于1**

  ```verilog
  reg [3:0]      counter ;    //声明4bit位宽的寄存器counter
  wire [32-1:0]  gpio_data;   //声明32bit位宽的线型变量gpio_data
  wire [8:2]     addr ;       //声明7bit位宽的线型变量addr，位宽范围为8:2
  reg [0:31]     data ;       //声明32bit位宽的寄存器变量data, 最高有效位为0
  ```

- **real 实数**

- **time 时间**

  可以通过调用系统函数 `$time` 获取当前仿真时间

- **数组**

  ```verilog
  integer          flag [7:0] ; //8个整数组成的数组
  reg  [3:0]       counter [3:0] ; //由4个4bit计数器组成的数组
  wire [7:0]       addr_bus [3:0] ; //由4个8bit wire型变量组成的数组
  wire             data_bit[7:0][5:0] ; //声明1bit wire型变量的二维数组
  reg [31:0]       data_4d[11:0][3:0][3:0][255:0] ; //声明4维的32bit数据变量数组
  ```

- **parameter 参数** 

  表示常量，只能赋值一次

- **字符串**

  保存在reg类型变量中，每个字符占一个字节

### Verilog 表达式

- **拼接操作符**

  ```verilog
  A = 4'b1010 ;
  B = 1'b1 ;
  Y1 = {B, A[3:2], A[0], 4'h3 };  //结果为Y1='b1100_0011
  Y2 = {4{B}, 3'd4};  //结果为 Y2=7'b111_1100
  Y3 = {32{1'b0}};  //结果为 Y3=32h0，常用作寄存器初始化时匹配位宽的赋初值
  ```

### Verilog 时延

连续赋值延时语句中的延时，用于控制任意操作数发生变化到语句左端赋予新值之间的时间延时。

```verilog
//普通时延，A&B计算结果延时10个时间单位赋值给Z
wire Z, A, B ;
assign #10    Z = A & B ;
//隐式时延，声明一个wire型变量时对其进行包含一定时延的连续赋值。
wire A, B;
wire #10        Z = A & B;
//声明时延，声明一个wire型变量是指定一个时延。因此对该变量所有的连续赋值都会被推迟到指定的时间。除非门级建模中，一般不推荐使用此类方法建模。
wire A, B;
wire #10 Z ;
assign           Z =A & B
```

**惯性时延**

```verilog
   initial begin
        ai        = 0 ;
        #25 ;      ai        = 1 ;
        #35 ;      ai        = 0 ;        //60ns
        #40 ;      ai        = 1 ;        //100ns
        #10 ;      ai        = 0 ;        //110ns
    end
```

### Verilog 过程结构

tips：不应该使用 `initial`（下发的测试代码中已有的除外），这是无法综合的语句。

- **initial语句**

  initial 语句从 0 时刻开始执行，只执行一次，多个 initial 块之间是相互独立的。

  如果 initial 块内包含多个语句，需要使用关键字 begin 和 end 组成一个块语句。

  如果 initial 块内只要一条语句，关键字 begin 和 end 可使用也可不使用。

  initial 理论上来讲是不可综合的，多用于初始化、信号检测等。

  可以看出，2 个 initial 进程语句分别给信号 ai，bi 赋值时，相互间并没有影响。

  ```verilog
   initial begin
          ai         = 0 ;
          #25 ;      ai        = 1 ;
          #35 ;      ai        = 0 ;        //absolute 60ns
          #40 ;      ai        = 1 ;        //absolute 100ns
          #10 ;      ai        = 0 ;        //absolute 110ns
      end
   
      initial begin
          bi         = 1 ;
          #70 ;      bi        = 0 ;        //absolute 70ns
          #20 ;      bi        = 1 ;        //absolute 90ns
      end
  ```

- **always 语句**

  与 initial 语句相反，always 语句是重复执行的。always 语句块从 0 时刻开始执行其中的行为语句；当执行完最后一条语句后，便再次执行语句块中的第一条语句，如此循环反复。

  由于循环执行的特点，always 语句多用于仿真时钟的产生，信号行为的检测等。

  ```verilog
   always begin
          #10;
          if ($time >= 1000) begin
              $finish ;
          end
      end
  ```

### Verilog 连续赋值

`assign` 为关键词，任何已经声明 wire 变量的连续赋值语句都是以 assign 开头，例如：

```verilog
wire      Cout, A, B ;
assign    Cout  = A & B ;     //实现计算A与B的功能
```

LHS_target 必须是一个标量或者线型向量，而不能是寄存器类型。

只要 RHS_expression 表达式的操作数有事件发生（值的变化）时，RHS_expression 就会立刻重新计算，同时赋值给 LHS_target。

Verilog 还提供了另一种对 wire 型赋值的简单方法，即在 wire 型变量声明的时候同时对其赋值。

### Verilog 过程赋值

过程性赋值是在 initial 或 always 语句块里的赋值，赋值对象是寄存器、整数、实数等类型。

这些变量在被赋值后，其值将保持不变，直到重新被赋予新值。

- **阻塞赋值**

  阻塞赋值属于**顺序执行**，即下一条语句执行前，当前语句一定会执行完毕。

  阻塞赋值语句使用等号 **=** 作为赋值符。

- **非阻塞赋值**

  非阻塞赋值属于**并行执行语句**，即下一条语句的执行和当前语句的执行是同时进行的，它不会阻塞位于同一个语句块中后面语句的执行。

  非阻塞赋值语句使用小于等于号 **<=** 作为赋值符。

实际 Verilog 代码设计时，切记**不要在一个过程结构中混合使用阻塞赋值与非阻塞赋值**。两种赋值方式混用时，时序不容易控制，很容易得到意外的结果。

always 时序逻辑块中多用非阻塞赋值，always 组合逻辑块中多用阻塞赋值

在仿真电路时，initial 块中一般多用阻塞赋值。

```verilog
//2 个 always 块中语句并行执行 交换ab寄存器的值
always @(posedge clk) begin
    a <= b ;
end
 
always @(posedge clk) begin
    b <= a;
end
```

### Verilog 时序控制

- **时延控制**

  - 常规时延

    遇到常规延时时，该语句需要等待一定时间，然后将计算结果赋值给目标信号。

    ```verilog
    reg  value_test ;
    reg  value_general ;
    #10  value_general    = value_test ;
    //或者
    #10 ;
    value_ single         = value_test ;
    ```

  - 内嵌时延

    遇到内嵌延时时，该语句**先将计算结果保存**，然后等待一定的时间后赋值给目标信号。

    内嵌时延控制加在赋值号之后。例如：

    ```verilog
    reg  value_test ;
    reg  value_embed ;
    value_embed        = #10 value_test ;
    ```

  - 注意！

    当延时语句的赋值符号右端是常量时，2 种时延控制都能达到相同的延时赋值效果。

    当延时语句的赋值符号右端是变量时，2 种时延控制可能会产生不同的延时赋值效果。

- **边沿触发事件控制**

  在 Verilog 中，**事件**是指某一个 reg 或 wire 型变量发生了值的变化。

  基于事件触发的时序控制又主要分为以下几种。

  - **一般事件控制**

    事件控制用符号 **@** 表示。

    语句执行的条件是信号的值发生特定的变化。

    关键字 posedge 指信号发生边沿正向跳变，negedge 指信号发生负向边沿跳变，未指明跳变方向时，则 2 种情况的边沿变化都会触发相关事件。例如：

    ```verilog
    //信号clk只要发生变化，就执行q<=d，双边沿D触发器模型
    always @(clk) q <= d ;                
    //在信号clk上升沿时刻，执行q<=d，正边沿D触发器模型
    always @(posedge clk) q <= d ;  
    //在信号clk下降沿时刻，执行q<=d，负边沿D触发器模型
    always @(negedge clk) q <= d ;
    //立刻计算d的值，并在clk上升沿时刻赋值给q，不推荐这种写法
    q = @(posedge clk) d ;      
    ```

  - **命名事件控制**

    用户可以声明 event（事件）类型的变量，并触发该变量来识别该事件是否发生。命名事件用关键字 `event` 来声明，触发信号用 `->` 表示。

    ```verilog
    event     start_receiving ;
    always @( posedge clk_samp) begin
            -> start_receiving ;       //采样时钟上升沿作为时间触发时刻
    end
     
    always @(start_receiving) begin
        data_buf = {data_if[0], data_if[1]} ; //触发时刻，对多维数据整合
    end
    ```

  - **敏感列表**

    当多个信号或事件中任意一个发生变化都能够触发语句的执行时，Verilog 中使用"或"表达式来描述这种情况，用关键字 **or** 连接多个事件或信号。这些事件或信号组成的列表称为"敏感列表"。当然，or 也可以用逗号 **,** 来代替。

    当组合逻辑输入变量很多时，那么编写敏感列表会很繁琐。此时，更为简洁的写法是 **@\*** 或 **@(\*)**，表示**对语句块中的所有输入变量的变化都是敏感的**。例如：

    ```verilog
    always @(*) begin
    //always @(a, b, c, d, e, f, g, h, i, j, k, l, m) begin
    //两种写法等价
        assign s = a? b+c : d ? e+f : g ? h+i : j ? k+l : m ;
    end
    ```

  - **电平敏感事件控制**

    使用电平作为敏感信号来控制时序，即后面语句的执行需要等待某个条件为真。

    Verilog 中使用关键字 `wait` 来表示这种电平敏感情况。

    ```verilog
    initial begin
        wait (start_enable) ;      //等待 start 信号
        forever begin
            //start信号使能后，在clk_samp上升沿，对数据进行整合
            @(posedge clk_samp)  ;
            data_buf = {data_if[0], data_if[1]} ;      
        end
    end
    ```

### Verilog 语句块

- **顺序块**

  顺序块用关键字 begin 和 end 来表示。

  顺序块中的语句是一条条执行的。当然，非阻塞赋值除外。

  顺序块中每条语句的时延总是与其前面语句执行的时间相关。

  在本节之前的仿真中，initial 块中的阻塞赋值，都是顺序块的实例。

- **并行块**

  并行块有关键字 `fork` 和 `join` 来表示。

  并行块中的语句是并行执行的，即便是阻塞形式的赋值。

  并行块中每条语句的时延都是与块语句开始执行的时间相关。

- **嵌套块**

  顺序块和并行块还可以嵌套使用。

- **命名块**

  命名的块中可以声明局部变量，通过层次名引用的方法对变量进行访问。

  ```verilog
   initial begin: runoob   //命名模块名字为runoob，分号不能少
          integer    i ;       //此变量可以通过test.runoob.i 被其他模块使用
          i = 0 ;
          forever begin
              #10 i = i + 10 ;      
          end
      end
   
      reg stop_flag ;
      initial stop_flag = 1'b0 ;
      always begin : detect_stop
          if ( test.runoob.i == 100) begin //i累加10次，即100ns时停止仿真
              $display("Now you can stop the simulation!!!");
              stop_flag = 1'b1 ;
          end
          #10 ;
      end
  ```

  命名的块也可以被禁用，用关键字 disable 来表示。

  disable 可以终止命名块的执行，可以用来从循环中退出、处理错误等。

  与 C 语言中 break 类似，但是 break 只能退出当前所在循环，而 **disable 可以禁用设计中任何一个命名的块。**

  ```verilog
   initial begin: runoob_d //命名模块名字为runoob_d
          integer    i_d ;
          i_d = 0 ;
          while(i_d<=100) begin: runoob_d2
              # 10 ;
              if (i_d >= 50) begin       //累加5次停止累加
                  disable runoob_d3.clk_gen ;//stop 外部block: clk_gen
                  disable runoob_d2 ;       //stop 当前block: runoob_d2
              end
              i_d = i_d + 10 ;
          end
      end
   
      reg clk ;
      initial begin: runoob_d3
          while (1) begin: clk_gen  //时钟产生模块
              clk=1 ;      #10 ;
              clk=0 ;      #10 ;
          end
      end
  ```

### Verilog 条件语句

事例中 if 条件每次执行的语句只有一条，没有使用 begin 与 end 关键字。但如果是 if-if-else 的形式，即便执行语句只有一条，不使用 begin 与 end 关键字也会引起歧义。

所以条件语句中加入 `begin` 与 `and` 关键字就是一个很好的习惯。

```verilog
if(en) begin
    if(sel == 2'b1) begin
        sout = p1s ;
    end
    else begin
        sout = p0 ;
    end
end
```

### Verilog 多路分支语句

```verilog
case(case_expr)
    condition1     :             true_statement1 ;
    condition2     :             true_statement2 ;
    ……
    default        :             default_statement ;
endcase
```

条件选项可以有多个，不仅限于 condition1、condition2 等，而且这些条件选项不要求互斥。虽然这些条件选项是并发比较的，但执行效果是谁在前且条件为真谁被执行。

case 语句中的条件选项表单式不必都是常量，也可以是 x 值或 z 值。

当多个条件选项下需要执行相同的语句时，**多个条件选项可以用逗号分开，放在同一个语句块的候选项中**。

但是 case 语句中的 x 或 z 的比较逻辑是不可综合的，所以一般不建议在 case 语句中使用 x 或 z 作为比较值。

例如，对 4 路选择器的 case 语句进行扩展，举例如下：

```verilog
case(sel)
    2'b00:   sout_t = p0 ;
    2'b01:   sout_t = p1 ;
    2'b10:   sout_t = p2 ;
    2'b11:     sout_t = p3 ;
    2'bx0, 2'bx1, 2'bxz, 2'bxx, 2'b0x, 2'b1x, 2'bzx :
        sout_t = 2'bxx ;
    2'bz0, 2'bz1, 2'bzz, 2'b0z, 2'b1z :
        sout_t = 2'bzz ;
    default:  $display("Unexpected input control!!!");
endcase
```

- casex/casez 语句

  casex、 casez 语句是 case 语句的变形，用来表示条件选项中的无关项。

  **casex 用 "x" 来表示无关值，casez 用问号 "?" 来表示无关值。**

  两者的实现的功能是完全一致的，语法与 case 语句也完全一致。

  但是 casex、casez 一般是不可综合的，多用于仿真。

  ```verilog
   always @(*)
          casez(sel)
              4'b???1:     sout_t = p0 ;
              4'b??1?:     sout_t = p1 ;
              4'b?1??:     sout_t = p2 ;
              4'b1???:     sout_t = p3 ;  
          default:         sout_t = 2'b0 ;
      endcase
  ```

### Verilog 循环语句

- `while`

  ```verilog
  while (condition) begin
      …
  end
  ```

- `for`

  ```verilog
  for(initial_assignment; condition ; step_assignment)  begin
      …
  end
  ```

  需要注意的是，i = i + 1 不能像 C 语言那样写成 i++ 的形式，i = i -1 也不能写成 i -- 的形式。

- `repeat`

  执行固定次数的循环。repeat 循环的次数必须是一个常量、变量或信号。

  ```verilog
  repeat (loop_times) begin
      …
  end
  ```

- `forever`

  ```verilog
  forever begin
      …
  end
  ```

  forever 语句表示永久循环，不包含任何条件表达式，一旦执行便无限的执行下去，系统函数 $finish 可退出 forever。

  forever 相当于 while(1) 。

### Verilog 过程连续赋值

过程连续赋值是过程赋值的一种。这种赋值语句能够**替换其他所有 wire 或 reg 的赋值**，改写了 wire 或 reg 型变量的当前值。

与过程赋值不同的是，过程连续赋值的表达式能被连续的驱动到 wire 或 reg 型变量中，即过程连续赋值发生作用时，**右端表达式中任意操作数的变化都会引起过程连续赋值语句的重新执行**。

过程连续性赋值主要有 2 种，assign-deassign 和 force-release。

- **assign, deassign**

  赋值对象只能是**寄存器或寄存器组**，而不能是 wire 型变量。

  赋值过程中对寄存器连续赋值，寄存器中的值被保留直到被重新赋值。

- **force, release**

  force （强制赋值操作）与 release（取消强制赋值）表示第二类过程连续赋值语句。

  使用方法和效果，和 assign 与 deassign 类似，但赋值对象可以是 reg 型变量，也可以是 wire 型变量。

  因为是无条件强制赋值，一般多用于交互式调试过程，不要在设计模块中使用。

### Verilog 模块与端口

- 模块

  模块格式定义如下：

  ```verilog
  module module_name 
  #(parameter_list)
  (port_list) ;
                Declarations_and_Statements ;
  endmodule
  ```

  ### 5.1 Verilog 模块与端口

- 模块

  模块是 Verilog 中基本单元的定义形式，是与外界交互的接口。

  模块格式定义如下：

  ```verilog
  module module_name 
  #(parameter_list)
  (port_list) ;
                Declarations_and_Statements ;
  endmodule
  ```

  模块定义必须以关键字 module 开始，以关键字 endmodule 结束。

  模块名，端口信号，端口声明和可选的参数声明等，出现在设计使用的 Verilog 语句（图中 Declarations_and_Statements）之前。

  模块内部有可选的 5 部分组成，分别是变量声明，数据流语句，行为级语句，低层模块例化及任务和函数

- 端口

  端口是模块与外界交互的接口。对于外部环境来说，模块内部是不可见的，对模块的调用只能通过端口连接进行。

- 端口列表

  模块的定义中包含一个可选的端口列表，一般将不带类型、不带位宽的信号变量罗列在模块声明里。下面是一个 PAD 模型的端口列表：

  ```verilog
  module pad(
      DIN, OEN, PULL,
      DOUT, PAD);
  ```

  一个模块如果和外部环境没有交互，则可以不用声明端口列表。

- 端口声明

  (1) 端口信号在端口列表中罗列出来以后，就可以在模块实体中进行声明了。

  根据端口的方向，端口类型有 3 种： 输入（input），输出（output）和双向端口（inout）。

  input、inout 类型不能声明为 reg 数据类型，因为 reg 类型是用于保存数值的，而输入端口只能反映与其相连的外部信号的变化，不能保存这些信号的值。

  output 可以声明为 wire 或 reg 数据类型。

  上述例子中 pad 模块的端口声明，在 module 实体中就可以表示如下：

  ```verilog
  //端口类型声明
  input        DIN, OEN ;
  input [1:0]  PULL ;  //(00,01-dispull, 11-pullup, 10-pulldown)
  inout        PAD ;   //pad value
  output       DOUT ;  //pad load when pad configured as input
  
  //端口数据类型声明
  wire         DIN, OEN ;
  wire  [1:0]  PULL ;
  wire         PAD ;
  reg          DOUT ;
  ```

  (2) 在 Verilog 中，**端口隐式的声明为 wire 型变量**，即当端口具有 wire 属性时，不用再次声明端口类型为 wire 型。但是，当端口有 reg 属性时，则 reg 声明不可省略。

  上述例子中的端口声明，则可以简化为：

  ```verilog
  //端口类型声明
  input        DIN, OEN ;
  input [1:0]  PULL ;    
  inout        PAD ;    
  output       DOUT ;    
  reg          DOUT ;
  ```

  (3) 当然，信号 DOUT 的声明完全可以合并成一句：

  ```verilog
  output reg      DOUT ;
  ```

- 端口仿真

### Verilog 函数

函数只能在模块中定义，位置任意，并在模块的任何地方引用，作用范围也局限于此模块。

- 1）不含有任何延迟、时序或时序控制逻辑
- 2）至少有一个输入变量
- 3）只有一个返回值，且没有输出
- 4）不含有非阻塞赋值语句
- 5）函数可以调用其他函数，但是不能调用任务

Verilog 函数声明格式如下：

```verilog
function [range-1:0]     function_id ;
input_declaration ;
 other_declaration ;
procedural_statement ;
endfunction
```

函数在声明时，会隐式的声明一个宽度为 range、 名字为 function_id 的寄存器变量，函数的返回值通过这个变量进行传递。当该寄存器变量没有指定位宽时，默认位宽为 1。

函数通过指明函数名与输入变量进行调用。函数结束时，返回值被传递到调用处。

函数调用格式如下：

```verilog
function_id(input1, input2, …);
```

### Verilog 任务

```verilog
task       task_id ;
    port_declaration ;
    procedural_statement ;
endtask
```

