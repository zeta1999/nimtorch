import fragments/ffi/cpp as cpp
export cpp
import os

defineCppType(AType, "at::Type", "ATen/ATen.h")
defineCppType(ATensor, "at::Tensor", "ATen/ATen.h")
defineCppType(AStorage, "at::Storage", "ATen/ATen.h")
defineCppType(ASparseTensorRef, "at::SparseTensorRef", "ATen/ATen.h")
defineCppType(ATensorOptions, "at::TensorOptions", "ATen/ATen.h")
defineCppType(AScalar, "at::Scalar", "ATen/ATen.h")
defineCppType(AIntList, "at::IntList", "ATen/ATen.h")
defineCppType(AGenerator, "at::Generator", "ATen/ATen.h")
defineCppType(AContext, "at::Context", "ATen/ATen.h")
defineCppType(ATensors, "std::vector<at::Tensor>", "vector")
defineCppType(OStringStream, "std::ostringstream", "sstream")

type
  ScalarType* {.pure, importcpp: "at::ScalarType", header: "ATen/ATen.h".} = enum
    kByte
    kChar
    kShort
    kInt
    kLong
    kHalf
    kFloat
    kDouble

proc toATenType*(nimType: typedesc[byte]): ScalarType {.inline.} = ScalarType.kByte
proc toATenType*(nimType: typedesc[char]): ScalarType {.inline.} = ScalarType.kChar
proc toATenType*(nimType: typedesc[int16]): ScalarType {.inline.} = ScalarType.kShort
proc toATenType*(nimType: typedesc[int32]): ScalarType {.inline.} = ScalarType.kInt
proc toATenType*(nimType: typedesc[int64]): ScalarType {.inline.} = ScalarType.kLong
proc toATenType*(nimType: typedesc[float32]): ScalarType {.inline.} = ScalarType.kFloat
proc toATenType*(nimType: typedesc[float64]): ScalarType {.inline.} = ScalarType.kDouble

proc ACPU*(): CppProxy {.importcpp: "at::CPU(at::kFloat)".}
proc ACUDA*(): CppProxy {.importcpp: "at::CUDA(at::kFloat)".}
proc ACPU*(dtype: ScalarType): CppProxy {.importcpp: "at::CPU(#)".}
proc ACUDA*(dtype: ScalarType): CppProxy {.importcpp: "at::CUDA(#)".}
proc printTensor*(t: ATensor) {.importcpp: "at::print(#)".}
proc globalContext*(): AContext {.importcpp: "at::globalContext()".}
var BackendCPU* {.importcpp: "at::Backend::CPU", nodecl.}: cint
var BackendCUDA* {.importcpp: "at::Backend::CUDA", nodecl.}: cint
var DeviceTypeCPU* {.importcpp: "at::DeviceType::CPU", nodecl.}: cint
var DeviceTypeCUDA* {.importcpp: "at::DeviceType::CUDA", nodecl.}: cint

when getEnv("ATEN") == "" and defined(ANACONDA):
  const atenPath = currentSourcePath()[0..^14] & "../../../../"
else:
  const atenPath = getEnv("ATEN")
  when atenPath == "":
    {.error: "Please set $ATEN environment variable to point to the ATen installation path".}

cppincludes(atenPath & """/include""")
cpplibpaths(atenPath & """/lib""")
cpplibpaths(atenPath & """/lib64""")

type AInt64* {.importcpp: "int64_t", header: "<stdint.h>".} = object

when defined wasm:  
  {.passL: "-lcaffe2 -lc10".}

elif defined windows:
  cpplibs(atenPath & "/lib/caffe2.lib")
  cpplibs(atenPath & "/lib/cpuinfo.lib")

  cppdefines("NOMINMAX")

  when defined cuda:
    const cudaPath = getEnv("CUDA_PATH")
    cppincludes(cudaPath & """/include""")
  
    when sizeof(int) == 8:
      const cudaLibPath = cudaPath & "/lib/x64"
    else:
      const cudaLibPath = cudaPath & "/lib/Win32"

    cpplibs(cudaLibPath & "/cuda.lib")

elif defined osx:
  {.passC: "-std=c++14".}

  when not defined ios:
    {.passL: "-lcaffe2 -lcpuinfo -lsleef -pthread -lc10".}
  else:
    import fragments/ffi/ios
    {.passL: "-lcaffe2 -lcpuinfo -pthread -lc10".}
  
  # Make sure we allow users to use rpath and be able find ATEN easier
  const atenEnvRpath = """-Wl,-rpath,'""" & atenPath & """/lib'"""
  {.passL: atenEnvRpath.}
  {.passL: """-Wl,-rpath,'$ORIGIN'""".}

  when defined gperftools:
    {.passC: "-DWITHGPERFTOOLS -g".}
    {.passL: "-lprofiler -g".}
    proc ProfilerStart*(fname: cstring): int {.importc.}
    proc ProfilerStop*() {.importc.}

else:
  {.passC: "-std=c++14".}

  {.passL: "-lcaffe2 -lcpuinfo -lsleef -pthread -fopenmp -lrt -lc10".}
  when defined cuda:
    {.passL: "-lcaffe2_gpu -Wl,--no-as-needed -lcuda".}
  
  # Make sure we allow users to use rpath and be able find ATEN easier
  const atenEnvRpath = """-Wl,-rpath,'""" & atenPath & """/lib'"""
  {.passL: atenEnvRpath.}
  {.passL: """-Wl,-rpath,'$ORIGIN'""".}

  when defined gperftools:
    {.passC: "-DWITHGPERFTOOLS -g".}
    {.passL: "-lprofiler -g".}
    proc ProfilerStart*(fname: cstring): int {.importc.}
    proc ProfilerStop*() {.importc.}
