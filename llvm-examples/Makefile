CLANG=clang
LLFILES=function_declaration.ll  getelementptr.ll  global.ll  printf.ll \
        vector.ll vector.opt.ll ternary.ll ternary.opt.ll 

all : $(LLFILES)
clean :
	rm -f $(LLFILES)
.PHONY: all clean
.SUFFIXES:
.SUFFIXES: .c .ll .opt.ll
.c.ll :
	$(CLANG) -O0 -emit-llvm -S $< -o $@
.c.opt.ll :
	$(CLANG) -O3 -emit-llvm -S $< -o $@

