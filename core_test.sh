FLAG="-cc -top core_tb --timing --trace-fst --build --exe -j 0"

verilator $FLAG ./core_tb.cpp \
                ./core_package.sv \
                ./ALU.sv \
                ./WB.sv \
                ./control.sv \
                ./csr.sv \
                ./csrRegFile.sv \
                ./decode.sv \
                ./execute.sv \
                ./fetch.sv \
                ./memory.sv \
                ./ram.sv \
                ./registerFile.sv \
                ./core.sv \
                ./core_tb.sv

./obj_dir/Vcore_tb