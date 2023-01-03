#include "verilated_fst_c.h"
#include "verilated.h"
#include "Vcore_tb.h"
#include <memory>

double sc_time_stamp() { return 0; }

int main(int argc, char const *argv[])
{
    const std::unique_ptr<VerilatedContext> contextp{new VerilatedContext};
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);

    const std::unique_ptr<Vcore_tb> core_tb{new Vcore_tb{contextp.get(), "core_tb"}};

    core_tb->clk = 1;
    while (!contextp->gotFinish())
    {
        contextp->timeInc(1);
        core_tb->clk = !core_tb->clk;
        core_tb->eval();
    }
    core_tb->final();
    return 0;
}
