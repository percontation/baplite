open Core_kernel
open Core_kernel.Or_error
open Bap.Std

exception Arch_unsupp
exception No_instr
exception Disasm_fail of string
exception Lift_fail of string

let disasm_basic arch =
  Disasm_expert.Basic.create ~backend:"llvm" (Arch.to_string arch) |> ok_exn ;;

let make_mem arch (addr, s) =
  Memory.create
    LittleEndian
    (Addr.of_int64 ~width:(Size.to_bits @@ Arch.addr_size arch) addr)
    (Bigstring.of_string s) |> ok_exn ;;

let archutils =
  let armutils = lazy (disasm_basic `arm, make_mem `arm, ARM.lift) in
  let x86utils = lazy (disasm_basic `x86, make_mem `x86, IA32.lift) in
  let x64utils = lazy (disasm_basic `x86_64, make_mem `x86_64, AMD64.lift) in
  function
    | `arm -> Lazy.force armutils
    | `x86 -> Lazy.force x86utils
    | `x86_64 -> Lazy.force x64utils
    | _ -> raise Arch_unsupp
;;

let lift arch (addr, s) =
  let dis, mkmem, lift = archutils arch in
  let mem = mkmem (addr, s) in
  match Disasm_expert.Basic.insn_of_mem dis mem with
    | Result.Error e -> raise @@ Disasm_fail (Error.to_string_hum e)
    | Result.Ok (_, None, _) -> raise No_instr
    | Result.Ok (_, Some insn, _) -> (
        match lift mem insn with
          | Result.Ok bil -> bil
          | Result.Error e -> raise @@ Lift_fail (Error.to_string_hum e)
      )
;;

let lift_stub archstr addr s =
  try
    match Arch.of_string archstr with
      | Some arch -> lift arch (addr, s) |> Adt.strings_of_bil |> String.concat "," |> fun s -> "["^s^"]"
      | None -> "Invalid architecture"
  with
    | Arch_unsupp -> "Architecture is not supported."
    | No_instr -> "No instruction disassembled from bytes."
    | Disasm_fail s -> "Disassembly failed: " ^ s
    | Lift_fail s -> "Lifting failed: " ^ s
    | e -> "Unexpected failure: " ^ Printexc.to_string e

let () =
  Bap_plugins.Std.Plugins.load () ;
  Callback.register "lift_stub" lift_stub ;;
