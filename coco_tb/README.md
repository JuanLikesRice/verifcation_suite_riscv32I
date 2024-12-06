# <div align="center"> CocoTB Auto Verification Suite </div>  
  
<div align="center"> <b> Rice Switch Core </div>  
  
## Contents  
- CocoTB resources  
- Environment setup
- CocoTB sample usage  
- Single file verification  
- Multiple file verification  
  
## CocoTB resources  
https://docs.cocotb.org/en/stable/quickstart.html  
  
## Environment setup  
### MacOS

### Windows
 
## CocoTB sample usage  
- pass  
- pass  
  
  
## Single file verification  
### Work flow diagram  
<div align="center">  
<img src="https://s2.loli.net/2024/12/07/DpC1eFksMKhn43f.png" alt="workflow" width="50%" />
</div>  
<div align="center">  
work flow for single verilog file  
</div>  
When we want to use cocotb to verification single verilog file, you just need to follow the instruction below, take decoder_swc.v as an example:  
  
1. Put your dut file under "./DUT" folder, like "./DUT/decoder_swc.v"  
2. Write your testbench and put it under "./Testbench", like "./Testbench/test_dec.py"  
3. Run the command as below:  
```
python verify.py dec_swc.v
```
By doing this an automatically wrapper file will be generated under "./DUT_Wrapper" folder, in this example the wrapper file name would be "dec_swc_wrapper.v", feel free to add extra logic or command to this wrapper file for detailed test.

Also you shall see the result in your command line.

## Multiple files verification  
### Work flow diagram  
<div align="center">  
<img src="https://s2.loli.net/2024/12/07/BA7PbuDf2ckdRWn.png" alt="workflow" width="80%" />
</div>  
<div align="center">  
work flow for single verilog file  
</div>  
When we want to use cocotb to verify multiple files things become much more complex. It takes more steps:

 1. Put all of DUTs under "./DUT" folder
 2. Write your testbench and put it under "./Testbench", the filename should be "test_top.py".
 3. Run the command as below:
 ```
python verify.py DUT1.v DUT2.v ... DUTn.v 
```
Normally first time running this won't success because the v_connector can't wire all the signals correctly and competely, please mannually modify the top wrapper file.

Same as single file verification, you can check the simulation result on your command line.